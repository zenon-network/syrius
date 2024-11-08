import 'package:zenon_syrius_wallet_flutter/blocs/notifications_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/pow_generating_status_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/transfer/transfer_widgets_balance_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/model/database/notification_type.dart';
import 'package:zenon_syrius_wallet_flutter/model/database/wallet_notification.dart';
import 'package:zenon_syrius_wallet_flutter/utils/format_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class AccountBlockUtilsHelper {
  Future<AccountBlockTemplate> createAccountBlock(
      AccountBlockTemplate transactionParams,
      String purposeOfGeneratingPlasma, {
        Address? address,
        bool waitForRequiredPlasma = false,
      }) async {
    final SyncInfo syncInfo = await zenon!.stats.syncInfo();
    final bool nodeIsSynced = syncInfo.state == SyncState.syncDone ||
        (syncInfo.targetHeight > 0 &&
            syncInfo.currentHeight > 0 &&
            (syncInfo.targetHeight - syncInfo.currentHeight) < 20);
    if (nodeIsSynced) {
      // Acquire wallet lock to prevent concurrent access.
      final Wallet wallet = await kWalletFile!.open();
      try {
        address ??= Address.parse(kSelectedAddress!);
        final WalletAccount walletAccount = await wallet
            .getAccount(kDefaultAddressList.indexOf(address.toString()));

        final bool needPlasma = await zenon!.requiresPoW(
          transactionParams,
          blockSigningKey: walletAccount,
        );
        final bool needReview = kWalletFile!.isHardwareWallet;

        if (needPlasma) {
          await sl
              .get<NotificationsBloc>()
              .sendPlasmaNotification(purposeOfGeneratingPlasma);
        } else if (needReview) {
          await _sendReviewNotification(transactionParams);
        }
        final AccountBlockTemplate response = await zenon!.send(
          transactionParams,
          currentKeyPair: walletAccount,
          generatingPowCallback: (PowStatus status) async {
            // Wait for plasma to be generated before sending review notification
            if (needReview && status == PowStatus.done) {
              await _sendReviewNotification(transactionParams);
            }
            _addEventToPowGeneratingStatusBloc(status);
          },
          waitForRequiredPlasma: waitForRequiredPlasma,
        );
        if (BlockUtils.isReceiveBlock(transactionParams.blockType)) {
          sl.get<TransferWidgetsBalanceBloc>().getBalanceForAllAddresses();
        }
        await sl.get<NotificationsBloc>().addNotification(
          WalletNotification(
            title: 'Account-block published',
            timestamp: DateTime
                .now()
                .millisecondsSinceEpoch,
            details:
            'Account-block type: ${FormatUtils.extractNameFromEnum<
                BlockTypeEnum>(
              BlockTypeEnum.values[response.blockType],
            )}',
            type: NotificationType.paymentSent,
          ),
        );

        // Release the lock after 1 second, asynchronously.
        //
        // This will give the node enough time so that it'll process the transaction before we start creating a new one.
        // This is a problem when we create 2 transactions from the same address without requiring PoW.
        // If we release the lock too early, zenon.send will autofill the AccountBlockTemplate with an old value of
        // ledger.getFrontierAccountBlock, since the node did not had enough time to process the current transaction.
        await Future.delayed(const Duration(seconds: 1));

        return response;
      } finally {
        kWalletFile!.close();
      }
    } else {
      throw 'Node is not synced';
    }
  }

Future<void> _sendReviewNotification(
    AccountBlockTemplate transactionParams,) async {
  await sl.get<NotificationsBloc>().addNotification(
    WalletNotification(
      title:
      '${BlockUtils.isSendBlock(transactionParams.blockType)
          ? 'Sending transaction'
          : 'Receiving transaction'}, please review the transaction on your hardware device',
      timestamp: DateTime
          .now()
          .millisecondsSinceEpoch,
      details:
      'Review account-block type: ${FormatUtils.extractNameFromEnum<
          BlockTypeEnum>(
        BlockTypeEnum.values[transactionParams.blockType],
      )}',
      type: NotificationType.confirm,
    ),
  );
}

void _addEventToPowGeneratingStatusBloc(PowStatus event) =>
    sl.get<PowGeneratingStatusBloc>().addEvent(event);
}

