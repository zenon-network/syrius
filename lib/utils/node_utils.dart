import 'dart:async';
import 'dart:isolate';

import 'package:hive/hive.dart';
import 'package:logging/logging.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/embedded_node/embedded_node.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/utils/date_time_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:zenon_syrius_wallet_flutter/utils/notification_utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

int _kHeight = 0;

class NodeUtils {
  static Future<bool> establishConnectionToNode(String url) async {
    final connectionStatus = await zenon!.wsClient.initialize(
      url,
      retry: false,
    );
    return connectionStatus;
  }

  static Future<int> getNodeChainIdentifier() async {
    var nodeChainId = 1;
    try {
      await zenon!.ledger.getFrontierMomentum().then((value) {
        nodeChainId = value.chainIdentifier;
      });
    } catch (e, stackTrace) {
      Logger('NodeUtils')
          .log(Level.WARNING, 'getNodeChainIdentifier', e, stackTrace);
    }
    return nodeChainId;
  }

  static closeEmbeddedNode() async {
    // Release WakeLock
    if (await WakelockPlus.enabled) {
      WakelockPlus.disable();
    }

    if (kCurrentNode == kLocalhostDefaultNodeUrl ||
        kCurrentNode == kEmbeddedNode) {
      if (kEmbeddedNodeRunning) {
        await sl.get<NotificationsBloc>().addNotification(
              WalletNotification(
                title: 'Waiting for Embedded Node to stop',
                timestamp: DateTime.now().millisecondsSinceEpoch,
                details:
                    'The app will close after the Embedded Node has been stopped',
                type: NotificationType.changedNode,
              ),
            );

        // If the message is null, it means that the isolate has closed
        final embeddedStoppedCompleter = Completer();
        sl<Stream>(instanceName: 'embeddedStoppedStream').listen(
          (message) {
            kEmbeddedNodeRunning = false;
            embeddedStoppedCompleter.complete();
          },
        );

        if (EmbeddedNode.stopNode()) {
          await embeddedStoppedCompleter.future;
        } else {
          kEmbeddedNodeRunning = false;
          embeddedStoppedCompleter.complete();
        }
      }
    }
  }

  static stopWebSocketClient() {
    try {
      zenon!.wsClient.stop();
    } catch (_) {}
  }

  static initWebSocketClient() async {
    addOnWebSocketConnectedCallback();
    final url = kCurrentNode == kEmbeddedNode
          ? kLocalhostDefaultNodeUrl
          : kCurrentNode ?? '';
    var connected = false;
    try {
      connected = await establishConnectionToNode(url);
    } catch (_) {}
    if (!connected) {
      zenon!.wsClient.initialize(
        url,
      );
    }
  }

  static Future<void> addOnWebSocketConnectedCallback() async {
    zenon!.wsClient
        .addOnConnectionEstablishedCallback((allResponseBroadcaster) async {
      kNodeChainId = await getNodeChainIdentifier();
      await _getSubscriptionForMomentums();
      await _getSubscriptionForAllAccountEvents();
      await getUnreceivedTransactions();

      sl<AutoReceiveTxWorker>().autoReceive();
      Future.delayed(const Duration(seconds: 30))
          .then((value) async => NotificationUtils.sendNodeSyncingNotification());
      _initListenForUnreceivedAccountBlocks(allResponseBroadcaster);
    });
  }

  static Future<void> getUnreceivedTransactions() async {
    await Future.forEach<String?>(
      kDefaultAddressList,
      (address) async => getUnreceivedTransactionsByAddress(
        Address.parse(address!),
      ),
    );
  }

  static Future<void> getUnreceivedTransactionsByAddress(
    Address address,
  ) async {
    final unreceivedBlocks =
        (await zenon!.ledger.getUnreceivedBlocksByAddress(
      address,
    ))
            .list!;

    if (unreceivedBlocks.isNotEmpty) {
      for (final unreceivedBlock in unreceivedBlocks) {
        if (sharedPrefsService!.get(
          kAutoReceiveKey,
          defaultValue: kAutoReceiveDefaultValue,
        )) {
          sl<AutoReceiveTxWorker>().addHash(unreceivedBlock.hash);
        }
      }
    }
  }

  static Future<void> checkForLocalTimeDiscrepancy(
      String warningMessage,) async {
    const maxAllowedDiscrepancy = Duration(minutes: 5);
    try {
      final syncInfo = await zenon!.stats.syncInfo();
      final nodeIsSynced = syncInfo.state == SyncState.syncDone ||
          (syncInfo.targetHeight > 0 &&
              syncInfo.currentHeight > 0 &&
              (syncInfo.targetHeight - syncInfo.currentHeight) < 20);
      if (nodeIsSynced) {
        final frontierTime =
            (await zenon!.ledger.getFrontierMomentum()).timestamp;
        final timeDifference = (frontierTime - DateTimeUtils.unixTimeNow).abs();
        if (timeDifference > maxAllowedDiscrepancy.inSeconds) {
          await NotificationUtils.sendNotificationError(
            Exception('Local time discrepancy detected.'),
            warningMessage,
          );
        }
      }
    } catch (e, stackTrace) {
      Logger('NodeUtils')
          .log(Level.WARNING, 'checkForLocalTimeDiscrepancy', e, stackTrace);
    }
  }

  static void _initListenForUnreceivedAccountBlocks(Stream broadcaster) {
    broadcaster.listen(
      (event) {
        // Only process unreceived account blocks when autoReceive is enabled
        if (event!.containsKey('method') &&
            event['method'] == 'ledger.subscription' &&
            sharedPrefsService!
                .get(kAutoReceiveKey, defaultValue: kAutoReceiveDefaultValue)) {
          for (var i = 0; i < event['params']['result'].length; i += 1) {
            final tx = event['params']['result'][i];
            if (tx.containsKey('toAddress') &&
                kDefaultAddressList.contains(tx['toAddress'])) {
              final hash = Hash.parse(tx['hash']);
              sl<AutoReceiveTxWorker>().addHash(hash);
            }
          }

          final Map result = (event['params']['result'] as List).first;
          if (!result.containsKey('blockType') &&
              result['height'] != null &&
              (_kHeight == 0 || result['height'] >= _kHeight + 1)) {
            _kHeight = result['height'];
            if (sl<AutoReceiveTxWorker>().pool.isNotEmpty &&
                kWalletFile != null) {
              sl<AutoReceiveTxWorker>().autoReceive();
            }
          }
        }
      },
    );
  }

  static Future<void> _getSubscriptionForMomentums() async =>
      zenon!.subscribe.toMomentums();

  static Future<void> _getSubscriptionForAllAccountEvents() async =>
      zenon!.subscribe.toAllAccountBlocks();

  static Future<void> loadDbNodes() async {
    if (!Hive.isBoxOpen(kNodesBox)) {
      await Hive.openBox<String>(kNodesBox);
    }
    final nodesBox = Hive.box<String>(kNodesBox);
    if (kDbNodes.isNotEmpty) {
      kDbNodes.clear();
    }
    kDbNodes.addAll(nodesBox.values);
    // Handle the case in which some default nodes were deleted
    // so they can't be found in the cache
    final currentNode = kCurrentNode;
    if (currentNode != null &&
        !kDefaultNodes.contains(currentNode) &&
        !kDbNodes.contains(currentNode)) {
      kDefaultNodes.add(currentNode);
    }
  }

  static Future<void> setNode() async {
    final String? savedNode = sharedPrefsService!.get(kSelectedNodeKey);
    kCurrentNode = savedNode;

    if (savedNode == kEmbeddedNode) {
      // First we need to check if the node is not already running
      final isConnectionEstablished =
          await NodeUtils.establishConnectionToNode(kLocalhostDefaultNodeUrl);
      if (isConnectionEstablished == false) {
        // Acquire WakeLock
        if (!await WakelockPlus.enabled) {
          WakelockPlus.enable();
        }
        // Initialize local full node
        await Isolate.spawn(EmbeddedNode.runNode, [''],
            onExit:
                sl<ReceivePort>(instanceName: 'embeddedStoppedPort').sendPort,);

        kEmbeddedNodeRunning = true;
      }
    }
  }
}
