import 'dart:async';

import 'package:collection/collection.dart';
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

  static BlockData? getDecodedBlockData(Abi abi, List<int> encodedData) {
    if (encodedData.length < AbiFunction.encodedSignLength) {
      return null;
    }
    final eq = const ListEquality().equals;
    try {
      for (final entry in abi.entries) {
        if (eq(AbiFunction.extractSignature(entry.encodeSignature()),
            AbiFunction.extractSignature(encodedData))) {
          final decoded =
              AbiFunction(entry.name!, entry.inputs!).decode(encodedData);
          final Map<String, dynamic> params = {};
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
      Address address, int time) async {
    final List<AccountBlock> blocks = [];
    int pageIndex = 0;
    try {
      while (true) {
        final fetched = await zenon!.ledger.getAccountBlocksByPage(address,
            pageIndex: pageIndex, pageSize: 100);

        final lastBlockConfirmation = fetched.list!.last.confirmationDetail;
        if (lastBlockConfirmation == null ||
            lastBlockConfirmation.momentumTimestamp <= time) {
          for (final block in fetched.list!) {
            final confirmation = block.confirmationDetail;
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
      Address address, int height) async {
    if (height >= 1) {
      try {
        final block =
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

  static void _addEventToPowGeneratingStatusBloc(PowStatus event) =>
      sl.get<PowGeneratingStatusBloc>().addEvent(event);
}
