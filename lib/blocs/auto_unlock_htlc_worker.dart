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
      pool.removeFirst();
      try {
        final htlc = await zenon!.embedded.htlc.getById(currentHash);
        final swap = htlcSwapsService!
            .getSwapByHashLock(FormatUtils.encodeHexString(htlc.hashLock));
        if (swap == null || swap.preimage == null) {
          throw 'Invalid swap';
        }
        if (!kDefaultAddressList.contains(htlc.hashLocked.toString())) {
          return;
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
        // Ignore exception caused by non existent HTLC
        if (!e.message.contains('data non existent')) {
          pool.addFirst(currentHash);
          _sendErrorNotification(e.toString());
        }
      } catch (e, stackTrace) {
        Logger('AutoUnlockHtlcWorker')
            .log(Level.WARNING, 'autoUnlock', e, stackTrace);
        pool.addFirst(currentHash);
        _sendErrorNotification(e.toString());
      }
      running = false;
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
}
