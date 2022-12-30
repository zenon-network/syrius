import 'dart:async';

import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/utils/format_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class AccountBlockUtils {
  static final Map<String, Future<void>?> _kIsRunningByAddress = {};

  static Future<AccountBlockTemplate> createAccountBlock(
    AccountBlockTemplate transactionParams,
    String purposeOfGeneratingPlasma, {
    KeyPair? blockSigningKey,
    bool waitForRequiredPlasma = false,
  }) async {
    SyncInfo syncInfo = await zenon!.stats.syncInfo();
    bool nodeIsSynced = kCurrentNode == kLocalhostDefaultNodeUrl
        ? (syncInfo.state == SyncState.syncDone ||
            (syncInfo.targetHeight > 0 &&
                syncInfo.currentHeight > 0 &&
                (syncInfo.targetHeight - syncInfo.currentHeight) < 20))
        : true;
    if (nodeIsSynced) {
      Address address = (await blockSigningKey?.address ??
          await zenon!.defaultKeyPair!.address)!;
      try {
        // Wait until the lock is unused.
        //
        // A while-loop is required since there is the case when a lot of routines are waiting, and only one should move
        // forward when the main routine finishes.
        while (_kIsRunningByAddress.containsKey(address.toString()) &&
            _kIsRunningByAddress[address.toString()] != null) {
          await _kIsRunningByAddress[address.toString()];
        }

        // Acquire lock
        Completer<void> completer;
        completer = Completer<void>();
        _kIsRunningByAddress[address.toString()] = completer.future;

        bool needPlasma = await zenon!.requiresPoW(
          transactionParams,
          blockSigningKey: blockSigningKey,
        );

        if (needPlasma) {
          sl
              .get<NotificationsBloc>()
              .sendPlasmaNotification(purposeOfGeneratingPlasma);
        }
        final AccountBlockTemplate response = await zenon!.send(
          transactionParams,
          currentKeyPair: blockSigningKey,
          generatingPowCallback: _addEventToPowGeneratingStatusBloc,
          waitForRequiredPlasma: waitForRequiredPlasma,
        );
        if (BlockUtils.isReceiveBlock(transactionParams.blockType)) {
          sl.get<TransferWidgetsBalanceBloc>().getBalanceForAllAddresses();
        }
        sl.get<NotificationsBloc>().addNotification(
              WalletNotification(
                title: 'Account-block published',
                timestamp: DateTime.now().millisecondsSinceEpoch,
                details: 'Account-block type: ' +
                    FormatUtils.extractNameFromEnum<BlockTypeEnum>(
                      BlockTypeEnum.values[response.blockType],
                    ),
                type: NotificationType.paymentSent,
              ),
            );

        // Release the lock after 1 second, asynchronously.
        //
        // This will give the node enough time so that it'll process the transaction before we start creating a new one.
        // This is a problem when we create 2 transactions from the same address without requiring PoW.
        // If we release the lock too early, zenon.send will autofill the AccountBlockTemplate with an old value of
        // ledger.getFrontierAccountBlock, since the node did not had enough time to process the current transaction.
        Future.delayed(const Duration(seconds: 1)).then((_) {
          completer.complete();
          _kIsRunningByAddress[address.toString()] = null;
        });

        return response;
      } catch (e) {
        _kIsRunningByAddress[address.toString()] = null;
        rethrow;
      }
    } else {
      throw 'Node is not synced';
    }
  }

  static void _addEventToPowGeneratingStatusBloc(PowStatus event) =>
      sl.get<PowGeneratingStatusBloc>().addEvent(event);
}
