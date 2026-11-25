import 'dart:async';

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:reown_walletkit/reown_walletkit.dart';
import 'package:window_manager/window_manager.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/notifications_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/wallet_connect/chains/i_chain.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/wallet_connect/chains/nom_service.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/model/database/notification_type.dart';
import 'package:zenon_syrius_wallet_flutter/model/database/wallet_notification.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/wallet_connect_metadata_utils.dart';
import 'package:zenon_syrius_wallet_flutter/services/desktop_signing_wallet_kit.dart';
import 'package:zenon_syrius_wallet_flutter/services/i_web3wallet_service.dart';
import 'package:zenon_syrius_wallet_flutter/services/sticky_fallback_secure_store.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/dialogs.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/icons/link_icon.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// Desktop WalletConnect v2 service backed by [DesktopSigningWalletKit] and
/// [StickyFallbackSecureStore].
class Web3WalletService extends IWeb3WalletService {
  /// Creates a [Web3WalletService].
  ///
  /// Optional [walletKit], [_chainResolver], and [inFlightPairWaitTimeout]
  /// overrides exist solely for deterministic unit testing without a live
  /// relay or global service locator.
  Web3WalletService({
    @visibleForTesting ReownWalletKit? walletKit,
    @visibleForTesting this._chainResolver,
    @visibleForTesting Duration? inFlightPairWaitTimeout,
  }) : _wcClient = walletKit,
       _inFlightPairWaitTimeout =
           inFlightPairWaitTimeout ?? _defaultInFlightPairWaitTimeout;

  static const Duration _defaultInFlightPairWaitTimeout = Duration(seconds: 5);

  static const List<String> _supportedNoMMethods = <String>[
    'znn_sign',
    'znn_info',
    'znn_send',
  ];
  static const List<String> _supportedNoMEvents = <String>[
    'chainIdChange',
    'addressChange',
  ];

  static const int _maxCompletedRequestIds = 512;

  /// Storage key persisted in `core.storage` when [disconnectEverything] is
  /// invoked before initialization completes (or while offline), ensuring a
  /// wallet reset survives an immediate process exit.
  @visibleForTesting
  static const String pendingResetStorageKey = 'syrius_pending_wc_reset';

  final Logger _logger = Logger('WalletConnectService');
  final IChain Function(String chainId)? _chainResolver;
  final Duration _inFlightPairWaitTimeout;

  ReownWalletKit? _wcClient;
  Future<void>? _initFuture;
  Future<void>? _pendingResetMarkerPersist;
  Future<void>? _resetInFlight;
  Future<void> _markerOpQueue = Future<void>.value();
  int _activeResetDepth = 0;
  int _resetRequestEpoch = 0;
  int _resetGeneration = 0;
  bool _isInitialized = false;
  bool _isDisposed = false;
  bool _listenersSubscribed = false;
  bool _pendingDisconnectEverything = false;
  bool _hasUnresolvedReset = false;
  bool _hasUnresolvedFullReset = false;
  bool _hasUnconfirmedResetMarkerWrite = false;
  bool _needsRelayReconnectAfterRecovery = false;
  bool _needsKeyChainPersist = false;
  bool _needsExpirerPersist = false;

  bool get _isResetting => _activeResetDepth > 0;
  bool get _hasActiveOrPendingReset =>
      _isResetting ||
      _hasUnresolvedReset ||
      _pendingDisconnectEverything ||
      _hasPendingResetMarker();

  final Set<Future<void>> _inFlightPairCalls = <Future<void>>{};
  final Set<Future<void>> _timedOutInFlightPairCalls = <Future<void>>{};

  final Map<String, String> _pendingSessionCleanups = <String, String>{};
  final Set<String> _pendingPairingCleanups = <String>{};
  final Set<String> _topicsNeedingSessionStorePersist = <String>{};
  final Set<String> _topicsNeedingPairingStorePersist = <String>{};

  final Set<int> _approvedProposalIds = <int>{};
  final Set<int> _proposalIdsInFlight = <int>{};
  final Map<int, String> _proposalPairingTopicsInFlight = <int, String>{};
  final Set<int> _inFlightRequestIds = <int>{};
  final Set<int> _completedRequestIds = <int>{};
  final Map<int, JsonRpcResponse<dynamic>> _pendingUnsentResponses =
      <int, JsonRpcResponse<dynamic>>{};
  final Set<String> _stalePendingTopics = <String>{};
  final Set<String> _registeredAccounts = <String>{};

  @override
  ValueNotifier<List<PairingInfo>> pairings = ValueNotifier<List<PairingInfo>>(
    <PairingInfo>[],
  );

  @override
  ValueNotifier<List<SessionData>> sessions = ValueNotifier<List<SessionData>>(
    <SessionData>[],
  );

  bool get _isCreated => _wcClient != null;
  String get _namespaceChainId => 'zenon:${getChainIdentifier()}';
  List<String> get _supportedNoMChainIds =>
      NoMChainId.values.map((NoMChainId chainId) => chainId.chain()).toList();
  bool _isSupportedChainId(String chainId) =>
      _supportedNoMChainIds.contains(chainId);

  @override
  void create() {
    if (_wcClient == null) {
      if (kWcProjectId.isEmpty) {
        _logger.warning('WalletConnect project id missing');
        return;
      }

      _wcClient = DesktopSigningWalletKit(
        core: createDesktopReownCore(projectId: kWcProjectId),
        metadata: const PairingMetadata(
          name: 's y r i u s',
          description: 'A wallet for interacting with Zenon Network',
          url: 'https://zenon.network',
          icons: <String>[
            'https://raw.githubusercontent.com/zenon-network/syrius/master/macos/Runner/Assets.xcassets/AppIcon.appiconset/Icon-MacOS-512x512%402x.png',
          ],
        ),
      );
    }

    if (!_listenersSubscribed) {
      _subscribeListeners();
    }
  }

  @override
  Future<void> init() async {
    if (!_isCreated) {
      _logger.warning('init called before create');
      return;
    }

    if (_isInitialized) {
      return;
    }

    final Future<void>? pendingInit = _initFuture;
    if (pendingInit != null) {
      await pendingInit;
      return;
    }

    _initFuture = _initialize();
    try {
      await _initFuture;
    } finally {
      if (!_isInitialized) {
        _initFuture = null;
      }
    }
  }

  Future<void> _initialize() async {
    if (!_listenersSubscribed) {
      _subscribeListeners();
    }
    _registerEventEmitters();
    _registerRequestHandlers();
    registerAccountsIfNeeded();

    await _wcClient!.init();
    if (_isDisposed || _wcClient == null) {
      return;
    }

    registerAccountsIfNeeded();

    if (_pendingDisconnectEverything || _hasPendingResetMarker()) {
      bool forceFullReset = _pendingDisconnectEverything;
      _pendingDisconnectEverything = false;
      _hasUnresolvedReset = true;
      await _runInitializedReset(
        forceFullReset: forceFullReset,
        rethrowMarkerWriteError: false,
        storesReady: true,
      );
      while (_pendingDisconnectEverything &&
          !_isDisposed &&
          _wcClient != null) {
        _pendingDisconnectEverything = false;
        forceFullReset = true;
        await _runInitializedReset(
          forceFullReset: forceFullReset,
          rethrowMarkerWriteError: false,
          storesReady: true,
        );
      }
      if (_isDisposed || _wcClient == null) {
        return;
      }
      _isInitialized = true;
      if (!_hasUnresolvedReset) {
        _reloadStores();
        await _disconnectUnsupportedSessions();
        unawaited(_drainPendingSessionRequests());
      }
      return;
    }

    _isInitialized = true;
    _reloadStores();
    await _disconnectUnsupportedSessions();
    unawaited(_drainPendingSessionRequests());
  }

  @override
  FutureOr<void> onDispose() {
    if (_isDisposed) {
      return null;
    }
    _isDisposed = true;

    if (_wcClient != null && _listenersSubscribed) {
      _unsubscribeListeners();
    }

    _approvedProposalIds.clear();
    _proposalIdsInFlight.clear();
    _proposalPairingTopicsInFlight.clear();
    _inFlightRequestIds.clear();
    _completedRequestIds.clear();
    _pendingUnsentResponses.clear();
    _stalePendingTopics.clear();
    _registeredAccounts.clear();
    _pendingSessionCleanups.clear();
    _pendingPairingCleanups.clear();
    _topicsNeedingSessionStorePersist.clear();
    _topicsNeedingPairingStorePersist.clear();
    _pendingDisconnectEverything = false;
    _resetInFlight = null;
    _hasUnresolvedReset = false;
    _hasUnresolvedFullReset = false;
    _hasUnconfirmedResetMarkerWrite = false;
    _needsRelayReconnectAfterRecovery = false;
    _needsKeyChainPersist = false;
    _needsExpirerPersist = false;
    _inFlightPairCalls.clear();
    _timedOutInFlightPairCalls.clear();
    _pendingResetMarkerPersist = null;
    _initFuture = null;
    _isInitialized = false;
    _wcClient = null;

    pairings.dispose();
    sessions.dispose();
  }

  @override
  ReownWalletKit getWeb3Wallet() => _wcClient!;

  @override
  Future<PairingInfo> pair(Uri uri) async {
    if (_wcClient == null) {
      throw StateError('WalletConnect client not created');
    }

    await init();

    if (!_isInitialized) {
      throw StateError('WalletConnect client not initialized');
    }

    if (_hasActiveOrPendingReset) {
      await _runInitializedReset(
        forceFullReset: false,
        rethrowMarkerWriteError: false,
      );
      if (_hasActiveOrPendingReset) {
        throw StateError(
          'WalletConnect reset cleanup is still pending; cannot create a new '
          'pairing until the reset marker is cleared',
        );
      }
      unawaited(_drainPendingSessionRequests());
    }

    if (kAddressLabelMap.isEmpty) {
      throw StateError('No wallet addresses available');
    }

    final int capturedResetGeneration = _resetGeneration;
    registerAccountsIfNeeded();
    await _cleanupStalePairings(
      expectedResetGeneration: capturedResetGeneration,
    );

    if (_isDisposed || _wcClient == null) {
      throw StateError('WalletConnect client not initialized');
    }
    if (_hasActiveOrPendingReset ||
        _resetGeneration != capturedResetGeneration) {
      throw StateError(
        'WalletConnect reset cleanup is in progress or pending; cannot '
        'create a new pairing until the reset marker is cleared',
      );
    }

    final Completer<void> pairDone = Completer<void>();
    _inFlightPairCalls.add(pairDone.future);
    late final PairingInfo pairing;
    try {
      pairing = await _wcClient!.pair(uri: uri);
    } finally {
      _inFlightPairCalls.remove(pairDone.future);
      _timedOutInFlightPairCalls.remove(pairDone.future);
      pairDone.complete();
    }

    if (_isDisposed ||
        _wcClient == null ||
        _hasActiveOrPendingReset ||
        _resetGeneration != capturedResetGeneration) {
      _reloadStores();
      throw StateError(
        'WalletConnect reset ran while creating pairing; pairing was aborted',
      );
    }

    _reloadStores();
    return pairing;
  }

  Future<void> _cleanupStalePairings({
    required int expectedResetGeneration,
  }) async {
    if (_wcClient == null ||
        _isDisposed ||
        _hasActiveOrPendingReset ||
        _resetGeneration != expectedResetGeneration) {
      return;
    }

    final List<PairingInfo> currentPairings = List<PairingInfo>.from(
      _wcClient!.pairings.getAll(),
    );

    for (final PairingInfo pairing in currentPairings) {
      if (_wcClient == null ||
          _isDisposed ||
          _hasActiveOrPendingReset ||
          _resetGeneration != expectedResetGeneration) {
        return;
      }
      if (_isPairingProtectedByProposal(pairing.topic)) {
        continue;
      }

      final Map<String, SessionData> sessionsForPairing = _wcClient!
          .getSessionsForPairing(pairingTopic: pairing.topic);
      if (sessionsForPairing.isNotEmpty) {
        continue;
      }

      final int nowSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      final bool isExpired = pairing.expiry <= nowSeconds;
      final bool isInactive = !pairing.active;
      if (!isInactive && !isExpired) {
        continue;
      }

      try {
        _logger.info('Removing stale orphan pairing: ${pairing.topic}');
        await _wcClient!.core.pairing.disconnect(topic: pairing.topic);
      } on Object catch (e, s) {
        _logger.warning(
          'Failed to remove orphan pairing ${pairing.topic}',
          e,
          s,
        );
      }
    }

    if (_wcClient == null ||
        _isDisposed ||
        _hasActiveOrPendingReset ||
        _resetGeneration != expectedResetGeneration) {
      return;
    }
    _reloadStores();
  }

  bool _isPairingProtectedByProposal(String pairingTopic) {
    return _proposalPairingTopicsInFlight.containsValue(pairingTopic) ||
        _safeGetPendingProposalPairingTopics().contains(pairingTopic);
  }

  Set<String> _safeGetPendingProposalPairingTopics() {
    try {
      return _wcClient!
          .getPendingSessionProposals()
          .values
          .map((ProposalData proposal) => proposal.pairingTopic)
          .where((String topic) => topic.isNotEmpty)
          .toSet();
    } on Object {
      return const <String>{};
    }
  }

  Future<void> _disconnectUnsupportedSessions() async {
    if (_wcClient == null) return;

    bool disconnectedAny = false;
    final List<SessionData> currentSessions = List<SessionData>.from(
      _wcClient!.sessions.getAll(),
    );
    for (final SessionData session in currentSessions) {
      final List<String>? chains =
          session.namespaces[NoMService.namespace]?.chains;
      final bool hasSupportedChain =
          chains != null &&
          chains.isNotEmpty &&
          _isSupportedChainId(chains.first);
      if (hasSupportedChain) {
        continue;
      }

      disconnectedAny = true;
      try {
        _logger.warning(
          'Disconnecting stored session ${session.topic} with unsupported '
          'chain(s): $chains',
        );
        await _wcClient!.disconnectSession(
          topic: session.topic,
          reason: Errors.getSdkError(Errors.UNSUPPORTED_CHAINS).toSignError(),
        );
      } on Object catch (e, s) {
        _logger.warning(
          'Failed to disconnect unsupported session ${session.topic}',
          e,
          s,
        );
      }
    }

    if (disconnectedAny) {
      _reloadStores();
    }
  }

  @override
  Future<void> activatePairing({required String topic}) async {
    if (_wcClient == null) {
      return;
    }
    await _wcClient!.core.pairing.activate(topic: topic);
    _reloadStores();
  }

  @override
  Future<void> deactivatePairing({required String topic}) async {
    if (_wcClient == null) {
      throw StateError('WalletConnect client not created');
    }
    try {
      await _wcClient!.core.pairing.disconnect(topic: topic);
      _approvedProposalIds.clear();
      _reloadStores();
    } on ReownCoreError catch (e) {
      _logger.warning('Failed to deactivate pairing: ${e.code} ${e.message}');
      rethrow;
    } on Object catch (e, s) {
      _logger.severe('Unexpected error while deactivating pairing', e, s);
      rethrow;
    }
  }

  @override
  Map<String, SessionData> getSessionsForPairing(String pairingTopic) {
    if (_wcClient == null) {
      return <String, SessionData>{};
    }
    return _wcClient!.getSessionsForPairing(pairingTopic: pairingTopic);
  }

  @override
  Future<void> emitAddressChangeEvent(String newAddress) {
    return _emitEventPairedDApps(
      changeName: 'addressChange',
      newValue: newAddress,
    );
  }

  @override
  Future<void> emitChainIdChangeEvent(String newChainId) {
    registerAccountsIfNeeded();
    return _emitEventPairedDApps(
      changeName: 'chainIdChange',
      newValue: newChainId,
    );
  }

  @override
  Future<void> disconnectSessions() async {
    if (_wcClient == null) {
      return;
    }

    final Map<String, String> unfinished = await _disconnectSessionsInternal(
      includeLiveSessions: true,
      residualSessions: Map<String, String>.from(_pendingSessionCleanups),
    );
    _pendingSessionCleanups
      ..clear()
      ..addAll(unfinished);
  }

  Future<Map<String, String>> _disconnectSessionsInternal({
    required bool includeLiveSessions,
    Map<String, String> residualSessions = const <String, String>{},
    Set<String>? allowedLiveTopics,
    bool storesReady = false,
  }) async {
    if (_wcClient == null) {
      return Map<String, String>.from(residualSessions);
    }

    final Map<String, SessionData> sessionsByTopic = <String, SessionData>{
      if (includeLiveSessions) ...<String, SessionData>{
        for (final SessionData session in sessions.value)
          if (allowedLiveTopics == null ||
              allowedLiveTopics.contains(session.topic))
            session.topic: session,
        if (_isInitialized || storesReady)
          for (final SessionData session in _wcClient!.sessions.getAll())
            if (allowedLiveTopics == null ||
                allowedLiveTopics.contains(session.topic))
              session.topic: session,
      },
    };
    final Map<String, String> unfinishedSessions = <String, String>{};

    for (final SessionData session in sessionsByTopic.values) {
      try {
        await _wcClient!.disconnectSession(
          topic: session.topic,
          reason: Errors.getSdkError(Errors.USER_DISCONNECTED).toSignError(),
        );
        _topicsNeedingSessionStorePersist.remove(session.topic);
      } on Object catch (e, s) {
        _logger.warning(
          'Failed to disconnect session ${session.topic} remotely; '
          'purging local session state and key material',
          e,
          s,
        );
        // Reown's disconnectSession can delete in-memory session, keychain, and
        // expirer entries before calling persist(), so ensure the follow-up
        // local purge flushes all three stores even if delete() is a no-op.
        _topicsNeedingSessionStorePersist.add(session.topic);
        _needsKeyChainPersist = true;
        _needsExpirerPersist = true;
        final bool purged = await _purgeSessionLocally(
          topic: session.topic,
          publicKey: session.self.publicKey,
        );
        if (!purged) {
          unfinishedSessions[session.topic] = session.self.publicKey;
        }
      }
    }

    for (final MapEntry<String, String> residual in residualSessions.entries) {
      if (sessionsByTopic.containsKey(residual.key)) {
        continue;
      }
      final bool purged = await _purgeSessionLocally(
        topic: residual.key,
        publicKey: residual.value,
      );
      if (!purged) {
        unfinishedSessions[residual.key] = residual.value;
      }
    }

    _approvedProposalIds.clear();
    _pendingUnsentResponses.clear();
    _reloadStores();
    return unfinishedSessions;
  }

  Future<bool> _purgeSessionLocally({
    required String topic,
    required String publicKey,
  }) async {
    if (_wcClient == null) return false;

    bool allLocalDeletesSucceeded = true;
    bool keyChainDeletesSucceeded = true;
    bool expirerDeleteSucceeded = true;

    try {
      await _wcClient!.sessions.delete(topic);
      if (_topicsNeedingSessionStorePersist.contains(topic)) {
        await _wcClient!.sessions.persist();
        _topicsNeedingSessionStorePersist.remove(topic);
      }
    } on Object catch (e, s) {
      allLocalDeletesSucceeded = false;
      _topicsNeedingSessionStorePersist.add(topic);
      _logger.warning('Failed deleting local session $topic', e, s);
    }
    if (publicKey.isNotEmpty) {
      try {
        await _wcClient!.core.crypto.deleteKeyPair(publicKey);
      } on Object catch (e, s) {
        allLocalDeletesSucceeded = false;
        keyChainDeletesSucceeded = false;
        _needsKeyChainPersist = true;
        _logger.warning('Failed deleting session key pair for $topic', e, s);
      }
    }
    try {
      await _wcClient!.core.crypto.deleteSymKey(topic);
    } on Object catch (e, s) {
      allLocalDeletesSucceeded = false;
      keyChainDeletesSucceeded = false;
      _needsKeyChainPersist = true;
      _logger.warning('Failed deleting session symKey for $topic', e, s);
    }
    if (keyChainDeletesSucceeded && _needsKeyChainPersist) {
      try {
        await _wcClient!.core.crypto.keyChain.persist();
        _needsKeyChainPersist = false;
      } on Object catch (e, s) {
        allLocalDeletesSucceeded = false;
        _logger.warning(
          'Failed persisting keychain after deleting keys for session $topic',
          e,
          s,
        );
      }
    }
    try {
      await _wcClient!.core.expirer.delete(topic);
    } on Object catch (e, s) {
      allLocalDeletesSucceeded = false;
      expirerDeleteSucceeded = false;
      _needsExpirerPersist = true;
      _logger.warning('Failed deleting session expirer entry for $topic', e, s);
    }
    if (expirerDeleteSucceeded && _needsExpirerPersist) {
      try {
        await _wcClient!.core.expirer.persist();
        _needsExpirerPersist = false;
      } on Object catch (e, s) {
        allLocalDeletesSucceeded = false;
        _logger.warning(
          'Failed persisting expirer after deleting session $topic',
          e,
          s,
        );
      }
    }
    try {
      await _wcClient!.core.relayClient
          .unsubscribe(topic: topic)
          .timeout(_inFlightPairWaitTimeout);
    } on Object {
      // Relay may be offline or unresponsive during local reset.
    }

    return allLocalDeletesSucceeded;
  }

  Future<bool> _purgePairingLocally({required String topic}) async {
    if (_wcClient == null) return false;

    bool allLocalDeletesSucceeded = true;
    bool keyChainDeleteSucceeded = true;
    bool expirerDeleteSucceeded = true;

    try {
      await _wcClient!.pairings.delete(topic);
      if (_topicsNeedingPairingStorePersist.contains(topic)) {
        await _wcClient!.pairings.persist();
        _topicsNeedingPairingStorePersist.remove(topic);
      }
    } on Object catch (e, s) {
      allLocalDeletesSucceeded = false;
      _topicsNeedingPairingStorePersist.add(topic);
      _logger.warning('Failed deleting local pairing $topic', e, s);
    }
    try {
      await _wcClient!.core.crypto.deleteSymKey(topic);
    } on Object catch (e, s) {
      allLocalDeletesSucceeded = false;
      keyChainDeleteSucceeded = false;
      _needsKeyChainPersist = true;
      _logger.warning('Failed deleting pairing symKey for $topic', e, s);
    }
    if (keyChainDeleteSucceeded && _needsKeyChainPersist) {
      try {
        await _wcClient!.core.crypto.keyChain.persist();
        _needsKeyChainPersist = false;
      } on Object catch (e, s) {
        allLocalDeletesSucceeded = false;
        _logger.warning(
          'Failed persisting keychain after deleting symKey for pairing $topic',
          e,
          s,
        );
      }
    }
    try {
      await _wcClient!.core.expirer.delete(topic);
    } on Object catch (e, s) {
      allLocalDeletesSucceeded = false;
      expirerDeleteSucceeded = false;
      _needsExpirerPersist = true;
      _logger.warning('Failed deleting pairing expirer entry for $topic', e, s);
    }
    if (expirerDeleteSucceeded && _needsExpirerPersist) {
      try {
        await _wcClient!.core.expirer.persist();
        _needsExpirerPersist = false;
      } on Object catch (e, s) {
        allLocalDeletesSucceeded = false;
        _logger.warning(
          'Failed persisting expirer after deleting pairing $topic',
          e,
          s,
        );
      }
    }
    try {
      await _wcClient!.core.relayClient
          .unsubscribe(topic: topic)
          .timeout(_inFlightPairWaitTimeout);
    } on Object {
      // Relay may be offline or unresponsive during local reset.
    }

    return allLocalDeletesSucceeded;
  }

  @override
  Future<void> disconnectAllPairings() async {
    if (_wcClient == null) {
      return;
    }

    final Set<String> unfinished = await _disconnectPairingsInternal(
      includeLivePairings: true,
      residualPairings: Set<String>.from(_pendingPairingCleanups),
    );
    _pendingPairingCleanups
      ..clear()
      ..addAll(unfinished);
  }

  Future<Set<String>> _disconnectPairingsInternal({
    required bool includeLivePairings,
    Set<String> residualPairings = const <String>{},
    Set<String>? allowedLiveTopics,
    bool storesReady = false,
  }) async {
    if (_wcClient == null) {
      return Set<String>.from(residualPairings);
    }

    final Map<String, PairingInfo> pairingsByTopic = <String, PairingInfo>{
      if (includeLivePairings) ...<String, PairingInfo>{
        for (final PairingInfo pairing in pairings.value)
          if (allowedLiveTopics == null ||
              allowedLiveTopics.contains(pairing.topic))
            pairing.topic: pairing,
        if (_isInitialized || storesReady)
          for (final PairingInfo pairing in _wcClient!.pairings.getAll())
            if (allowedLiveTopics == null ||
                allowedLiveTopics.contains(pairing.topic))
              pairing.topic: pairing,
      },
    };
    final Set<String> unfinishedPairings = <String>{};

    for (final PairingInfo pairing in pairingsByTopic.values) {
      try {
        await _wcClient!.core.pairing.disconnect(topic: pairing.topic);
      } on Object catch (e, s) {
        _logger.warning(
          'Failed to disconnect pairing ${pairing.topic} remotely; '
          'purging local pairing state and key material',
          e,
          s,
        );
        // Reown's pairing.disconnect deletes the in-memory pairing record
        // before calling persist(), so ensure the follow-up local purge flushes
        // pairings.persist() even if pairings.delete() sees it already absent.
        _topicsNeedingPairingStorePersist.add(pairing.topic);
      }

      // Reown's pairing.disconnect removes the pairing record and broadcasts
      // onPairingDelete, but does not delete the topic's symmetric key or
      // expirer entry. Always complete local key/expirer cleanup before
      // treating the pairing as finished.
      final bool purged = await _purgePairingLocally(topic: pairing.topic);
      if (purged) {
        _topicsNeedingPairingStorePersist.remove(pairing.topic);
      } else {
        unfinishedPairings.add(pairing.topic);
      }
    }

    for (final String topic in residualPairings) {
      if (pairingsByTopic.containsKey(topic)) {
        continue;
      }
      final bool purged = await _purgePairingLocally(topic: topic);
      if (!purged) {
        unfinishedPairings.add(topic);
      }
    }

    _approvedProposalIds.clear();
    _reloadStores();
    return unfinishedPairings;
  }

  Future<T> _synchronizedMarkerOp<T>(Future<T> Function() action) {
    final Completer<T> completer = Completer<T>();
    _markerOpQueue = _markerOpQueue.then((_) async {
      try {
        completer.complete(await action());
      } on Object catch (e, s) {
        completer.completeError(e, s);
      }
    });
    return completer.future;
  }

  @override
  Future<void> disconnectEverything() async {
    if (_wcClient == null) {
      return;
    }

    if (!_isInitialized) {
      // Persist a durable reset marker and defer full store wipe until init()
      // completes so offline wallet resets never block, never invoke
      // uninitialized ReownWalletKit methods, and survive an immediate exit.
      _pendingDisconnectEverything = true;
      _hasUnresolvedReset = true;
      _hasUnresolvedFullReset = true;
      _resetRequestEpoch++;
      _resetGeneration++;
      final Future<void> persistFuture = _synchronizedMarkerOp<void>(() async {
        await _wcClient!.core.storage.init();
        final _PendingResetState existingMarker = _readPendingResetMarker();
        final Map<String, String> mergedSessions = <String, String>{
          ...existingMarker.pendingSessions,
          ..._pendingSessionCleanups,
        };
        final Set<String> mergedPairings = <String>{
          ...existingMarker.pendingPairings,
          ..._pendingPairingCleanups,
        };
        await _persistPendingResetMarkerLocked(
          fullReset: true,
          pendingSessions: mergedSessions,
          pendingPairings: mergedPairings,
        );
      });
      _pendingResetMarkerPersist = persistFuture;
      try {
        await persistFuture;
      } finally {
        if (identical(_pendingResetMarkerPersist, persistFuture)) {
          _pendingResetMarkerPersist = null;
        }
      }
      _approvedProposalIds.clear();
      _pendingUnsentResponses.clear();
      if (!_isDisposed) {
        sessions.value = <SessionData>[];
        pairings.value = <PairingInfo>[];
      }
      return;
    }

    await _runInitializedReset(
      forceFullReset: true,
      rethrowMarkerWriteError: true,
    );
  }

  Future<void> _runInitializedReset({
    required bool forceFullReset,
    required bool rethrowMarkerWriteError,
    bool storesReady = false,
  }) async {
    while (_resetInFlight != null) {
      try {
        await _resetInFlight;
      } on Object {
        // Prior reset attempt failed; continue with this call's own run.
      }
    }
    if (_isDisposed || _wcClient == null) {
      return;
    }

    final Completer<void> resetCompleter = Completer<void>();
    _resetInFlight = resetCompleter.future;
    _activeResetDepth++;
    try {
      await _performInitializedReset(
        forceFullReset: forceFullReset,
        rethrowMarkerWriteError: rethrowMarkerWriteError,
        storesReady: storesReady,
      );
    } finally {
      if (_activeResetDepth > 0) {
        _activeResetDepth--;
      }
      if (identical(_resetInFlight, resetCompleter.future)) {
        _resetInFlight = null;
      }
      resetCompleter.complete();
    }
  }

  Future<void> _performInitializedReset({
    required bool forceFullReset,
    required bool rethrowMarkerWriteError,
    required bool storesReady,
  }) async {
    final Future<void>? inFlightPersist = _pendingResetMarkerPersist;
    if (inFlightPersist != null) {
      try {
        await inFlightPersist;
      } on Object {
        // Proceed with live reset even if an earlier pre-init persist failed.
      } finally {
        if (identical(_pendingResetMarkerPersist, inFlightPersist)) {
          _pendingResetMarkerPersist = null;
        }
      }
    }

    final int capturedEpoch = _resetRequestEpoch;
    _pendingDisconnectEverything = false;

    final Set<String> attemptedSessionTopics = <String>{};
    final Set<String> attemptedPairingTopics = <String>{};
    Map<String, String> unfinishedSessions = <String, String>{};
    Set<String> unfinishedPairings = <String>{};
    bool runFullSweep = forceFullReset;
    bool hasSweptOnce = false;
    bool bumpedResetGeneration = false;
    bool persistedInitialFullResetMarker = false;

    while (!_isDisposed && _wcClient != null) {
      final ({
        bool aborted,
        bool runFullSweep,
        Map<String, String> targetSessions,
        Set<String> targetPairings,
      })
      snapshot = await _synchronizedMarkerOp(() async {
        final _PendingResetState markerState = _readPendingResetMarker();
        final bool passRunFullSweep = !hasSweptOnce
            ? (forceFullReset ||
                  _hasUnresolvedFullReset ||
                  markerState.fullReset)
            : runFullSweep;
        if (passRunFullSweep) {
          _hasUnresolvedFullReset = true;
          if (!bumpedResetGeneration) {
            bumpedResetGeneration = true;
            _resetGeneration++;
          }
        }
        final Map<String, String> residualSessions = !hasSweptOnce
            ? <String, String>{
                ...markerState.pendingSessions,
                ..._pendingSessionCleanups,
              }
            : Map<String, String>.from(unfinishedSessions);
        final Set<String> residualPairings = !hasSweptOnce
            ? <String>{
                ...markerState.pendingPairings,
                ..._pendingPairingCleanups,
              }
            : Set<String>.from(unfinishedPairings);

        // Snapshot all live session (topic + publicKey) and pairing targets so
        // they are persisted in the reset marker BEFORE the first destructive
        // operation. A crash after deleting a record but before deleting its
        // keys can then still finish key cleanup on restart.
        final Map<String, String> targetSessions = <String, String>{
          ...residualSessions,
          if (passRunFullSweep) ...<String, String>{
            for (final SessionData session in sessions.value)
              if (!hasSweptOnce ||
                  !attemptedSessionTopics.contains(session.topic))
                session.topic: session.self.publicKey,
            if (_isInitialized || storesReady)
              for (final SessionData session in _wcClient!.sessions.getAll())
                if (!hasSweptOnce ||
                    !attemptedSessionTopics.contains(session.topic))
                  session.topic: session.self.publicKey,
          },
        };
        final Set<String> targetPairings = <String>{
          ...residualPairings,
          if (passRunFullSweep) ...<String>{
            for (final PairingInfo pairing in pairings.value)
              if (!hasSweptOnce ||
                  !attemptedPairingTopics.contains(pairing.topic))
                pairing.topic,
            if (_isInitialized || storesReady)
              for (final PairingInfo pairing in _wcClient!.pairings.getAll())
                if (!hasSweptOnce ||
                    !attemptedPairingTopics.contains(pairing.topic))
                  pairing.topic,
          },
        };

        final bool markerMissingTargets =
            !_sameStringMap(markerState.pendingSessions, targetSessions) ||
            !_sameStringSet(markerState.pendingPairings, targetPairings);
        final bool mustPersistMarker =
            (!persistedInitialFullResetMarker && forceFullReset) ||
            _hasUnconfirmedResetMarkerWrite ||
            markerMissingTargets;
        if (mustPersistMarker) {
          _hasUnresolvedReset = true;
          try {
            await _persistPendingResetMarkerLocked(
              fullReset: passRunFullSweep,
              pendingSessions: targetSessions,
              pendingPairings: targetPairings,
            );
            if (passRunFullSweep) {
              persistedInitialFullResetMarker = true;
            }
          } on Object {
            if (rethrowMarkerWriteError) {
              rethrow;
            }
            // Abort before any destructive sweep so records are never deleted
            // without their target key identifiers durably saved first.
            return (
              aborted: true,
              runFullSweep: passRunFullSweep,
              targetSessions: targetSessions,
              targetPairings: targetPairings,
            );
          }
        }

        return (
          aborted: false,
          runFullSweep: passRunFullSweep,
          targetSessions: targetSessions,
          targetPairings: targetPairings,
        );
      });

      if (snapshot.aborted) {
        return;
      }

      runFullSweep = snapshot.runFullSweep;

      if (snapshot.runFullSweep && _inFlightPairCalls.isNotEmpty) {
        final List<Future<void>> pendingPairs = List<Future<void>>.from(
          _inFlightPairCalls,
        );
        final bool hasPreviouslyTimedOutPairs = pendingPairs.any(
          _timedOutInFlightPairCalls.contains,
        );
        if (hasPreviouslyTimedOutPairs) {
          // A prior reset attempt already timed out waiting for these SDK
          // pair() calls (typically hung on an unanswered relay subscribe
          // JSON-RPC request). Close the relay connection owning them so the
          // SDK call fails and settles before we sweep local state.
          _needsRelayReconnectAfterRecovery = true;
          try {
            await _wcClient!.core.relayClient.disconnect().timeout(
              _inFlightPairWaitTimeout,
            );
          } on Object catch (e, s) {
            _logger.warning(
              'Failed disconnecting relay while recovering from hung '
              'WalletConnect pair() call',
              e,
              s,
            );
          }
          if (_isDisposed || _wcClient == null) {
            return;
          }
        }

        // Wait (with a bounded deadline) for any SDK pair() calls that were
        // admitted before this reset began so they finish writing pairing
        // records, symmetric keys, relay subscriptions, and expirer entries
        // BEFORE the first purge runs. Because _isResetting is true, no new
        // pair() calls can enter _inFlightPairCalls while waiting.
        try {
          await Future.wait<void>(
            pendingPairs,
          ).timeout(_inFlightPairWaitTimeout);
        } on TimeoutException {
          if (_isDisposed) {
            return;
          }
          // Keep the full-reset marker on disk and unresolved so any late
          // writes from the still-in-flight SDK pair() call are swept on retry
          // or next launch, record the timed-out calls so retry can close the
          // relay connection to unblock them, and propagate the error to
          // runtime callers (such as the splash reset/cache-deletion flow).
          _timedOutInFlightPairCalls.addAll(_inFlightPairCalls);
          _hasUnresolvedReset = true;
          _hasUnresolvedFullReset = true;
          if (rethrowMarkerWriteError) {
            rethrow;
          }
          return;
        }
        if (_isDisposed || _wcClient == null) {
          return;
        }
        // Re-snapshot with all newly settled pairing targets committed to the
        // marker before running the first purge.
        continue;
      }

      hasSweptOnce = true;
      attemptedSessionTopics.addAll(snapshot.targetSessions.keys);
      attemptedPairingTopics.addAll(snapshot.targetPairings);

      unfinishedSessions = await _disconnectSessionsInternal(
        includeLiveSessions: snapshot.runFullSweep,
        residualSessions: snapshot.targetSessions,
        allowedLiveTopics: snapshot.targetSessions.keys.toSet(),
        storesReady: storesReady,
      );
      unfinishedPairings = await _disconnectPairingsInternal(
        includeLivePairings: snapshot.runFullSweep,
        residualPairings: snapshot.targetPairings,
        allowedLiveTopics: snapshot.targetPairings,
        storesReady: storesReady,
      );

      _pendingSessionCleanups
        ..clear()
        ..addAll(unfinishedSessions);
      _pendingPairingCleanups
        ..clear()
        ..addAll(unfinishedPairings);

      if (!snapshot.runFullSweep || _isDisposed || _wcClient == null) {
        break;
      }

      final bool hasNewLiveSessions = _collectLiveSessionTopics(
        storesReady: storesReady,
      ).any((String topic) => !attemptedSessionTopics.contains(topic));
      final bool hasNewLivePairings = _collectLivePairingTopics(
        storesReady: storesReady,
      ).any((String topic) => !attemptedPairingTopics.contains(topic));
      if (!hasNewLiveSessions && !hasNewLivePairings) {
        break;
      }
    }

    await _synchronizedMarkerOp<void>(() async {
      final bool newerResetRequested =
          _resetRequestEpoch != capturedEpoch || _pendingDisconnectEverything;

      if (unfinishedSessions.isNotEmpty || unfinishedPairings.isNotEmpty) {
        _hasUnresolvedReset = true;
        if (newerResetRequested) {
          _hasUnresolvedFullReset = true;
        }
        try {
          await _persistPendingResetMarkerLocked(
            fullReset: newerResetRequested,
            pendingSessions: unfinishedSessions,
            pendingPairings: unfinishedPairings,
          );
          if (!newerResetRequested) {
            _hasUnresolvedFullReset = false;
          }
        } on Object {
          if (rethrowMarkerWriteError) {
            rethrow;
          }
        }
        return;
      }

      // If a newer full-reset request arrived while this run was in flight,
      // preserve its marker on disk instead of deleting it in the gap before
      // the next loop iteration executes.
      if (newerResetRequested) {
        _hasUnresolvedReset = true;
        _hasUnresolvedFullReset = true;
        return;
      }

      final bool cleared = await _clearPendingResetMarkerLocked();
      _hasUnresolvedReset = !cleared;
      if (cleared) {
        _hasUnresolvedFullReset = false;
        if (_needsRelayReconnectAfterRecovery) {
          _needsRelayReconnectAfterRecovery = false;
          unawaited(_reconnectRelayAfterRecovery());
        }
      }
    });
  }

  Future<void> _reconnectRelayAfterRecovery() async {
    if (_isDisposed ||
        _wcClient == null ||
        _hasUnresolvedReset ||
        _pendingDisconnectEverything) {
      return;
    }
    try {
      await _wcClient!.core.relayClient.connect();
    } on Object catch (e, s) {
      _logger.fine(
        'Failed reconnecting relay after hung WalletConnect pair recovery',
        e,
        s,
      );
    }
  }

  Future<void> _persistPendingResetMarkerLocked({
    required bool fullReset,
    Map<String, String> pendingSessions = const <String, String>{},
    Set<String> pendingPairings = const <String>{},
  }) async {
    final List<Map<String, String>> serializedSessions =
        pendingSessions.entries
            .map(
              (MapEntry<String, String> entry) => <String, String>{
                'topic': entry.key,
                'publicKey': entry.value,
              },
            )
            .toList()
          ..sort(
            (Map<String, String> a, Map<String, String> b) =>
                a['topic']!.compareTo(b['topic']!),
          );
    final List<String> serializedPairings = pendingPairings.toList()..sort();

    final Map<String, dynamic> payload = <String, dynamic>{
      'pending': true,
      'fullReset': fullReset,
      if (serializedSessions.isNotEmpty) 'pendingSessions': serializedSessions,
      if (serializedPairings.isNotEmpty) 'pendingPairings': serializedPairings,
    };

    try {
      await _wcClient!.core.storage.init();
      await _wcClient!.core.storage.set(pendingResetStorageKey, payload);
      _hasUnconfirmedResetMarkerWrite = false;
    } on Object catch (e, s) {
      _hasUnconfirmedResetMarkerWrite = true;
      _logger.warning('Failed persisting WalletConnect reset marker', e, s);
      rethrow;
    }
  }

  Set<String> _collectLiveSessionTopics({required bool storesReady}) {
    if (_wcClient == null) {
      return const <String>{};
    }
    return <String>{
      for (final SessionData session in sessions.value) session.topic,
      if (_isInitialized || storesReady)
        for (final SessionData session in _wcClient!.sessions.getAll())
          session.topic,
    };
  }

  Set<String> _collectLivePairingTopics({required bool storesReady}) {
    if (_wcClient == null) {
      return const <String>{};
    }
    return <String>{
      for (final PairingInfo pairing in pairings.value) pairing.topic,
      if (_isInitialized || storesReady)
        for (final PairingInfo pairing in _wcClient!.pairings.getAll())
          pairing.topic,
    };
  }

  bool _hasPendingResetMarker() {
    try {
      return _wcClient != null &&
          _wcClient!.core.storage.has(pendingResetStorageKey);
    } on Object {
      return false;
    }
  }

  _PendingResetState _readPendingResetMarker() {
    if (_wcClient == null) {
      return const _PendingResetState.none();
    }
    try {
      if (!_wcClient!.core.storage.has(pendingResetStorageKey)) {
        return const _PendingResetState.none();
      }
      final Map<String, dynamic>? raw = _wcClient!.core.storage.get(
        pendingResetStorageKey,
      );
      if (raw == null) {
        return const _PendingResetState.full();
      }
      final bool fullReset = (raw['fullReset'] as bool?) ?? true;
      final Map<String, String> pendingSessions = <String, String>{};
      final Object? rawSessions = raw['pendingSessions'];
      if (rawSessions is List) {
        for (final Object? item in rawSessions) {
          if (item is Map) {
            final Object? topic = item['topic'];
            final Object? publicKey = item['publicKey'];
            if (topic is String && topic.isNotEmpty) {
              pendingSessions[topic] = publicKey is String ? publicKey : '';
            }
          }
        }
      }
      final Set<String> pendingPairings = <String>{};
      final Object? rawPairings = raw['pendingPairings'];
      if (rawPairings is List) {
        for (final Object? item in rawPairings) {
          if (item is String && item.isNotEmpty) {
            pendingPairings.add(item);
          }
        }
      }
      return _PendingResetState(
        fullReset: fullReset,
        pendingSessions: pendingSessions,
        pendingPairings: pendingPairings,
      );
    } on Object catch (e, s) {
      _logger.warning(
        'Failed reading WalletConnect reset marker; falling back to full reset',
        e,
        s,
      );
      return const _PendingResetState.full();
    }
  }

  Future<bool> _clearPendingResetMarkerLocked() async {
    try {
      if (_wcClient != null &&
          _wcClient!.core.storage.has(pendingResetStorageKey)) {
        await _wcClient!.core.storage.delete(pendingResetStorageKey);
      }
      _hasUnconfirmedResetMarkerWrite = false;
      return true;
    } on Object catch (e, s) {
      _logger.warning('Failed clearing WalletConnect reset marker', e, s);
      return false;
    }
  }

  bool _sameStringMap(Map<String, String> a, Map<String, String> b) {
    if (a.length != b.length) {
      return false;
    }
    for (final MapEntry<String, String> entry in a.entries) {
      if (b[entry.key] != entry.value) {
        return false;
      }
    }
    return true;
  }

  bool _sameStringSet(Set<String> a, Set<String> b) =>
      a.length == b.length && a.containsAll(b);

  @override
  Future<void> disconnectSession({required String topic}) async {
    if (_wcClient == null) {
      throw StateError('WalletConnect client not created');
    }

    await _wcClient!.disconnectSession(
      topic: topic,
      reason: Errors.getSdkError(Errors.USER_DISCONNECTED).toSignError(),
    );

    _reloadStores();
  }

  @override
  Map<String, SessionData> getActiveSessions() {
    if (_wcClient == null) {
      return <String, SessionData>{};
    }
    return _wcClient!.getActiveSessions();
  }

  @override
  Map<String, SessionRequest> getPendingSessionRequests() {
    if (_wcClient == null) {
      return const <String, SessionRequest>{};
    }
    return _safeGetPendingRequests();
  }

  void _subscribeListeners() {
    _wcClient!.core.relayClient.onRelayClientConnect.subscribe(
      _onRelayClientConnect,
    );
    _wcClient!.core.relayClient.onRelayClientDisconnect.subscribe(
      _onRelayClientDisconnect,
    );
    _wcClient!.core.relayClient.onRelayClientError.subscribe(
      _onRelayClientError,
    );

    _wcClient!.core.pairing.onPairingCreate.subscribe(_onPairingCreate);
    _wcClient!.core.pairing.onPairingActivate.subscribe(_onPairingActivate);
    _wcClient!.core.pairing.onPairingPing.subscribe(_onPairingPing);
    _wcClient!.core.pairing.onPairingInvalid.subscribe(_onPairingInvalid);
    _wcClient!.core.pairing.onPairingDelete.subscribe(_onPairingDelete);

    _wcClient!.pairings.onSync.subscribe(_onPairingsSync);
    _wcClient!.sessions.onSync.subscribe(_onSessionsSync);

    _wcClient!.onSessionProposal.subscribe(_onSessionProposal);
    _wcClient!.onSessionConnect.subscribe(_onSessionConnect);
    _wcClient!.onSessionRequest.subscribe(_onSessionRequest);
    _wcClient!.onSessionProposalError.subscribe(_onSessionProposalError);
    _wcClient!.onSessionDelete.subscribe(_onSessionDelete);
    _listenersSubscribed = true;
  }

  void _unsubscribeListeners() {
    _wcClient!.core.relayClient.onRelayClientConnect.unsubscribe(
      _onRelayClientConnect,
    );
    _wcClient!.core.relayClient.onRelayClientDisconnect.unsubscribe(
      _onRelayClientDisconnect,
    );
    _wcClient!.core.relayClient.onRelayClientError.unsubscribe(
      _onRelayClientError,
    );

    _wcClient!.core.pairing.onPairingCreate.unsubscribe(_onPairingCreate);
    _wcClient!.core.pairing.onPairingActivate.unsubscribe(_onPairingActivate);
    _wcClient!.core.pairing.onPairingPing.unsubscribe(_onPairingPing);
    _wcClient!.core.pairing.onPairingInvalid.unsubscribe(_onPairingInvalid);
    _wcClient!.core.pairing.onPairingDelete.unsubscribe(_onPairingDelete);

    _wcClient!.pairings.onSync.unsubscribe(_onPairingsSync);
    _wcClient!.sessions.onSync.unsubscribe(_onSessionsSync);

    _wcClient!.onSessionProposal.unsubscribe(_onSessionProposal);
    _wcClient!.onSessionConnect.unsubscribe(_onSessionConnect);
    _wcClient!.onSessionRequest.unsubscribe(_onSessionRequest);
    _wcClient!.onSessionProposalError.unsubscribe(_onSessionProposalError);
    _wcClient!.onSessionDelete.unsubscribe(_onSessionDelete);
    _listenersSubscribed = false;
  }

  @override
  void registerAccountsIfNeeded() {
    if (_wcClient == null) {
      _logger.warning(
        'registerAccountsIfNeeded called before WalletConnect client exists',
      );
      return;
    }

    if (!_isSupportedChainId(_namespaceChainId)) {
      _logger.warning(
        'Skipping account registration for unsupported chain '
        '$_namespaceChainId',
      );
      return;
    }

    if (kAddressLabelMap.isEmpty) {
      _logger.warning('No wallet addresses available to register');
      return;
    }

    for (final String address in kAddressLabelMap.keys) {
      final String accountKey = '$_namespaceChainId::$address';

      if (_registeredAccounts.contains(accountKey)) {
        continue;
      }

      _logger.info('Register account for $_namespaceChainId -> $address');
      _wcClient!.registerAccount(
        chainId: _namespaceChainId,
        accountAddress: address,
      );
      _registeredAccounts.add(accountKey);
    }
  }

  void _registerEventEmitters() {
    for (final String chainId in _supportedNoMChainIds) {
      for (final String event in _supportedNoMEvents) {
        _wcClient!.registerEventEmitter(chainId: chainId, event: event);
      }
    }
  }

  void _registerRequestHandlers() {
    // Register supported methods with no handler (default null) so upstream
    // reown_sign includes them in NamespaceUtils.generateNamespaces /
    // conformance checks while delivering incoming requests via
    // onSessionRequest (with event.id) instead of discarding return values.
    for (final String chainId in _supportedNoMChainIds) {
      for (final String method in _supportedNoMMethods) {
        _wcClient!.registerRequestHandler(chainId: chainId, method: method);
      }
    }
  }

  IChain _resolveChainService(String topic, {String? chainId}) {
    String resolvedChainId = chainId ?? _namespaceChainId;

    try {
      final SessionData session = _wcClient!
          .getActiveSessions()
          .values
          .firstWhere((SessionData element) => element.topic == topic);

      final List<String>? chains =
          session.namespaces[NoMService.namespace]?.chains;
      if (chains != null && chains.isNotEmpty) {
        resolvedChainId = chains.first;
      }
    } on Object {
      // Session may not be in active store yet; fallback to provided chainId.
    }

    if (!_isSupportedChainId(resolvedChainId)) {
      // ReownCoreError does not implement Error/Exception upstream.
      // ignore: only_throw_errors
      throw ReownCoreError(
        code: Errors.getSdkError(Errors.UNSUPPORTED_CHAINS).code,
        message: 'Unsupported Zenon chain: $resolvedChainId',
      );
    }

    final IChain Function(String chainId)? customResolver = _chainResolver;
    if (customResolver != null) {
      return customResolver(resolvedChainId);
    }

    if (!sl.isRegistered<IChain>(instanceName: resolvedChainId)) {
      // ReownCoreError does not implement Error/Exception upstream.
      // ignore: only_throw_errors
      throw ReownCoreError(
        code: Errors.getSdkError(Errors.UNSUPPORTED_CHAINS).code,
        message: 'No chain handler registered for $resolvedChainId',
      );
    }

    return sl<IChain>(instanceName: resolvedChainId);
  }

  Future<dynamic> _handleZnnInfoRequest(
    String topic,
    dynamic params, {
    String? chainId,
    int? requestId,
    VerifyContext? verifyContext,
  }) {
    final IChain chain = _resolveChainService(topic, chainId: chainId);
    if (chain is NoMService) {
      return chain.handleZnnInfo(
        topic,
        params,
        requestId: requestId,
        verifyContext: verifyContext,
      );
    }
    throw UnsupportedError(
      'znn_info not implemented for chain ${chain.getChainId()}',
    );
  }

  Future<dynamic> _handleZnnSignRequest(
    String topic,
    dynamic params, {
    String? chainId,
    int? requestId,
    VerifyContext? verifyContext,
  }) {
    final IChain chain = _resolveChainService(topic, chainId: chainId);
    if (chain is NoMService) {
      return chain.handleZnnSign(
        topic,
        params,
        requestId: requestId,
        verifyContext: verifyContext,
      );
    }
    throw UnsupportedError(
      'znn_sign not implemented for chain ${chain.getChainId()}',
    );
  }

  Future<dynamic> _handleZnnSendRequest(
    String topic,
    dynamic params, {
    String? chainId,
    int? requestId,
    VerifyContext? verifyContext,
  }) {
    final IChain chain = _resolveChainService(topic, chainId: chainId);
    if (chain is NoMService) {
      return chain.handleZnnSend(
        topic,
        params,
        requestId: requestId,
        verifyContext: verifyContext,
      );
    }
    throw UnsupportedError(
      'znn_send not implemented for chain ${chain.getChainId()}',
    );
  }

  Future<void> _onSessionRequest(SessionRequestEvent? event) async {
    if (event == null) return;

    // Wait for ongoing init so respondSessionRequest never hits NOT_INITIALIZED
    // if the relay delivers a queued session request mid-startup.
    final Future<void>? pendingInit = _initFuture;
    if (!_isInitialized && pendingInit != null) {
      try {
        await pendingInit;
      } on Object {
        return;
      }
    }

    if (_isDisposed || _isResetting || _hasUnresolvedReset) {
      return;
    }

    await _processSessionRequest(
      id: event.id,
      topic: event.topic,
      chainId: event.chainId,
      method: event.method,
      params: event.params,
      verifyContext:
          _safeGetPendingRequests()[event.id.toString()]?.verifyContext,
      sourceLabel: 'live event',
    );
  }

  Future<void> _drainPendingSessionRequests() async {
    if (_wcClient == null) return;

    final Map<String, SessionRequest> pendingRequests =
        _safeGetPendingRequests();
    if (pendingRequests.isEmpty) return;

    for (final SessionRequest request in pendingRequests.values) {
      if (_isDisposed || _isResetting || _hasUnresolvedReset) {
        return;
      }

      await _processSessionRequest(
        id: request.id,
        topic: request.topic,
        chainId: request.chainId,
        method: request.method,
        params: request.params,
        verifyContext: request.verifyContext,
        sourceLabel: 'startup pending backlog',
      );
    }
  }

  Future<void> _processSessionRequest({
    required int id,
    required String topic,
    required String? chainId,
    required String method,
    required dynamic params,
    required String sourceLabel,
    VerifyContext? verifyContext,
  }) async {
    if (_wcClient == null) return;

    if (!_markRequestInFlight(id)) {
      return;
    }

    if (!_hasActiveSessionTopic(topic)) {
      final JsonRpcResponse<dynamic>? unsent = _pendingUnsentResponses.remove(
        id,
      );
      final bool isSideEffecting = method == 'znn_send' || method == 'znn_sign';
      if (isSideEffecting && unsent != null && unsent.error == null) {
        final dynamic result = unsent.result;
        final String blockHashSuffix = result is AccountBlockTemplate
            ? ' blockHash=${result.hash}'
            : '';
        _logger.warning(
          'WalletConnect session closed before side-effecting response '
          'could be delivered ($sourceLabel): method=$method id=$id '
          'topic=$topic$blockHashSuffix',
        );
      } else {
        final String staleKey = '$method:$topic';
        if (_stalePendingTopics.add(staleKey)) {
          _logger.finer(
            'Skipping stale WalletConnect request without active session '
            '($sourceLabel): $method ($id) topic=$topic',
          );
        }
      }
      _markRequestCompleted(id);
      return;
    }

    // If the handler already ran and only response delivery failed (e.g.
    // relay disconnected offline), resend ONLY the cached response without
    // re-running the interactive handler or re-broadcasting side effects.
    final JsonRpcResponse<dynamic>? cachedResponse =
        _pendingUnsentResponses[id];
    if (cachedResponse != null) {
      await _deliverSessionResponse(
        topic: topic,
        requestId: id,
        method: method,
        response: cachedResponse,
        sourceLabel: '$sourceLabel retry',
      );
      return;
    }

    final VerifyContext? resolvedVerifyContext =
        verifyContext ??
        _safeGetPendingRequests()[id.toString()]?.verifyContext;

    late final JsonRpcResponse<dynamic> responseToDeliver;
    try {
      if (isWalletConnectVerifyScam(resolvedVerifyContext)) {
        _logger.warning(
          'Blocking WalletConnect session request flagged as scam '
          '($sourceLabel): $method ($id) topic=$topic '
          'origin=${resolvedVerifyContext?.origin}',
        );
        // ReownCoreError does not implement Error/Exception upstream.
        // ignore: only_throw_errors
        throw ReownCoreError(
          code: Errors.getSdkError(Errors.USER_REJECTED).code,
          message: 'WalletConnect request blocked: peer flagged as scam',
        );
      }

      _logger.fine(
        'Handling WalletConnect session request ($sourceLabel): $method ($id)',
      );

      final dynamic result = await _dispatchSessionRequest(
        topic: topic,
        chainId: chainId,
        requestId: id,
        method: method,
        params: params,
        verifyContext: resolvedVerifyContext,
      );

      responseToDeliver = JsonRpcResponse<dynamic>(id: id, result: result);
    } on Object catch (e, s) {
      if (_isStaleSessionError(e)) {
        _logger.finer(
          'Dropping stale WalletConnect request ($sourceLabel): $method ($id) '
          'topic=$topic error=$e',
        );
        _markRequestCompleted(id);
        return;
      }

      if (_isAlreadyRespondedError(e)) {
        _logger.fine(
          'WalletConnect request already responded ($sourceLabel): '
          '$method ($id)',
        );
        _markRequestCompleted(id);
        return;
      }

      _logger.severe(
        'Failed handling session request ($sourceLabel): $method',
        e,
        s,
      );
      responseToDeliver = JsonRpcResponse<dynamic>(
        id: id,
        error: walletConnectErrorToJsonRpcError(e),
      );
    }

    _cacheUnsentResponse(id, responseToDeliver);
    await _deliverSessionResponse(
      topic: topic,
      requestId: id,
      method: method,
      response: responseToDeliver,
      sourceLabel: sourceLabel,
    );
  }

  void _cacheUnsentResponse(int id, JsonRpcResponse<dynamic> response) {
    _pendingUnsentResponses[id] = response;
    if (_pendingUnsentResponses.length > _maxCompletedRequestIds) {
      _pendingUnsentResponses.remove(_pendingUnsentResponses.keys.first);
    }
  }

  Future<void> _deliverSessionResponse({
    required String topic,
    required int requestId,
    required String method,
    required JsonRpcResponse<dynamic> response,
    required String sourceLabel,
  }) async {
    final bool isSideEffectingSuccess =
        (method == 'znn_send' || method == 'znn_sign') &&
        response.error == null;

    try {
      await _wcClient!.respondSessionRequest(topic: topic, response: response);
      _pendingUnsentResponses.remove(requestId);
      _markRequestCompleted(requestId);
    } on Object catch (respondError, respondStack) {
      if (_isExpiredOrMissingPendingRequestError(respondError) ||
          _isStaleSessionError(respondError)) {
        if (isSideEffectingSuccess) {
          final dynamic result = response.result;
          final String blockHashSuffix = result is AccountBlockTemplate
              ? ' blockHash=${result.hash}'
              : '';
          _logger.warning(
            'WalletConnect side-effecting request could not deliver success '
            'response ($sourceLabel): method=$method id=$requestId '
            'topic=$topic$blockHashSuffix',
            respondError,
            respondStack,
          );
        } else if (_isStaleSessionError(respondError)) {
          _logger.finer(
            'WalletConnect stale response skipped ($sourceLabel): '
            '$method ($requestId) topic=$topic error=$respondError',
          );
        } else {
          _logger.fine(
            'WalletConnect request already responded or expired '
            '($sourceLabel): $method ($requestId)',
          );
        }
        _pendingUnsentResponses.remove(requestId);
        _markRequestCompleted(requestId);
      } else if (_isAlreadyRespondedError(respondError)) {
        _logger.fine(
          'WalletConnect response skipped (already responded): '
          '$method ($requestId)',
        );
        _pendingUnsentResponses.remove(requestId);
        _markRequestCompleted(requestId);
      } else {
        // Keep the computed response cached so _onRelayClientConnect retries
        // ONLY delivery without re-executing the handler.
        _markRequestFailed(requestId);
        _logger.warning(
          'Failed delivering WalletConnect response for $method ($requestId); '
          'will retry cached response on relay reconnect',
          respondError,
          respondStack,
        );
      }
    }
  }

  Future<dynamic> _dispatchSessionRequest({
    required String topic,
    required String method,
    required dynamic params,
    String? chainId,
    int? requestId,
    VerifyContext? verifyContext,
  }) {
    switch (method) {
      case 'znn_info':
        return _handleZnnInfoRequest(
          topic,
          params,
          chainId: chainId,
          requestId: requestId,
          verifyContext: verifyContext,
        );
      case 'znn_sign':
        return _handleZnnSignRequest(
          topic,
          params,
          chainId: chainId,
          requestId: requestId,
          verifyContext: verifyContext,
        );
      case 'znn_send':
        return _handleZnnSendRequest(
          topic,
          params,
          chainId: chainId,
          requestId: requestId,
          verifyContext: verifyContext,
        );
      default:
        throw UnsupportedError('Unsupported WalletConnect method: $method');
    }
  }

  Map<String, SessionRequest> _safeGetPendingRequests() {
    try {
      return _wcClient!.getPendingSessionRequests();
    } on Object {
      return const <String, SessionRequest>{};
    }
  }

  bool _markRequestInFlight(int id) {
    if (_completedRequestIds.contains(id) || _inFlightRequestIds.contains(id)) {
      return false;
    }
    _inFlightRequestIds.add(id);
    return true;
  }

  bool _hasActiveSessionTopic(String topic) {
    try {
      return _wcClient!.getActiveSessions().containsKey(topic);
    } on Object {
      return false;
    }
  }

  bool _isStaleSessionError(Object error) {
    final String message = error.toString().toLowerCase();
    return message.contains('session not found') ||
        message.contains("session topic doesn't exist") ||
        message.contains('session topic does not exist') ||
        message.contains('no matching key. session topic');
  }

  void _markRequestCompleted(int id) {
    _inFlightRequestIds.remove(id);
    _completedRequestIds.add(id);
    if (_completedRequestIds.length > _maxCompletedRequestIds) {
      _completedRequestIds.remove(_completedRequestIds.first);
    }
  }

  void _markRequestFailed(int id) {
    _inFlightRequestIds.remove(id);
  }

  bool _isExpiredOrMissingPendingRequestError(Object error) {
    final String message = error.toString().toLowerCase();
    return message.contains("proposal id doesn't exist") ||
        message.contains('expired');
  }

  bool _isAlreadyRespondedError(Object error) {
    final String message = error.toString().toLowerCase();
    return message.contains('already responded') ||
        message.contains('response already') ||
        message.contains('request already') ||
        message.contains('duplicate response') ||
        message.contains('request not found') ||
        // Thrown by reown_sign's _isValidPendingRequest once the pending
        // request has been deleted after a direct handler response.
        _isExpiredOrMissingPendingRequestError(error);
  }

  void _reloadStores() {
    if (_wcClient == null || _isDisposed) return;

    final List<PairingInfo> updatedPairings = List<PairingInfo>.from(
      _wcClient!.pairings.getAll(),
    );
    final List<SessionData> updatedSessions = List<SessionData>.from(
      _wcClient!.sessions.getAll(),
    );

    pairings.value = updatedPairings;
    sessions.value = updatedSessions;

    _logger.info(
      'Reloaded WalletConnect stores: '
      '${updatedPairings.length} pairings, ${updatedSessions.length} sessions',
    );
  }

  bool _isProposalBlockedByReset({String? pairingTopic}) {
    if (_pendingDisconnectEverything || _hasUnresolvedFullReset) {
      return true;
    }
    if (_isResetting || _hasUnresolvedReset || _hasPendingResetMarker()) {
      final _PendingResetState markerState = _readPendingResetMarker();
      if (markerState.fullReset) {
        return true;
      }
      if (pairingTopic == null || pairingTopic.isEmpty) {
        return true;
      }
      return markerState.pendingPairings.contains(pairingTopic) ||
          _pendingPairingCleanups.contains(pairingTopic);
    }
    return false;
  }

  Future<void> _rejectProposalForReset(int id) async {
    if (_wcClient == null || _isDisposed) {
      return;
    }
    try {
      await _wcClient!.rejectSession(
        id: id,
        reason: Errors.getSdkError(
          Errors.USER_REJECTED,
          context: 'WalletConnect reset in progress',
        ).toSignError(),
      );
    } on Object catch (e, s) {
      _logger.fine(
        'Failed rejecting proposal $id during WalletConnect reset',
        e,
        s,
      );
    }
  }

  SessionData? _findStoredSession(String topic) {
    if (_wcClient == null) {
      return null;
    }
    for (final SessionData session in _wcClient!.sessions.getAll()) {
      if (session.topic == topic) {
        return session;
      }
    }
    return null;
  }

  Future<void> _onSessionProposal(SessionProposalEvent? event) async {
    if (event == null || _wcClient == null || _isDisposed) {
      return;
    }

    if (_approvedProposalIds.contains(event.id) ||
        !_proposalIdsInFlight.add(event.id)) {
      _logger.fine('Ignoring duplicate WalletConnect proposal ${event.id}');
      return;
    }
    final String pairingTopic = event.params.pairingTopic;

    try {
      if (_isProposalBlockedByReset(pairingTopic: pairingTopic)) {
        await _rejectProposalForReset(event.id);
        return;
      }
      if (pairingTopic.isNotEmpty) {
        _proposalPairingTopicsInFlight[event.id] = pairingTopic;
      }
      final PairingMetadata dAppMetadata = event.params.proposer.metadata;
      final String dAppName = _dAppName(dAppMetadata);
      final String dAppDescription = _dAppDescription(dAppMetadata);
      final String? dAppUrl = _dAppUrl(dAppMetadata);
      final String? dAppIconUrl = _dAppIconUrl(dAppMetadata);
      final String? unsupportedProposalReason =
          unsupportedRequiredNamespaceReason(event.params.requiredNamespaces);

      if (unsupportedProposalReason != null) {
        try {
          _approvedProposalIds.add(event.id);
          await _wcClient!.rejectSession(
            id: event.id,
            reason: Errors.getSdkError(
              Errors.UNSUPPORTED_NAMESPACE_KEY,
              context: unsupportedProposalReason,
            ).toSignError(),
          );
          await NotificationUtils.sendNotificationError(
            unsupportedProposalReason,
            'WalletConnect session proposal rejected',
          );
        } on Object catch (e, s) {
          _logger.severe(
            'Failed rejecting unsupported WalletConnect proposal',
            e,
            s,
          );
        } finally {
          _reloadStores();
        }
        return;
      }

      if (isWalletConnectVerifyScam(event.verifyContext)) {
        try {
          _approvedProposalIds.add(event.id);
          _logger.warning(
            'Blocking WalletConnect session proposal flagged as scam: '
            'id=${event.id} origin=${event.verifyContext?.origin}',
          );
          await _wcClient!.rejectSession(
            id: event.id,
            reason: Errors.getSdkError(
              Errors.USER_REJECTED,
              context: 'Flagged as scam by WalletConnect Verify API',
            ).toSignError(),
          );
          await NotificationUtils.sendNotificationError(
            'This peer was flagged as a known scam by WalletConnect Verify.',
            'WalletConnect session proposal blocked',
          );
        } on Object catch (e, s) {
          _logger.severe('Failed rejecting scam WalletConnect proposal', e, s);
        } finally {
          _reloadStores();
        }
        return;
      }

      if (!await windowManager.isFocused() ||
          !await windowManager.isVisible()) {
        await windowManager.show();
      }
      if (_wcClient == null || _isDisposed) {
        return;
      }
      if (_isProposalBlockedByReset(pairingTopic: pairingTopic)) {
        await _rejectProposalForReset(event.id);
        return;
      }

      final BuildContext? context = globalNavigatorKey.currentContext;
      if (context == null || !context.mounted) {
        _logger.warning('No navigator context available for session proposal');
        return;
      }

      final Map<String, Namespace> approvedNamespaces = buildApprovedNamespaces(
        event.params,
      );
      final String approvedChains = _approvedChainsLabel(approvedNamespaces);
      final String approvedMethods = _approvedMethodsLabel(approvedNamespaces);
      final String approvedEvents = _approvedEventsLabel(approvedNamespaces);
      final WalletConnectVerifySummary verifySummary =
          describeWalletConnectVerifyContext(event.verifyContext);

      final bool? accepted = await showDialogWithNoAndYesOptions(
        context: context,
        isBarrierDismissible: false,
        title: 'Approve session',
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text('Are you sure you want to connect to $dAppName?'),
              kVerticalSpacing,
              _buildVerifyStatusBanner(verifySummary),
              kVerticalSpacing,
              Text('Chains: $approvedChains'),
              kVerticalSpacing,
              Text('Methods: $approvedMethods'),
              kVerticalSpacing,
              Text('Events: $approvedEvents'),
              kVerticalSpacing,
              if (dAppIconUrl != null)
                Image(
                  image: NetworkImage(dAppIconUrl),
                  height: 100,
                  fit: BoxFit.fitHeight,
                ),
              kVerticalSpacing,
              Text(dAppDescription),
              kVerticalSpacing,
              if (dAppUrl != null)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Flexible(
                      child: Text(dAppUrl, overflow: TextOverflow.ellipsis),
                    ),
                    LinkIcon(url: dAppUrl),
                  ],
                ),
            ],
          ),
        ),
      );

      if (_wcClient == null || _isDisposed) {
        return;
      }
      if (_isProposalBlockedByReset(pairingTopic: pairingTopic)) {
        await _rejectProposalForReset(event.id);
        return;
      }

      if (accepted ?? false) {
        try {
          final ApproveResponse approveResponse = await approveSession(
            id: event.id,
            namespaces: approvedNamespaces,
            pairingTopic: pairingTopic,
          );

          await finalizeApprovedSession(
            proposalId: event.id,
            approveResponse: approveResponse,
            dAppMetadata: dAppMetadata,
            pairingTopic: pairingTopic,
          );
        } on Object catch (e, s) {
          _logger.severe('Failed approving WalletConnect session', e, s);
          await NotificationUtils.sendNotificationError(
            e,
            'WalletConnect session approval failed',
          );
        }
        return;
      }

      _approvedProposalIds.add(event.id);
      try {
        await _wcClient!.rejectSession(
          id: event.id,
          reason: Errors.getSdkError(Errors.USER_REJECTED).toSignError(),
        );
      } on Object catch (e, s) {
        _logger.warning('Failed rejecting WalletConnect session', e, s);
      } finally {
        _reloadStores();
      }
    } finally {
      _proposalIdsInFlight.remove(event.id);
      _proposalPairingTopicsInFlight.remove(event.id);
    }
  }

  /// Validates [requiredNamespaces] against the currently active Zenon chain
  /// and supported methods/events, returning a human-readable rejection reason
  /// or `null` when conforming.
  @visibleForTesting
  String? unsupportedRequiredNamespaceReason(
    Map<String, RequiredNamespace> requiredNamespaces,
  ) {
    if (!_isSupportedChainId(_namespaceChainId)) {
      return 'Unsupported active chain $_namespaceChainId';
    }

    for (final MapEntry<String, RequiredNamespace> entry
        in requiredNamespaces.entries) {
      final String namespaceKey = entry.key.split(':').first;
      if (namespaceKey != NoMService.namespace) {
        return 'Unsupported namespace ${entry.key}';
      }

      final Set<String> requestedChains = _requestedChains(
        entry.key,
        entry.value,
      );
      final List<String> unsupportedChains = requestedChains
          .where(
            (String chainId) =>
                chainId != _namespaceChainId || !_isSupportedChainId(chainId),
          )
          .toList();
      if (unsupportedChains.isNotEmpty) {
        return 'Unsupported chain(s): ${unsupportedChains.join(', ')}';
      }

      final List<String> unsupportedMethods = entry.value.methods
          .where((String method) => !_supportedNoMMethods.contains(method))
          .toList();
      if (unsupportedMethods.isNotEmpty) {
        return 'Unsupported method(s): ${unsupportedMethods.join(', ')}';
      }

      final List<String> unsupportedEvents = entry.value.events
          .where((String event) => !_supportedNoMEvents.contains(event))
          .toList();
      if (unsupportedEvents.isNotEmpty) {
        return 'Unsupported event(s): ${unsupportedEvents.join(', ')}';
      }
    }

    return null;
  }

  Set<String> _requestedChains(
    String namespaceKey,
    RequiredNamespace namespace,
  ) {
    return <String>{
      if (namespaceKey.contains(':')) namespaceKey,
      ...?namespace.chains,
    };
  }

  /// Builds the effective approved [Namespace] map for [proposal] containing
  /// the active Zenon chain, wallet accounts, all required methods/events, and
  /// only the optional methods/events supported by this wallet.
  @visibleForTesting
  Map<String, Namespace> buildApprovedNamespaces(ProposalData proposal) {
    final Set<String> approvedMethods = <String>{};
    final Set<String> approvedEvents = <String>{};
    final bool hasAnyRequestedNamespace =
        proposal.requiredNamespaces.isNotEmpty ||
        proposal.optionalNamespaces.isNotEmpty;

    void collectFrom(Map<String, RequiredNamespace> namespaces) {
      for (final MapEntry<String, RequiredNamespace> entry
          in namespaces.entries) {
        final String namespaceKey = entry.key.split(':').first;
        if (namespaceKey != NoMService.namespace) {
          continue;
        }
        final Set<String> entryChains = _requestedChains(
          entry.key,
          entry.value,
        );
        if (entryChains.isNotEmpty &&
            !entryChains.contains(_namespaceChainId)) {
          continue;
        }
        for (final String method in entry.value.methods) {
          if (_supportedNoMMethods.contains(method)) {
            approvedMethods.add(method);
          }
        }
        for (final String event in entry.value.events) {
          if (_supportedNoMEvents.contains(event)) {
            approvedEvents.add(event);
          }
        }
      }
    }

    collectFrom(proposal.requiredNamespaces);
    collectFrom(proposal.optionalNamespaces);

    final List<String> methods = hasAnyRequestedNamespace
        ? approvedMethods.toList()
        : List<String>.from(_supportedNoMMethods);
    final List<String> events = hasAnyRequestedNamespace
        ? approvedEvents.toList()
        : List<String>.from(_supportedNoMEvents);

    return <String, Namespace>{
      NoMService.namespace: Namespace(
        chains: <String>[_namespaceChainId],
        accounts: _walletAccounts(),
        methods: methods,
        events: events,
      ),
    };
  }

  String _approvedChainsLabel(Map<String, Namespace> namespaces) {
    final List<String> chains =
        namespaces[NoMService.namespace]?.chains ?? const <String>[];
    return chains.isEmpty ? 'None' : chains.join(', ');
  }

  String _approvedMethodsLabel(Map<String, Namespace> namespaces) {
    final List<String> methods =
        namespaces[NoMService.namespace]?.methods ?? const <String>[];
    return methods.isEmpty ? 'None' : methods.join(', ');
  }

  String _approvedEventsLabel(Map<String, Namespace> namespaces) {
    final List<String> events =
        namespaces[NoMService.namespace]?.events ?? const <String>[];
    return events.isEmpty ? 'None' : events.join(', ');
  }

  void _onSessionConnect(SessionConnect? args) {
    if (args != null) {
      _upsertSession(args.session);
    }

    _reloadStores();
  }

  Future<void> _sendSuccessfullyApprovedSessionNotification(
    PairingMetadata dAppMetadata,
  ) {
    final String dAppName = _dAppName(dAppMetadata);

    return sl.get<NotificationsBloc>().addNotification(
      WalletNotification(
        title: 'Successfully connected to $dAppName',
        timestamp: DateTime.now().millisecondsSinceEpoch,
        details: 'Successfully connected to $dAppName via WalletConnect',
        type: NotificationType.paymentSent,
      ),
    );
  }

  /// Finalizes an approved WalletConnect session using the current SDK store
  /// record so a session removed by a concurrent reset is neither re-inserted
  /// into [sessions] nor reported as connected.
  @visibleForTesting
  Future<bool> finalizeApprovedSession({
    required int proposalId,
    required ApproveResponse approveResponse,
    required PairingMetadata dAppMetadata,
    String? pairingTopic,
  }) async {
    if (_wcClient == null ||
        _isDisposed ||
        _isProposalBlockedByReset(pairingTopic: pairingTopic)) {
      return false;
    }

    final SessionData? approvedSession = approveResponse.session;
    if (approvedSession == null) {
      throw StateError('WalletConnect approveSession returned null');
    }

    final SessionData? liveSession = _findStoredSession(approvedSession.topic);
    if (liveSession == null) {
      _reloadStores();
      return false;
    }

    // Mark the proposal as approved only after approveSession succeeds and
    // the session is still present in the SDK store.
    _approvedProposalIds.add(proposalId);
    _upsertSession(liveSession);
    await _sendSuccessfullyApprovedSessionNotification(dAppMetadata);

    _reloadStores();
    return true;
  }

  /// Approves a pending WalletConnect session proposal unless a wallet reset
  /// affecting [pairingTopic] (or any full reset) is in progress or pending.
  @visibleForTesting
  Future<ApproveResponse> approveSession({
    required int id,
    required Map<String, Namespace> namespaces,
    String? pairingTopic,
  }) async {
    if (_isDisposed ||
        _wcClient == null ||
        _isProposalBlockedByReset(pairingTopic: pairingTopic)) {
      throw StateError(
        'WalletConnect reset cleanup is in progress or pending; '
        'cannot approve session proposal',
      );
    }

    if (!await windowManager.isFocused() || !await windowManager.isVisible()) {
      await windowManager.show();
    }

    if (_isDisposed ||
        _wcClient == null ||
        _isProposalBlockedByReset(pairingTopic: pairingTopic)) {
      throw StateError(
        'WalletConnect reset cleanup is in progress or pending; '
        'cannot approve session proposal',
      );
    }

    _logger.info('Approving session with negotiated namespaces: $namespaces');

    return await _wcClient!.approveSession(id: id, namespaces: namespaces);
  }

  List<String> _walletAccounts() {
    final int chainId = getChainIdentifier();
    return kAddressLabelMap.keys
        .map((String address) => '$kZenonNameSpace:$chainId:$address')
        .toList();
  }

  Widget _buildVerifyStatusBanner(WalletConnectVerifySummary summary) {
    final Color accentColor = switch (summary.severity) {
      WalletConnectVerifySeverity.verified => Colors.green,
      WalletConnectVerifySeverity.unverified => Colors.orange,
      WalletConnectVerifySeverity.invalid ||
      WalletConnectVerifySeverity.scam => Colors.red,
    };
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: accentColor.withValues(alpha: 0.12),
        border: Border.all(color: accentColor),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            summary.title,
            style: TextStyle(fontWeight: FontWeight.bold, color: accentColor),
          ),
          const SizedBox(height: 4),
          Text(summary.detail),
        ],
      ),
    );
  }

  String _dAppName(PairingMetadata metadata) {
    return walletConnectDisplayValue(metadata.name, 'Unknown dApp');
  }

  String _dAppDescription(PairingMetadata metadata) {
    return walletConnectDisplayValue(
      metadata.description,
      'No description provided',
    );
  }

  String? _dAppUrl(PairingMetadata metadata) {
    return sanitizeWalletConnectHttpUrl(metadata.url);
  }

  String? _dAppIconUrl(PairingMetadata metadata) {
    for (final String icon in metadata.icons) {
      final String? sanitized = sanitizeWalletConnectHttpUrl(icon);
      if (sanitized != null) {
        return sanitized;
      }
    }
    return null;
  }

  void _upsertSession(SessionData session) {
    if (_isDisposed) {
      return;
    }

    final List<SessionData> updated = List<SessionData>.from(sessions.value);
    final int index = updated.indexWhere(
      (SessionData item) => item.topic == session.topic,
    );

    if (index == -1) {
      updated.add(session);
    } else {
      updated[index] = session;
    }

    sessions.value = updated;
  }

  Future<void> _emitEventPairedDApps({
    required String changeName,
    required String newValue,
  }) async {
    if (_wcClient == null || !_isInitialized) {
      return;
    }

    final List<SessionData> activeSessions = List<SessionData>.from(
      getActiveSessions().values,
    );

    for (final SessionData session in activeSessions) {
      final Namespace? nomNamespace = session.namespaces[NoMService.namespace];
      if (nomNamespace != null && !nomNamespace.events.contains(changeName)) {
        continue;
      }
      final List<String>? chains = nomNamespace?.chains;
      final String sessionChainId = (chains != null && chains.isNotEmpty)
          ? chains.first
          : _namespaceChainId;

      try {
        await _emitDAppEvent(
          sessionTopic: session.topic,
          chainId: sessionChainId,
          changeName: changeName,
          newValue: newValue,
        );
      } on Object catch (e, s) {
        _logger.warning(
          'Failed emitting $changeName event to session ${session.topic}',
          e,
          s,
        );
      }
    }
  }

  Future<void> _emitDAppEvent({
    required String sessionTopic,
    required String chainId,
    required String changeName,
    required String newValue,
  }) {
    return _wcClient!.emitSessionEvent(
      topic: sessionTopic,
      chainId: chainId,
      event: SessionEventParams(name: changeName, data: newValue),
    );
  }

  void _onSessionsSync(StoreSyncEvent? args) {
    if (args == null) return;
    _reloadStores();
  }

  void _onPairingsSync(StoreSyncEvent? args) {
    if (args == null) return;
    _reloadStores();
  }

  void _onSessionDelete(SessionDelete? args) {
    _reloadStores();
  }

  void _onSessionProposalError(SessionProposalErrorEvent? args) {
    _logger.severe('Session proposal error: $args');

    if (args != null) {
      _proposalIdsInFlight.remove(args.id);
      _proposalPairingTopicsInFlight.remove(args.id);
    }
    _reloadStores();
  }

  void _onPairingCreate(PairingEvent? args) {
    _reloadStores();
  }

  void _onPairingActivate(PairingActivateEvent? args) {
    _reloadStores();
  }

  void _onPairingPing(PairingEvent? args) {
    _reloadStores();
  }

  void _onPairingInvalid(PairingInvalidEvent? args) {
    _reloadStores();
  }

  void _onPairingDelete(PairingEvent? args) {
    _reloadStores();
  }

  void _onRelayClientConnect(dynamic args) {
    _reloadStores();
    if (_isInitialized &&
        !_isDisposed &&
        !_isResetting &&
        !_hasUnresolvedReset) {
      unawaited(_drainPendingSessionRequests());
    }
  }

  void _onRelayClientDisconnect(dynamic args) {
    _reloadStores();
  }

  void _onRelayClientError(dynamic args) {
    _logger.warning('Relay client error: $args');
  }
}

class _PendingResetState {
  const _PendingResetState({
    required this.fullReset,
    required this.pendingSessions,
    required this.pendingPairings,
  });

  const _PendingResetState.none()
    : fullReset = false,
      pendingSessions = const <String, String>{},
      pendingPairings = const <String>{};

  const _PendingResetState.full()
    : fullReset = true,
      pendingSessions = const <String, String>{},
      pendingPairings = const <String>{};

  final bool fullReset;
  final Map<String, String> pendingSessions;
  final Set<String> pendingPairings;
}
