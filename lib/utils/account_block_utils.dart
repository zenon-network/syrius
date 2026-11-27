import 'dart:async';

import 'package:collection/collection.dart';
import 'package:logging/logging.dart';
import 'package:mutex/mutex.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/exceptions/exceptions.dart';
import 'package:zenon_syrius_wallet_flutter/utils/format_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:zenon_syrius_wallet_flutter/utils/wallet_file.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class _AddressLockEntry {
  final Mutex mutex = Mutex();
  int activeCount = 0;
}

/// Utilities for creating, publishing, and inspecting Zenon account blocks.
class AccountBlockUtils {
  /// Creates an [AccountBlockUtils] instance with optional dependency
  /// overrides.
  AccountBlockUtils({
    this._publishSuccessNotification = true,
    Zenon Function()? zenonProvider,
    WalletFile? Function()? walletFileProvider,
    List<String?> Function()? addressListProvider,
    String? Function()? selectedAddressProvider,
    Future<void> Function(String purpose)? sendPlasmaNotification,
    Future<void> Function(WalletNotification notification)? addNotification,
    void Function(PowStatus status)? onPowStatusChanged,
    this._postSendDelay = const Duration(seconds: 1),
  }) : _zenonProvider = zenonProvider ?? _defaultZenonProvider,
       _walletFileProvider = walletFileProvider ?? _defaultWalletFileProvider,
       _addressListProvider =
           addressListProvider ?? _defaultAddressListProvider,
       _selectedAddressProvider =
           selectedAddressProvider ?? _defaultSelectedAddressProvider,
       _sendPlasmaNotification =
           sendPlasmaNotification ?? _defaultSendPlasmaNotification,
       _addNotification = addNotification ?? _defaultAddNotification,
       _onPowStatusChanged =
           onPowStatusChanged ?? _addEventToPowGeneratingStatusBloc;

  final bool _publishSuccessNotification;
  final Zenon Function() _zenonProvider;
  final WalletFile? Function() _walletFileProvider;
  final List<String?> Function() _addressListProvider;
  final String? Function() _selectedAddressProvider;
  final Future<void> Function(String purpose) _sendPlasmaNotification;
  final Future<void> Function(WalletNotification notification) _addNotification;
  final void Function(PowStatus status) _onPowStatusChanged;
  final Duration _postSendDelay;

  static final Map<String, _AddressLockEntry> _addressSendLocks =
      <String, _AddressLockEntry>{};

  static Future<T> _withAddressSendLock<T>(
    String addressKey,
    Future<T> Function() action,
  ) async {
    final _AddressLockEntry entry = _addressSendLocks.putIfAbsent(
      addressKey,
      _AddressLockEntry.new,
    );
    entry.activeCount++;
    try {
      return await entry.mutex.protect(action);
    } finally {
      entry.activeCount--;
      if (entry.activeCount == 0 &&
          identical(_addressSendLocks[addressKey], entry)) {
        _addressSendLocks.remove(addressKey);
      }
    }
  }

  /// Validates node sync and wallet state, then prepares and publishes
  /// [transactionParams] under a per-address lock.
  Future<AccountBlockTemplate> createAccountBlock(
    AccountBlockTemplate transactionParams,
    String purposeOfGeneratingPlasma, {
    Address? address,
    bool waitForRequiredPlasma = false,
  }) async {
    final Zenon currentZenon = _zenonProvider();
    final SyncInfo syncInfo = await currentZenon.stats.syncInfo();
    final bool nodeIsSynced =
        syncInfo.state == SyncState.syncDone ||
        (syncInfo.targetHeight > 0 &&
            syncInfo.currentHeight > 0 &&
            (syncInfo.targetHeight - syncInfo.currentHeight) < 20);
    if (!nodeIsSynced) {
      throw NodeNotSyncedException();
    }

    final Address resolvedAddress = address ?? _resolveSelectedAddress();
    final String resolvedAddressStr = resolvedAddress.toString();
    if (!_addressListProvider().contains(resolvedAddressStr)) {
      throw LocalizedSyriusException.addressNotInWalletList(
        address: resolvedAddressStr,
      );
    }

    final WalletFile? walletFile = _walletFileProvider();
    if (walletFile == null) {
      throw LocalizedSyriusException(SyriusErrorCode.walletNotUnlocked);
    }

    return await _withAddressSendLock<AccountBlockTemplate>(
      resolvedAddressStr,
      () => _createAndPublishAccountBlock(
        currentZenon: currentZenon,
        expectedWalletFile: walletFile,
        resolvedAddressStr: resolvedAddressStr,
        transactionParams: transactionParams,
        purposeOfGeneratingPlasma: purposeOfGeneratingPlasma,
        waitForRequiredPlasma: waitForRequiredPlasma,
      ),
    );
  }

  Address _resolveSelectedAddress() {
    final String? selected = _selectedAddressProvider();
    if (selected == null || selected.isEmpty) {
      throw LocalizedSyriusException(SyriusErrorCode.noWalletAddressSelected);
    }
    return Address.parse(selected);
  }

  Future<AccountBlockTemplate> _createAndPublishAccountBlock({
    required Zenon currentZenon,
    required WalletFile expectedWalletFile,
    required String resolvedAddressStr,
    required AccountBlockTemplate transactionParams,
    required String purposeOfGeneratingPlasma,
    required bool waitForRequiredPlasma,
  }) async {
    void throwIfWalletChanged() {
      final WalletFile? walletNow = _walletFileProvider();
      if (walletNow == null || !identical(walletNow, expectedWalletFile)) {
        throw LocalizedSyriusException(SyriusErrorCode.walletNotUnlocked);
      }
    }

    throwIfWalletChanged();
    final WalletFile currentWalletFile = expectedWalletFile;

    final int accountIndex = _addressListProvider().indexOf(resolvedAddressStr);
    if (accountIndex < 0) {
      throw LocalizedSyriusException.addressNotInWalletList(
        address: resolvedAddressStr,
      );
    }

    final bool needReview = currentWalletFile.isHardwareWallet;
    final AccountBlockTemplate response;

    if (needReview) {
      // Hardware wallets require serial USB device access across key lookup and
      // on-device transaction signing. Release the wallet lock before the
      // trailing frontier propagation delay so other wallet operations are not
      // blocked longer than necessary.
      response = await currentWalletFile.access<AccountBlockTemplate>((
        Wallet wallet,
      ) async {
        throwIfWalletChanged();
        final WalletAccount walletAccount = await wallet.getAccount(
          accountIndex,
        );
        return await _prepareAndSend(
          currentZenon: currentZenon,
          walletAccount: walletAccount,
          transactionParams: transactionParams,
          purposeOfGeneratingPlasma: purposeOfGeneratingPlasma,
          needReview: true,
          waitForRequiredPlasma: waitForRequiredPlasma,
        );
      });
    } else {
      // Software wallets derive an in-memory KeyPair; release the wallet lock
      // immediately after derivation so concurrent wallet operations (such as
      // address derivation or reclaim discovery) do not stall during PoW
      // generation or network I/O. Per-address frontier sequencing is preserved
      // by _withAddressSendLock.
      final WalletAccount walletAccount = await currentWalletFile
          .access<WalletAccount>((Wallet wallet) async {
            throwIfWalletChanged();
            return await wallet.getAccount(accountIndex);
          });
      response = await _prepareAndSend(
        currentZenon: currentZenon,
        walletAccount: walletAccount,
        transactionParams: transactionParams,
        purposeOfGeneratingPlasma: purposeOfGeneratingPlasma,
        needReview: false,
        waitForRequiredPlasma: waitForRequiredPlasma,
      );
    }

    if (_publishSuccessNotification) {
      final String blockTypeName =
          FormatUtils.extractNameFromEnum<BlockTypeEnum>(
            BlockTypeEnum.values[response.blockType],
          );
      await _addNotification(
        WalletNotification(
          title: 'Account-block published',
          timestamp: DateTime.now().millisecondsSinceEpoch,
          details: 'Account-block type: $blockTypeName',
          type: NotificationType.paymentSent,
        ),
      );
    }

    // Keep the per-address send lock held for 1 second after publishing so the
    // node has time to process the transaction and update
    // ledger.getFrontierAccountBlock before the next block from the same
    // address is autofilled.
    if (_postSendDelay > Duration.zero) {
      await Future<void>.delayed(_postSendDelay);
    }

    return response;
  }

  Future<AccountBlockTemplate> _prepareAndSend({
    required Zenon currentZenon,
    required WalletAccount walletAccount,
    required AccountBlockTemplate transactionParams,
    required String purposeOfGeneratingPlasma,
    required bool needReview,
    required bool waitForRequiredPlasma,
  }) async {
    final bool needPlasma = await currentZenon.requiresPoW(
      transactionParams,
      blockSigningKey: walletAccount,
    );

    if (needPlasma) {
      await _sendPlasmaNotification(purposeOfGeneratingPlasma);
    } else if (needReview) {
      await _sendReviewNotification(transactionParams);
    }
    bool powActive = false;
    try {
      return await currentZenon.send(
        transactionParams,
        currentKeyPair: walletAccount,
        generatingPowCallback: (PowStatus status) {
          if (status == PowStatus.generating) {
            powActive = true;
            _onPowStatusChanged(status);
            return;
          }
          if (status == PowStatus.done) {
            powActive = false;
            _onPowStatusChanged(status);
            // Wait for plasma to be generated before sending review
            // notification.
            if (needReview) {
              unawaited(_sendReviewNotificationSafely(transactionParams));
            }
          }
        },
        waitForRequiredPlasma: waitForRequiredPlasma,
      );
    } finally {
      if (powActive) {
        powActive = false;
        _onPowStatusChanged(PowStatus.done);
      }
    }
  }

  /// Decodes contract call [encodedData] using [abi], or returns `null` when
  /// no matching function entry is found.
  static BlockData? getDecodedBlockData(Abi abi, List<int> encodedData) {
    if (encodedData.length < AbiFunction.encodedSignLength) {
      return null;
    }
    final bool Function(List<dynamic>? list1, List<dynamic>? list2) eq =
        const ListEquality<dynamic>().equals;
    try {
      for (final Entry entry in abi.entries) {
        if (eq(
          AbiFunction.extractSignature(entry.encodeSignature()),
          AbiFunction.extractSignature(encodedData),
        )) {
          final List<dynamic> decoded = AbiFunction(
            entry.name!,
            entry.inputs!,
          ).decode(encodedData);
          final Map<String, dynamic> params = <String, dynamic>{};
          for (int i = 0; i < entry.inputs!.length; i += 1) {
            params[entry.inputs![i].name!] = decoded[i];
          }
          return BlockData(function: entry.name!, params: params);
        }
      }
    } catch (e) {
      rethrow;
    }
    return null;
  }

  /// Returns a list of [AccountBlock]s for [address] that are newer than
  /// [time], ordered chronologically ascending.
  static Future<List<AccountBlock>> getAccountBlocksAfterTime(
    Address address,
    int time,
  ) async {
    final List<AccountBlock> blocks = <AccountBlock>[];
    int pageIndex = 0;
    try {
      while (true) {
        final AccountBlockList fetched = await zenon!.ledger
            .getAccountBlocksByPage(
              address,
              pageIndex: pageIndex,
              pageSize: 100,
            );

        final AccountBlockConfirmationDetail? lastBlockConfirmation =
            fetched.list!.last.confirmationDetail;
        if (lastBlockConfirmation == null ||
            lastBlockConfirmation.momentumTimestamp <= time) {
          for (final AccountBlock block in fetched.list!) {
            final AccountBlockConfirmationDetail? confirmation =
                block.confirmationDetail;
            if (confirmation == null ||
                confirmation.momentumTimestamp <= time) {
              break;
            }
            blocks.add(block);
          }
          break;
        }

        blocks.addAll(fetched.list!);

        if (fetched.more == null || !fetched.more!) {
          break;
        }

        pageIndex += 1;
      }
    } catch (e) {
      rethrow;
    }
    return blocks.reversed.toList();
  }

  /// Returns the momentum confirmation timestamp for the block at [height] on
  /// [address], or `null` if unavailable.
  static Future<int?> getTimeForAccountBlockHeight(
    Address address,
    int height,
  ) async {
    if (height >= 1) {
      try {
        final AccountBlockList block = await zenon!.ledger
            .getAccountBlocksByHeight(address, height, 1);
        if (block.count != null && block.count! > 0) {
          return block.list?.first.confirmationDetail?.momentumTimestamp;
        }
      } catch (e) {
        rethrow;
      }
    }
    return null;
  }

  Future<void> _sendReviewNotificationSafely(
    AccountBlockTemplate transactionParams,
  ) async {
    try {
      await _sendReviewNotification(transactionParams);
    } on Object catch (error, stackTrace) {
      Logger('AccountBlockUtils').log(
        Level.WARNING,
        'Failed to send hardware wallet review notification',
        error,
        stackTrace,
      );
    }
  }

  Future<void> _sendReviewNotification(
    AccountBlockTemplate transactionParams,
  ) async {
    final String direction = BlockUtils.isSendBlock(transactionParams.blockType)
        ? 'Sending transaction'
        : 'Receiving transaction';
    final String blockTypeName =
        FormatUtils.extractNameFromEnum<BlockTypeEnum>(
          BlockTypeEnum.values[transactionParams.blockType],
        );
    await _addNotification(
      WalletNotification(
        title:
            '$direction, please review the transaction on your hardware device',
        timestamp: DateTime.now().millisecondsSinceEpoch,
        details: 'Review account-block type: $blockTypeName',
        type: NotificationType.confirm,
      ),
    );
  }

  static Zenon _defaultZenonProvider() => zenon!;

  static WalletFile? _defaultWalletFileProvider() => kWalletFile;

  static List<String?> _defaultAddressListProvider() => kDefaultAddressList;

  static String? _defaultSelectedAddressProvider() => kSelectedAddress;

  static Future<void> _defaultSendPlasmaNotification(String purpose) =>
      sl.get<NotificationsBloc>().sendPlasmaNotification(purpose);

  static Future<void> _defaultAddNotification(
    WalletNotification notification,
  ) => sl.get<NotificationsBloc>().addNotification(notification);

  static void _addEventToPowGeneratingStatusBloc(PowStatus event) =>
      sl.get<PowGeneratingStatusBloc>().add(PowGeneratingStatusChanged(event));
}
