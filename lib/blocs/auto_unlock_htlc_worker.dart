import 'dart:async';
import 'dart:collection';

import 'package:json_rpc_2/json_rpc_2.dart';
import 'package:logging/logging.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/base_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/model/database/notification_type.dart';
import 'package:zenon_syrius_wallet_flutter/model/database/wallet_notification.dart';
import 'package:zenon_syrius_wallet_flutter/utils/account_block_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/address_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/format_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class AutoUnlockHtlcWorker extends BaseBloc<WalletNotification> {
  static AutoUnlockHtlcWorker? _instance;
  Queue<Hash> pool = Queue<Hash>();
  HashSet<Hash> processedHashes = HashSet<Hash>();
  bool running = false;

  static AutoUnlockHtlcWorker getInstance() {
    _instance ??= AutoUnlockHtlcWorker();
    return _instance!;
  }

  Future<void> autoUnlock() async {
    if (pool.isNotEmpty && !running && kKeyStore != null) {
      running = true;
      Hash currentHash = pool.first;
      try {
        final htlc = await zenon!.embedded.htlc.getById(currentHash);
        final swap = htlcSwapsService!
            .getSwapByHashLock(FormatUtils.encodeHexString(htlc.hashLock));
        if (swap == null || swap.preimage == null) {
          throw 'Invalid swap';
        }
        if (!kDefaultAddressList.contains(htlc.hashLocked.toString())) {
          throw 'Swap address not in default addresses. Please add the address in the addresses list.';
        }
        KeyPair? keyPair = kKeyStore!.getKeyPair(
          kDefaultAddressList.indexOf(htlc.hashLocked.toString()),
        );
        AccountBlockTemplate transactionParams = zenon!.embedded.htlc
            .unlock(htlc.id, FormatUtils.decodeHexString(swap.preimage!));
        AccountBlockTemplate response =
            await AccountBlockUtils.createAccountBlock(
          transactionParams,
          'complete swap',
          blockSigningKey: keyPair,
          waitForRequiredPlasma: true,
        );
        _sendSuccessNotification(response, htlc.hashLocked.toString());
      } on RpcException catch (e, stackTrace) {
        Logger('AutoUnlockHtlcWorker')
            .log(Level.WARNING, 'autoUnlock', e, stackTrace);
        if (!e.message.contains('data non existent')) {
          _sendErrorNotification(e.toString());
        }
      } catch (e, stackTrace) {
        Logger('AutoUnlockHtlcWorker')
            .log(Level.WARNING, 'autoUnlock', e, stackTrace);
        _sendErrorNotification(e.toString());
      } finally {
        pool.removeFirst();
        _removeHashFromHashSetAfterDelay(currentHash);
        running = false;
      }
    }
  }

  void _sendErrorNotification(String errorText) {
    addEvent(
      WalletNotification(
        title: 'Failed to complete swap',
        timestamp: DateTime.now().millisecondsSinceEpoch,
        details: 'Failed to complete the swap: $errorText',
        type: NotificationType.error,
      ),
    );
  }

  void _sendSuccessNotification(AccountBlockTemplate block, String toAddress) {
    addEvent(
      WalletNotification(
        title: 'Transaction received on ${AddressUtils.getLabel(toAddress)}',
        timestamp: DateTime.now().millisecondsSinceEpoch,
        details: 'Transaction hash: ${block.hash}',
        type: NotificationType.paymentReceived,
      ),
    );
  }

  void addHash(Hash hash) {
    if (!processedHashes.contains(hash)) {
      zenon!.stats.syncInfo().then((syncInfo) {
        if (!processedHashes.contains(hash) &&
            (syncInfo.state == SyncState.syncDone ||
                (syncInfo.targetHeight > 0 &&
                    syncInfo.currentHeight > 0 &&
                    (syncInfo.targetHeight - syncInfo.currentHeight) < 3))) {
          pool.add(hash);
          processedHashes.add(hash);
        }
      }).onError(
        (e, stackTrace) {
          Logger('AutoUnlockHtlcWorker')
              .log(Level.WARNING, 'addHash', e, stackTrace);
        },
      );
    }
  }

  // Remove the hash from the processedHashes hash set after a delay, because
  // if the node shuts down immediately after the unlock transactions has been
  // sent, the transaction may not actually be published. By removing the hash
  // from processedHashes, it can be re-added to the pool and retried.
  // The delay gives the network time to process the transaction, before
  // allowing for it to be retried.
  void _removeHashFromHashSetAfterDelay(Hash hash) {
    Future.delayed(
        const Duration(minutes: 2), () => processedHashes.remove(hash));
  }
}
