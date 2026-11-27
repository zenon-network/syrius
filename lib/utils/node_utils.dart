import 'dart:async';
import 'dart:isolate';

import 'package:hive_ce/hive_ce.dart';
import 'package:logging/logging.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:zenon_syrius_wallet_flutter/embedded_node/embedded_node.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:zenon_syrius_wallet_flutter/utils/notification_utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

int _kHeight = 0;

/// Utilities for managing embedded and remote Zenon node connections.
class NodeUtils {
  /// Attempts a single non-retrying WebSocket connection to [url].
  static Future<bool> establishConnectionToNode(String url) async {
    final bool connectionStatus = await zenon!.wsClient.initialize(
      url,
      retry: false,
    );
    return connectionStatus;
  }

  /// Queries the connected node's frontier momentum chain identifier, falling
  /// back to `1` if the request fails.
  static Future<int> getNodeChainIdentifier() async {
    int nodeChainId = 1;
    try {
      await zenon!.ledger.getFrontierMomentum().then((Momentum value) {
        nodeChainId = value.chainIdentifier;
      });
    } on Object catch (e, stackTrace) {
      Logger('NodeUtils')
          .log(Level.WARNING, 'getNodeChainIdentifier', e, stackTrace);
    }
    return nodeChainId;
  }

  /// Releases wake lock and stops the embedded full node if it is running.
  static Future<void> closeEmbeddedNode() async {
    // Release WakeLock
    if (await WakelockPlus.enabled) {
      unawaited(WakelockPlus.disable());
    }

    if (kCurrentNode == kLocalhostDefaultNodeUrl ||
        kCurrentNode == kEmbeddedNode) {
      if (kEmbeddedNodeRunning) {
        await sl.get<NotificationsBloc>().addNotification(
              WalletNotification(
                title: 'Waiting for Embedded Node to stop',
                timestamp: DateTime.now().millisecondsSinceEpoch,
                details:
                    'The app will close after the Embedded Node has been '
                    'stopped',
                type: NotificationType.changedNode,
              ),
            );

        // If the message is null, it means that the isolate has closed
        final Completer<void> embeddedStoppedCompleter = Completer<void>();
        sl<Stream<dynamic>>(instanceName: 'embeddedStoppedStream').listen(
          (dynamic message) {
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

  /// Stops the active Zenon WebSocket client, ignoring errors if uninitialized.
  static void stopWebSocketClient() {
    try {
      zenon!.wsClient.stop();
    } on Object catch (_) {}
  }

  /// Registers connection callbacks and connects the WebSocket client to the
  /// selected node, falling back to background retries if initial connect
  /// fails.
  static Future<void> initWebSocketClient() async {
    unawaited(addOnWebSocketConnectedCallback());
    final String url = kCurrentNode == kEmbeddedNode
        ? kLocalhostDefaultNodeUrl
        : kCurrentNode ?? '';
    bool connected = false;
    try {
      connected = await establishConnectionToNode(url);
    } on Object catch (_) {}
    if (!connected) {
      unawaited(
        zenon!.wsClient.initialize(
          url,
        ),
      );
    }
  }

  /// Registers the callback that subscribes to ledger events and starts
  /// auto-receive whenever the WebSocket connection is established.
  static Future<void> addOnWebSocketConnectedCallback() async {
    zenon!.wsClient.addOnConnectionEstablishedCallback((
      Stream<Map<String, dynamic>?> allResponseBroadcaster,
    ) async {
      kNodeChainId = await getNodeChainIdentifier();
      await _getSubscriptionForMomentums();
      await _getSubscriptionForAllAccountEvents();
      await getUnreceivedTransactions();

      unawaited(sl<AutoReceiveTxWorker>().autoReceive());
      unawaited(
        Future<void>.delayed(const Duration(seconds: 30)).then(
          (_) => NotificationUtils.sendNodeSyncingNotification(),
        ),
      );
      _initListenForUnreceivedAccountBlocks(allResponseBroadcaster);
    });
  }

  /// Fetches and queues unreceived transactions for every wallet address.
  static Future<void> getUnreceivedTransactions() async {
    await Future.forEach<String?>(
      kDefaultAddressList,
      (String? address) async {
        await getUnreceivedTransactionsByAddress(
          Address.parse(address!),
        );
      },
    );
  }

  /// Fetches unreceived account blocks for [address] and enqueues them when
  /// auto-receive is enabled.
  static Future<void> getUnreceivedTransactionsByAddress(
    Address address,
  ) async {
    final List<AccountBlock> unreceivedBlocks =
        (await zenon!.ledger.getUnreceivedBlocksByAddress(
      address,
    ))
            .list!;

    if (unreceivedBlocks.isNotEmpty) {
      for (final AccountBlock unreceivedBlock in unreceivedBlocks) {
        if (sharedPrefsService!.get(
          kAutoReceiveKey,
          defaultValue: kAutoReceiveDefaultValue,
        )) {
          unawaited(sl<AutoReceiveTxWorker>().addHash(unreceivedBlock.hash));
        }
      }
    }
  }

  /// Checks whether the local system clock differs significantly from the
  /// synced node's frontier momentum timestamp and notifies with
  /// [warningMessage].
  static Future<void> checkForLocalTimeDiscrepancy(
    String warningMessage,
  ) async {
    const Duration maxAllowedDiscrepancy = Duration(minutes: 5);
    try {
      final SyncInfo syncInfo = await zenon!.stats.syncInfo();
      final bool nodeIsSynced = syncInfo.state == SyncState.syncDone ||
          (syncInfo.targetHeight > 0 &&
              syncInfo.currentHeight > 0 &&
              (syncInfo.targetHeight - syncInfo.currentHeight) < 20);
      if (nodeIsSynced) {
        final int frontierTime =
            (await zenon!.ledger.getFrontierMomentum()).timestamp;
        final int timeDifference =
            (frontierTime - DateTime.now().unixTimestamp).abs();
        if (timeDifference > maxAllowedDiscrepancy.inSeconds) {
          await NotificationUtils.sendNotificationError(
            Exception('Local time discrepancy detected.'),
            warningMessage,
          );
        }
      }
    } on Object catch (e, stackTrace) {
      Logger('NodeUtils')
          .log(Level.WARNING, 'checkForLocalTimeDiscrepancy', e, stackTrace);
    }
  }

  static void _initListenForUnreceivedAccountBlocks(
    Stream<Map<String, dynamic>?> broadcaster,
  ) {
    broadcaster.listen(
      (Map<String, dynamic>? event) {
        // Only process unreceived account blocks when autoReceive is enabled
        if (event != null &&
            event.containsKey('method') &&
            event['method'] == 'ledger.subscription' &&
            (sharedPrefsService!.get(
                  kAutoReceiveKey,
                  defaultValue: kAutoReceiveDefaultValue,
                )
                as bool)) {
          final Map<dynamic, dynamic> params =
              event['params'] as Map<dynamic, dynamic>;
          final List<dynamic> results = params['result'] as List<dynamic>;
          for (int i = 0; i < results.length; i += 1) {
            final Map<dynamic, dynamic> tx =
                results[i] as Map<dynamic, dynamic>;
            if (tx.containsKey('toAddress') &&
                kDefaultAddressList.contains(tx['toAddress'])) {
              final Hash hash = Hash.parse(tx['hash'] as String);
              unawaited(sl<AutoReceiveTxWorker>().addHash(hash));
            }
          }

          final Map<dynamic, dynamic> result =
              results.first as Map<dynamic, dynamic>;
          final Object? height = result['height'];
          if (!result.containsKey('blockType') &&
              height is int &&
              (_kHeight == 0 || height >= _kHeight + 1)) {
            _kHeight = height;
            if (sl<AutoReceiveTxWorker>().pool.isNotEmpty &&
                kWalletFile != null) {
              unawaited(sl<AutoReceiveTxWorker>().autoReceive());
            }
          }
        }
      },
    );
  }

  static Future<void> _getSubscriptionForMomentums() =>
      zenon!.subscribe.toMomentums();

  static Future<void> _getSubscriptionForAllAccountEvents() =>
      zenon!.subscribe.toAllAccountBlocks();

  /// Loads persisted user node URLs from Hive into [kDbNodes].
  static Future<void> loadDbNodes() async {
    if (!Hive.isBoxOpen(kNodesBox)) {
      await Hive.openBox<String>(kNodesBox);
    }
    final Box<String> nodesBox = Hive.box<String>(kNodesBox);
    if (kDbNodes.isNotEmpty) {
      kDbNodes.clear();
    }
    kDbNodes.addAll(nodesBox.values);
    // Handle the case in which some default nodes were deleted
    // so they can't be found in the cache
    final String? currentNode = kCurrentNode;
    if (currentNode != null &&
        !kDefaultNodes.contains(currentNode) &&
        !kDbNodes.contains(currentNode)) {
      kDefaultNodes.add(currentNode);
    }
  }

  /// Restores the saved node selection into [kCurrentNode] and starts the
  /// embedded full node when selected and not already reachable.
  static Future<void> setNode() async {
    final String? savedNode = sharedPrefsService!.get(kSelectedNodeKey);
    kCurrentNode = savedNode;

    if (savedNode == kEmbeddedNode) {
      // First we need to check if the node is not already running
      final bool isConnectionEstablished =
          await NodeUtils.establishConnectionToNode(kLocalhostDefaultNodeUrl);
      if (!isConnectionEstablished) {
        // Acquire WakeLock
        if (!await WakelockPlus.enabled) {
          unawaited(WakelockPlus.enable());
        }
        // Initialize local full node
        await Isolate.spawn(
          EmbeddedNode.runNode,
          <String>[''],
          onExit:
              sl<ReceivePort>(instanceName: 'embeddedStoppedPort').sendPort,
        );

        kEmbeddedNodeRunning = true;
      }
    }
  }
}
