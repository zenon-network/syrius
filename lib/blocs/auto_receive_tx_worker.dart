import 'dart:async';
import 'dart:collection';

import 'package:json_rpc_2/json_rpc_2.dart';
import 'package:logging/logging.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/auto_unlock_htlc_worker.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/utils/account_block_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/address_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class AutoReceiveTxWorker extends BaseBloc<WalletNotification> {
  static AutoReceiveTxWorker? _instance;
  Queue<Hash> pool = Queue<Hash>();
  bool running = false;

  static AutoReceiveTxWorker getInstance() {
    _instance ??= AutoReceiveTxWorker();
    return _instance!;
  }

  Future<AccountBlockTemplate?> autoReceiveTransactionHash(
      Hash currentHash,) async {
    if (!running) {
      running = true;
      try {
        final toAddress =
            (await zenon!.ledger.getAccountBlockByHash(currentHash))!.toAddress;
        final transactionParams = AccountBlockTemplate.receive(
          currentHash,
        );
        final response =
            await AccountBlockUtils.createAccountBlock(
          transactionParams,
          'receive transaction',
          address: toAddress,
          waitForRequiredPlasma: true,
        );
        _sendSuccessNotification(response, toAddress.toString());
        return response;
      } on RpcException catch (e, stackTrace) {
        _sendErrorNotification(e.toString());
        Logger('AutoReceiveTxWorker')
            .log(Level.WARNING, 'autoReceive', e, stackTrace);
      } finally {
        running = false;
      }
    }
    return null;
  }

  Future<void> autoReceive() async {
    if (sharedPrefsService!.get(
      kAutoReceiveKey,
      defaultValue: kAutoReceiveDefaultValue,
    ) == false) {
      pool.clear();
      return;
    }
    // Make sure that AutoUnlockHtlcWorker is not running since it should be
    // given priority to send transactions.
    if (pool.isNotEmpty && !running && !sl<AutoUnlockHtlcWorker>().running) {
      running = true;
      final currentHash = pool.first;
      try {
        final toAddress =
            (await zenon!.ledger.getAccountBlockByHash(currentHash))!.toAddress;
        final transactionParams = AccountBlockTemplate.receive(
          currentHash,
        );
        final response =
            await AccountBlockUtils.createAccountBlock(
          transactionParams,
          'receive transaction',
          address: toAddress,
          waitForRequiredPlasma: true,
        );
        _sendSuccessNotification(response, toAddress.toString());
        if (pool.isNotEmpty) {
          pool.removeFirst();
        }
        running = false;
        autoReceive();
      } on RpcException catch (e, stackTrace) {
        _sendErrorNotification(e.toString());
        Logger('AutoReceiveTxWorker')
            .log(Level.WARNING, 'autoReceive', e, stackTrace);
        if (e.message.compareTo('account-block from-block already received') ==
            0) {
          if (pool.isNotEmpty) {
            pool.removeFirst();
          }
        }
      } catch (e, stackTrace) {
        Logger('AutoReceiveTxWorker')
            .log(Level.WARNING, 'autoReceive', e, stackTrace);
        _sendErrorNotification(e.toString());
      } finally {
        running = false;
      }
    }
  }

  Future<void> addHash(Hash hash) async {
    zenon!.stats.syncInfo().then((syncInfo) {
      if (!pool.contains(hash) &&
          (syncInfo.state == SyncState.syncDone ||
              (syncInfo.targetHeight > 0 &&
                  syncInfo.currentHeight > 0 &&
                  (syncInfo.targetHeight - syncInfo.currentHeight) < 3))) {
        pool.add(hash);
      }
    });
  }

  void _sendErrorNotification(String errorText) {
    addEvent(
      WalletNotification(
        title: 'Receive transaction failed',
        timestamp: DateTime.now().millisecondsSinceEpoch,
        details: 'Failed to receive the transaction: $errorText',
        type: NotificationType.error,
      ),
    );
  }

  void _sendSuccessNotification(AccountBlockTemplate block, String toAddress) {
    addEvent(
      WalletNotification(
        title:
            'Transaction received on ${ZenonAddressUtils.getLabel(toAddress)}',
        timestamp: DateTime.now().millisecondsSinceEpoch,
        details: 'Transaction hash: ${block.hash}',
        type: NotificationType.paymentReceived,
      ),
    );
  }
}
