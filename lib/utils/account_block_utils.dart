import 'dart:async';

import 'package:collection/collection.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/utils/format_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class AccountBlockUtils {
  static Future<AccountBlockTemplate> createAccountBlock(
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
        await sl.get<NotificationsBloc>().addNotification(
              WalletNotification(
                title: 'Account-block published',
                timestamp: DateTime.now().millisecondsSinceEpoch,
                details:
                    'Account-block type: ${FormatUtils.extractNameFromEnum<BlockTypeEnum>(
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

  static BlockData? getDecodedBlockData(Abi abi, List<int> encodedData) {
    if (encodedData.length < AbiFunction.encodedSignLength) {
      return null;
    }
    final bool Function(List? list1, List? list2) eq = const ListEquality().equals;
    try {
      for (final Entry entry in abi.entries) {
        if (eq(AbiFunction.extractSignature(entry.encodeSignature()),
            AbiFunction.extractSignature(encodedData),)) {
          final List decoded =
              AbiFunction(entry.name!, entry.inputs!).decode(encodedData);
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

  // Returns a list of AccountBlocks that are newer than a given timestamp.
  // The list is returned in ascending order.
  static Future<List<AccountBlock>> getAccountBlocksAfterTime(
      Address address, int time,) async {
    final List<AccountBlock> blocks = <AccountBlock>[];
    int pageIndex = 0;
    try {
      while (true) {
        final AccountBlockList fetched = await zenon!.ledger.getAccountBlocksByPage(address,
            pageIndex: pageIndex, pageSize: 100,);

        final AccountBlockConfirmationDetail? lastBlockConfirmation = fetched.list!.last.confirmationDetail;
        if (lastBlockConfirmation == null ||
            lastBlockConfirmation.momentumTimestamp <= time) {
          for (final AccountBlock block in fetched.list!) {
            final AccountBlockConfirmationDetail? confirmation = block.confirmationDetail;
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

  static Future<int?> getTimeForAccountBlockHeight(
      Address address, int height,) async {
    if (height >= 1) {
      try {
        final AccountBlockList block =
            await zenon!.ledger.getAccountBlocksByHeight(address, height, 1);
        if (block.count != null && block.count! > 0) {
          return block.list?.first.confirmationDetail?.momentumTimestamp;
        }
      } catch (e) {
        rethrow;
      }
    }
    return null;
  }

  static Future<void> _sendReviewNotification(
      AccountBlockTemplate transactionParams,) async {
    await sl.get<NotificationsBloc>().addNotification(
          WalletNotification(
            title:
                '${BlockUtils.isSendBlock(transactionParams.blockType) ? 'Sending transaction' : 'Receiving transaction'}, please review the transaction on your hardware device',
            timestamp: DateTime.now().millisecondsSinceEpoch,
            details:
                'Review account-block type: ${FormatUtils.extractNameFromEnum<BlockTypeEnum>(
              BlockTypeEnum.values[transactionParams.blockType],
            )}',
            type: NotificationType.confirm,
          ),
        );
  }

  static void _addEventToPowGeneratingStatusBloc(PowStatus event) =>
      sl.get<PowGeneratingStatusBloc>().addEvent(event);
}
