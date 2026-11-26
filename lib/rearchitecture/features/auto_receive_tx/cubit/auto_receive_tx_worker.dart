import 'dart:async';
import 'dart:collection';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:json_rpc_2/json_rpc_2.dart';
import 'package:logging/logging.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/extensions/sync_info_extension.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'auto_receive_tx_state.dart';

const String _kAlreadyReceivedRpcMessage =
    'account-block from-block already received';

/// Cubit worker that queues and receives unreceived account blocks.
class AutoReceiveTxWorker extends Cubit<AutoReceiveTxState> {
  /// Creates an [AutoReceiveTxWorker].
  AutoReceiveTxWorker({
    Zenon Function()? zenonProvider,
    AccountBlockUtils Function()? accountBlockUtilsProvider,
    bool Function()? isAutoReceiveEnabled,
    bool Function()? isHtlcAutoUnlocking,
    void Function()? onRefreshPendingTransactions,
    void Function()? onTransactionReceived,
    String Function(String address)? addressLabelResolver,
    void Function(WalletNotification notification)? onNotification,
  }) : _zenonProvider = zenonProvider ?? _defaultZenonProvider,
       _accountBlockUtilsProvider =
           accountBlockUtilsProvider ?? AccountBlockUtils.new,
       _isAutoReceiveEnabled =
           isAutoReceiveEnabled ?? _defaultIsAutoReceiveEnabled,
       _isHtlcAutoUnlocking =
           isHtlcAutoUnlocking ?? _defaultIsHtlcAutoUnlocking,
       _onRefreshPendingTransactions =
           onRefreshPendingTransactions ?? _defaultRefreshPendingTransactions,
       _onTransactionReceived =
           onTransactionReceived ?? _defaultOnTransactionReceived,
       _addressLabelResolver =
           addressLabelResolver ?? ZenonAddressUtils.getLabel,
       _onNotification = onNotification ?? _defaultOnNotification,
       super(const AutoReceiveTxState());

  final Zenon Function() _zenonProvider;
  final AccountBlockUtils Function() _accountBlockUtilsProvider;
  final bool Function() _isAutoReceiveEnabled;
  final bool Function() _isHtlcAutoUnlocking;
  final void Function() _onRefreshPendingTransactions;
  final void Function() _onTransactionReceived;
  final String Function(String address) _addressLabelResolver;
  final void Function(WalletNotification notification) _onNotification;

  final Queue<Hash> _pool = Queue<Hash>();
  bool _running = false;

  /// Read-only view of pending block hashes queued for auto-receive.
  UnmodifiableListView<Hash> get pool => UnmodifiableListView<Hash>(_pool);

  /// Enqueues [hash] directly into the pool for tests without querying node
  /// sync status, emitting the updated [AutoReceiveTxState].
  @visibleForTesting
  void enqueueForTesting(Hash hash) {
    if (!_pool.contains(hash)) {
      _pool.add(hash);
      _emitStatus();
    }
  }

  /// Whether a receive operation is currently in flight.
  bool get running => _running;

  /// Clears all pending hashes from the auto-receive queue.
  void clearPool() {
    _pool.clear();
    _safeEmit(
      AutoReceiveTxState(
        isRunning: _running,
        notificationSequence: state.notificationSequence,
      ),
    );
  }

  /// Manually receives a single account block by [currentHash].
  Future<AccountBlockTemplate?> autoReceiveTransactionHash(
    Hash currentHash,
  ) async {
    if (_running) {
      return null;
    }

    _running = true;
    _emitStatus();
    try {
      final AccountBlock? block = await _zenonProvider().ledger
          .getAccountBlockByHash(currentHash);
      if (block == null) {
        throw StateError('Account block not found for hash $currentHash');
      }
      final Address toAddress = block.toAddress;
      final AccountBlockTemplate transactionParams =
          AccountBlockTemplate.receive(currentHash);
      final AccountBlockTemplate response = await _accountBlockUtilsProvider()
          .createAccountBlock(
            transactionParams,
            'receive transaction',
            address: toAddress,
            waitForRequiredPlasma: true,
          );
      _onSuccess(response, toAddress.toString());
      return response;
    } on RpcException catch (e, stackTrace) {
      _sendErrorNotification(e.toString());
      Logger(
        'AutoReceiveTxWorker',
      ).log(Level.WARNING, 'autoReceiveTransactionHash', e, stackTrace);
      return null;
    } finally {
      _running = false;
      _emitStatus();
    }
  }

  /// Drains queued unreceived hashes while auto-receive is enabled and no
  /// higher-priority HTLC auto-unlock transaction is running.
  Future<void> autoReceive() async {
    if (!_isAutoReceiveEnabled()) {
      clearPool();
      return;
    }

    if (_running || _pool.isEmpty || _isHtlcAutoUnlocking()) {
      return;
    }

    _running = true;
    _emitStatus();
    try {
      while (_pool.isNotEmpty && !isClosed) {
        if (!_isAutoReceiveEnabled()) {
          _pool.clear();
          break;
        }
        // Give HTLC auto-unlock priority to send transactions.
        if (_isHtlcAutoUnlocking()) {
          break;
        }

        final Hash currentHash = _pool.first;
        try {
          final AccountBlock? block = await _zenonProvider().ledger
              .getAccountBlockByHash(currentHash);
          if (block == null) {
            throw StateError('Account block not found for hash $currentHash');
          }
          final Address toAddress = block.toAddress;
          final AccountBlockTemplate transactionParams =
              AccountBlockTemplate.receive(currentHash);
          final AccountBlockTemplate response =
              await _accountBlockUtilsProvider().createAccountBlock(
                transactionParams,
                'receive transaction',
                address: toAddress,
                waitForRequiredPlasma: true,
              );
          if (_pool.isNotEmpty && _pool.first == currentHash) {
            _pool.removeFirst();
          }
          _onSuccess(response, toAddress.toString());
        } on RpcException catch (e, stackTrace) {
          _sendErrorNotification(e.toString());
          Logger(
            'AutoReceiveTxWorker',
          ).log(Level.WARNING, 'autoReceive', e, stackTrace);
          if (e.message == _kAlreadyReceivedRpcMessage) {
            if (_pool.isNotEmpty && _pool.first == currentHash) {
              _pool.removeFirst();
            }
            continue;
          }
          break;
        } on Object catch (e, stackTrace) {
          Logger(
            'AutoReceiveTxWorker',
          ).log(Level.WARNING, 'autoReceive', e, stackTrace);
          _sendErrorNotification(e.toString());
          break;
        }
      }
    } finally {
      _running = false;
      _emitStatus();
    }
  }

  /// Enqueues [hash] when the connected node is synced and the hash is not
  /// already queued.
  Future<void> addHash(Hash hash) async {
    try {
      final SyncInfo syncInfo = await _zenonProvider().stats.syncInfo();
      if (!_pool.contains(hash) && syncInfo.isSynced) {
        _onRefreshPendingTransactions();
        _pool.add(hash);
        _emitStatus();
      }
    } on Object catch (e, stackTrace) {
      Logger(
        'AutoReceiveTxWorker',
      ).log(Level.WARNING, 'addHash', e, stackTrace);
    }
  }

  void _emitStatus() {
    _safeEmit(
      AutoReceiveTxState(
        isRunning: _running,
        pendingCount: _pool.length,
        notificationSequence: state.notificationSequence,
      ),
    );
  }

  void _emitNotification(WalletNotification notification) {
    if (isClosed) {
      return;
    }
    try {
      _onNotification(notification);
    } on Object catch (e, stackTrace) {
      Logger(
        'AutoReceiveTxWorker',
      ).log(Level.WARNING, '_emitNotification', e, stackTrace);
    }
    emit(
      AutoReceiveTxState(
        isRunning: _running,
        pendingCount: _pool.length,
        lastNotification: notification,
        notificationSequence: state.notificationSequence + 1,
      ),
    );
  }

  void _safeEmit(AutoReceiveTxState nextState) {
    if (!isClosed) {
      emit(nextState);
    }
  }

  void _sendErrorNotification(String errorText) {
    _emitNotification(
      WalletNotification(
        title: 'Receive transaction failed',
        timestamp: DateTime.now().millisecondsSinceEpoch,
        details: 'Failed to receive the transaction: $errorText',
        type: NotificationType.error,
      ),
    );
  }

  void _onSuccess(AccountBlockTemplate block, String toAddress) {
    _onTransactionReceived();
    _sendSuccessNotification(block, toAddress);
  }

  void _sendSuccessNotification(AccountBlockTemplate block, String toAddress) {
    _emitNotification(
      WalletNotification(
        title: 'Transaction received on ${_addressLabelResolver(toAddress)}',
        timestamp: DateTime.now().millisecondsSinceEpoch,
        details: 'Transaction hash: ${block.hash}',
        type: NotificationType.paymentReceived,
      ),
    );
  }

  static Zenon _defaultZenonProvider() => zenon!;

  static bool _defaultIsAutoReceiveEnabled() =>
      sharedPrefsService!.get(
            kAutoReceiveKey,
            defaultValue: kAutoReceiveDefaultValue,
          )
          as bool;

  static bool _defaultIsHtlcAutoUnlocking() =>
      sl<HtlcSwapAutoUnlockService>().isUnlocking;

  static void _defaultRefreshPendingTransactions() {
    final String? selectedAddress = kSelectedAddress;
    if (selectedAddress == null) {
      return;
    }
    sl.get<PendingTransactionsBloc>().add(
      InfiniteListRefreshRequested(address: Address.parse(selectedAddress)),
    );
  }

  static void _defaultOnTransactionReceived() {
    sl.get<MultipleBalanceBloc>().add(
      MultipleBalanceFetch(
        addresses: kDefaultAddressList.whereType<String>().toList(),
      ),
    );

    final String? selectedAddress = kSelectedAddress;
    if (selectedAddress == null) {
      return;
    }
    final Address address = Address.parse(selectedAddress);
    sl.get<LatestTransactionsBloc>().add(
      InfiniteListRefreshRequested(address: address),
    );
    sl.get<PendingTransactionsBloc>().add(
      InfiniteListRefreshRequested(address: address),
    );
  }

  static void _defaultOnNotification(WalletNotification notification) {
    if (sl.isRegistered<NotificationsBloc>()) {
      unawaited(sl<NotificationsBloc>().addNotification(notification));
    }
  }
}
