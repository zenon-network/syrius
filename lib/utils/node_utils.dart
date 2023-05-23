import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:hive/hive.dart';
import 'package:logging/logging.dart';
import 'package:wakelock/wakelock.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/embedded_node/embedded_node.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:zenon_syrius_wallet_flutter/utils/notification_utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

int _kHeight = 0;

class NodeUtils {
  static Future<bool> establishConnectionToNode(String url) async {
    bool connectionStatus = await zenon!.wsClient.initialize(
      url,
      retry: false,
    );
    return connectionStatus;
  }

  static Future<int> getNodeChainIdentifier() async {
    int nodeChainId = 1;
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
    if (!Platform.isLinux && await Wakelock.enabled) {
      Wakelock.disable();
    }

    if (kCurrentNode == kLocalhostDefaultNodeUrl ||
        kCurrentNode == 'Embedded Node') {
      if (kEmbeddedNodeRunning) {
        sl.get<NotificationsBloc>().addNotification(
              WalletNotification(
                title: 'Waiting for embedded node to stop',
                timestamp: DateTime.now().millisecondsSinceEpoch,
                details:
                    'The app will close after the embedded node has been stopped',
                type: NotificationType.changedNode,
              ),
            );

        // If the message is null, it means that the isolate has closed
        Completer embeddedStoppedCompleter = Completer();
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

  static initWebSocketClient() async {
    addOnWebSocketConnectedCallback();
    var url = kCurrentNode!;
    bool connected = false;
    try {
      connected = await establishConnectionToNode(url);
    } on WebSocketException {
      url = kLocalhostDefaultNodeUrl;
    }
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
          .then((value) => NotificationUtils.sendNodeSyncingNotification());
      _initListenForUnreceivedAccountBlocks(allResponseBroadcaster);
    });
  }

  static Future<void> getUnreceivedTransactions() async {
    await Future.forEach<String?>(
      kDefaultAddressList,
      (address) async => await getUnreceivedTransactionsByAddress(
        Address.parse(address!),
      ),
    );
  }

  static Future<void> getUnreceivedTransactionsByAddress(
    Address address,
  ) async {
    List<AccountBlock> unreceivedBlocks =
        (await zenon!.ledger.getUnreceivedBlocksByAddress(
      address,
    ))
            .list!;

    if (unreceivedBlocks.isNotEmpty) {
      for (AccountBlock unreceivedBlock in unreceivedBlocks) {
        sl<AutoReceiveTxWorker>().addHash(unreceivedBlock.hash);
      }
    }
  }

  static void _initListenForUnreceivedAccountBlocks(Stream broadcaster) {
    broadcaster.listen(
      (event) {
        if (event!.containsKey('method') &&
            event['method'] == 'ledger.subscription') {
          for (var i = 0; i < event['params']['result'].length; i += 1) {
            var tx = event['params']['result'][i];
            if (tx.containsKey('toAddress') &&
                kDefaultAddressList.contains(tx['toAddress'])) {
              var hash = Hash.parse(tx['hash']);
              sl<AutoReceiveTxWorker>().addHash(hash);
            }
          }

          Map result = (event['params']['result'] as List).first;
          if (!result.containsKey('blockType') &&
              result['height'] != null &&
              (_kHeight == 0 || result['height'] >= _kHeight + 1)) {
            _kHeight = result['height'];
            if (sl<AutoReceiveTxWorker>().pool.isNotEmpty &&
                kKeyStore != null) {
              sl<AutoReceiveTxWorker>().autoReceive();
            }
          }
        }
      },
    );
  }

  static Future<void> _getSubscriptionForMomentums() async =>
      await zenon!.subscribe.toMomentums();

  static Future<void> _getSubscriptionForAllAccountEvents() async =>
      await zenon!.subscribe.toAllAccountBlocks();

  static Future<void> loadDbNodes() async {
    if (!Hive.isBoxOpen(kNodesBox)) {
      await Hive.openBox<String>(kNodesBox);
    }
    Box<String> nodesBox = Hive.box<String>(kNodesBox);
    if (kDbNodes.isNotEmpty) {
      kDbNodes.clear();
    }
    kDbNodes.addAll(nodesBox.values);
    // Handle the case in which some default nodes were deleted
    // so they can't be found in the cache
    String currentNode = kCurrentNode!;
    if (!kDefaultNodes.contains(currentNode) &&
        !kDbNodes.contains(currentNode)) {
      kDefaultNodes.add(currentNode);
    }
  }

  static Future<void> setNode() async {
    String savedNode = sharedPrefsService!.get(
      kSelectedNodeKey,
      defaultValue: kDefaultNodes.first,
    );
    kCurrentNode = savedNode;

    if (savedNode == 'Embedded Node') {
      // First we need to check if the node is not already running
      bool isConnectionEstablished =
          await NodeUtils.establishConnectionToNode(kLocalhostDefaultNodeUrl);
      if (isConnectionEstablished == false) {
        // Acquire WakeLock
        if (!Platform.isLinux && !await Wakelock.enabled) {
          Wakelock.enable();
        }
        // Initialize local full node
        await Isolate.spawn(EmbeddedNode.runNode, [''],
            onExit:
                sl<ReceivePort>(instanceName: 'embeddedStoppedPort').sendPort);

        kEmbeddedNodeRunning = true;
      }
    }
  }
}
