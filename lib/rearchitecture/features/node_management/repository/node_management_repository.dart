import 'dart:isolate';

import 'package:hive_ce/hive_ce.dart';
import 'package:logging/logging.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:zenon_syrius_wallet_flutter/embedded_node/embedded_node.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/auto_receive_tx/auto_receive_tx.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/notifications/notifications.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/p2p_swaps/data/htlc_swap_repository.dart';
import 'package:zenon_syrius_wallet_flutter/services/i_web3wallet_service.dart';
import 'package:zenon_syrius_wallet_flutter/services/shared_prefs_service.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// Persistence and connection operations for Node Management views.
abstract interface class NodeManagementRepository {
  /// Shuffles the default community nodes list for balanced load distribution.
  void shuffleCommunityNodes();

  /// Returns all available nodes (default, community, and user-added).
  List<String> getAvailableNodes();

  /// Returns whether [node] is a built-in default node.
  bool isDefaultNode(String node);

  /// Returns whether [node] is a community node.
  bool isCommunityNode(String node);

  /// Returns the currently active node, or [fallback] if none is configured.
  String getCurrentNode({required String fallback});

  /// Returns the configured client chain identifier.
  int getClientChainId();

  /// Fetches the connected node's chain identifier.
  Future<int> getNodeChainId();

  /// Fetches the frontier momentum's chain identifier from the connected node.
  Future<int> getFrontierChainId();

  /// Establishes a WebSocket connection to [node] (starting or stopping the
  /// embedded node as required).
  Future<bool> connectToNode(String node);

  /// Closes the active WebSocket connection so stale RPC clients are not used.
  void disconnectFromNode();

  /// Persists [node] as the selected node and updates [kCurrentNode].
  Future<void> saveSelectedNode(String node);

  /// Resets the last checked HTLC swap block height for [chainId] after
  /// switching nodes.
  Future<void> resetLastCheckedHtlcBlockHeight({required int chainId});

  /// Adds a custom [node] URL to Hive storage and reloads cached DB nodes.
  Future<void> addCustomNode(String node);

  /// Replaces [oldNode] with [newNode] in Hive storage and reloads DB nodes.
  Future<void> updateCustomNode({
    required String oldNode,
    required String newNode,
  });

  /// Deletes custom [node] from Hive storage and updates cached DB nodes.
  Future<void> deleteCustomNode(String node);

  /// Persists [chainId] and updates the SDK chain identifier.
  Future<void> saveClientChainId(int chainId);

  /// Notifies WalletConnect sessions about the updated client [chainId].
  Future<void> notifyClientChainIdChanged(int chainId);

  /// Returns whether auto-receive is currently enabled.
  bool getAutoReceive();

  /// Persists the auto-receive preference.
  Future<void> saveAutoReceive({required bool enabled});

  /// Fetches unreceived transactions and triggers the auto-receive worker.
  Future<void> triggerAutoReceive();

  /// Clears any pending auto-receive transaction hashes.
  void clearAutoReceivePool();

  /// Records a wallet notification.
  Future<void> addNotification(WalletNotification notification);

  /// Records an error notification.
  Future<void> reportError(Object error, String title);
}

/// Default Hive/SDK implementation of [NodeManagementRepository].
final class DefaultNodeManagementRepository
    implements NodeManagementRepository {
  /// Creates a [DefaultNodeManagementRepository].
  DefaultNodeManagementRepository({this._prefsService});

  final SharedPrefsService? _prefsService;

  SharedPrefsService get _prefs => _prefsService ?? sharedPrefsService!;

  @override
  void shuffleCommunityNodes() {
    kDefaultCommunityNodes.shuffle();
  }

  @override
  List<String> getAvailableNodes() => <String>{
    ...kDefaultNodes,
    ...kDefaultCommunityNodes,
    ...kDbNodes,
  }.toList(growable: false);

  @override
  bool isDefaultNode(String node) => kDefaultNodes.contains(node);

  @override
  bool isCommunityNode(String node) => kDefaultCommunityNodes.contains(node);

  @override
  String getCurrentNode({required String fallback}) => kCurrentNode ?? fallback;

  @override
  int getClientChainId() =>
      _prefs.get(kChainIdKey, defaultValue: kChainIdDefaultValue) as int;

  @override
  Future<int> getNodeChainId() => NodeUtils.getNodeChainIdentifier();

  @override
  Future<int> getFrontierChainId() async {
    final Momentum momentum = await zenon!.ledger.getFrontierMomentum();
    return momentum.chainIdentifier;
  }

  @override
  Future<bool> connectToNode(String node) async {
    if (!await WakelockPlus.enabled) {
      await WakelockPlus.enable();
    }

    final String targetUrl = node == kEmbeddedNode
        ? kLocalhostDefaultNodeUrl
        : node;
    bool isConnectionEstablished = await NodeUtils.establishConnectionToNode(
      targetUrl,
    );
    if (node == kEmbeddedNode) {
      if (!isConnectionEstablished) {
        await Isolate.spawn(
          EmbeddedNode.runNode,
          <String>[''],
          onExit: sl<ReceivePort>(instanceName: 'embeddedStoppedPort').sendPort,
          debugName: 'EmbeddedNodeIsolate',
        );
        kEmbeddedNodeRunning = true;
        await Future<void>.delayed(kEmbeddedConnectionDelay);
        isConnectionEstablished = await NodeUtils.establishConnectionToNode(
          targetUrl,
        );
      }
    } else if (isConnectionEstablished) {
      await NodeUtils.closeEmbeddedNode();
    }
    return isConnectionEstablished;
  }

  @override
  void disconnectFromNode() {
    NodeUtils.stopWebSocketClient();
  }

  @override
  Future<void> saveSelectedNode(String node) async {
    await _prefs.put(kSelectedNodeKey, node);
    kCurrentNode = node;
  }

  @override
  Future<void> resetLastCheckedHtlcBlockHeight({required int chainId}) async {
    await sl<HtlcSwapRepository>().storeLastCheckedHtlcBlockHeight(
      0,
      chainId: chainId,
    );
  }

  @override
  Future<void> addCustomNode(String node) async {
    if (!Hive.isBoxOpen(kNodesBox)) {
      await Hive.openBox<String>(kNodesBox);
    }
    await Hive.box<String>(kNodesBox).add(node);
    await NodeUtils.loadDbNodes();
  }

  @override
  Future<void> updateCustomNode({
    required String oldNode,
    required String newNode,
  }) async {
    if (!Hive.isBoxOpen(kNodesBox)) {
      await Hive.openBox<String>(kNodesBox);
    }
    final Box<String> nodesBox = Hive.box<String>(kNodesBox);
    final dynamic nodeKey = nodesBox.keys.firstWhere(
      (dynamic key) => nodesBox.get(key) == oldNode,
    );
    await nodesBox.put(nodeKey, newNode);
    await NodeUtils.loadDbNodes();
  }

  @override
  Future<void> deleteCustomNode(String node) async {
    if (!Hive.isBoxOpen(kNodesBox)) {
      await Hive.openBox<String>(kNodesBox);
    }
    final Box<String> nodesBox = Hive.box<String>(kNodesBox);
    final dynamic nodeKey = nodesBox.keys.firstWhere(
      (dynamic key) => nodesBox.get(key) == node,
    );
    await nodesBox.delete(nodeKey);
    kDbNodes.remove(node);
  }

  @override
  Future<void> saveClientChainId(int chainId) async {
    await _prefs.put(kChainIdKey, chainId);
    setChainIdentifier(chainIdentifier: chainId);
  }

  @override
  Future<void> notifyClientChainIdChanged(int chainId) async {
    await sl<IWeb3WalletService>().emitChainIdChangeEvent(chainId.toString());
  }

  @override
  bool getAutoReceive() =>
      _prefs.get(kAutoReceiveKey, defaultValue: kAutoReceiveDefaultValue)
          as bool;

  @override
  Future<void> saveAutoReceive({required bool enabled}) async {
    await _prefs.put(kAutoReceiveKey, enabled);
  }

  @override
  Future<void> triggerAutoReceive() async {
    try {
      await NodeUtils.getUnreceivedTransactions();
      await sl<AutoReceiveTxWorker>().autoReceive();
    } on Object catch (error, stackTrace) {
      Logger(
        'DefaultNodeManagementRepository',
      ).log(Level.WARNING, 'triggerAutoReceive', error, stackTrace);
    }
  }

  @override
  void clearAutoReceivePool() {
    if (sl<AutoReceiveTxWorker>().pool.isNotEmpty) {
      sl<AutoReceiveTxWorker>().pool.clear();
    }
  }

  @override
  Future<void> addNotification(WalletNotification notification) =>
      sl.get<NotificationsBloc>().addNotification(notification);

  @override
  Future<void> reportError(Object error, String title) =>
      NotificationUtils.sendNotificationError(error, title);
}
