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
  /// Optional [walletKit] and [_chainResolver] overrides exist solely for
  /// deterministic unit testing without a live relay or global service locator.
  Web3WalletService({
    @visibleForTesting ReownWalletKit? walletKit,
    @visibleForTesting this._chainResolver,
  }) : _wcClient = walletKit;

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

  ReownWalletKit? _wcClient;
  Future<void>? _initFuture;
  Future<void>? _pendingResetMarkerPersist;
  bool _isInitialized = false;
  bool _isDisposed = false;
  bool _listenersSubscribed = false;
  bool _pendingDisconnectEverything = false;

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

    _isInitialized = true;

    if (_pendingDisconnectEverything || _hasPendingResetMarker()) {
      _pendingDisconnectEverything = false;
      await disconnectEverything();
      return;
    }

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
    _pendingDisconnectEverything = false;
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

    if (kAddressLabelMap.isEmpty) {
      throw StateError('No wallet addresses available');
    }

    registerAccountsIfNeeded();
    await _cleanupStalePairings();

    final PairingInfo pairing = await _wcClient!.pair(uri: uri);
    _reloadStores();
    return pairing;
  }

  Future<void> _cleanupStalePairings() async {
    if (_wcClient == null) return;

    final List<PairingInfo> currentPairings = List<PairingInfo>.from(
      _wcClient!.pairings.getAll(),
    );

    for (final PairingInfo pairing in currentPairings) {
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

    final Map<String, SessionData> sessionsByTopic = <String, SessionData>{
      for (final SessionData session in sessions.value) session.topic: session,
      if (_isInitialized)
        for (final SessionData session in _wcClient!.sessions.getAll())
          session.topic: session,
    };

    for (final SessionData session in sessionsByTopic.values) {
      try {
        await _wcClient!.disconnectSession(
          topic: session.topic,
          reason: Errors.getSdkError(Errors.USER_DISCONNECTED).toSignError(),
        );
      } on Object catch (e, s) {
        _logger.warning(
          'Failed to disconnect session ${session.topic} remotely; '
          'purging local session state and key material',
          e,
          s,
        );
        await _purgeSessionLocally(session);
      }
    }

    _approvedProposalIds.clear();
    _pendingUnsentResponses.clear();
    _reloadStores();
  }

  Future<void> _purgeSessionLocally(SessionData session) async {
    if (_wcClient == null) return;
    try {
      await _wcClient!.sessions.delete(session.topic);
    } on Object catch (e, s) {
      _logger.warning('Failed deleting local session ${session.topic}', e, s);
    }
    try {
      await _wcClient!.core.crypto.deleteKeyPair(session.self.publicKey);
    } on Object catch (e, s) {
      _logger.warning(
        'Failed deleting session key pair for ${session.topic}',
        e,
        s,
      );
    }
    try {
      await _wcClient!.core.crypto.deleteSymKey(session.topic);
    } on Object catch (e, s) {
      _logger.warning(
        'Failed deleting session symKey for ${session.topic}',
        e,
        s,
      );
    }
    try {
      await _wcClient!.core.expirer.delete(session.topic);
    } on Object catch (e, s) {
      _logger.warning(
        'Failed deleting session expirer entry for ${session.topic}',
        e,
        s,
      );
    }
    try {
      await _wcClient!.core.relayClient.unsubscribe(topic: session.topic);
    } on Object {
      // Relay may be offline during local reset.
    }
  }

  Future<void> _purgePairingLocally(PairingInfo pairing) async {
    if (_wcClient == null) return;
    try {
      await _wcClient!.pairings.delete(pairing.topic);
    } on Object catch (e, s) {
      _logger.warning('Failed deleting local pairing ${pairing.topic}', e, s);
    }
    try {
      await _wcClient!.core.crypto.deleteSymKey(pairing.topic);
    } on Object catch (e, s) {
      _logger.warning(
        'Failed deleting pairing symKey for ${pairing.topic}',
        e,
        s,
      );
    }
    try {
      await _wcClient!.core.expirer.delete(pairing.topic);
    } on Object catch (e, s) {
      _logger.warning(
        'Failed deleting pairing expirer entry for ${pairing.topic}',
        e,
        s,
      );
    }
    try {
      await _wcClient!.core.relayClient.unsubscribe(topic: pairing.topic);
    } on Object {
      // Relay may be offline during local reset.
    }
  }

  @override
  Future<void> disconnectAllPairings() async {
    if (_wcClient == null) {
      return;
    }

    final Map<String, PairingInfo> pairingsByTopic = <String, PairingInfo>{
      for (final PairingInfo pairing in pairings.value) pairing.topic: pairing,
      if (_isInitialized)
        for (final PairingInfo pairing in _wcClient!.pairings.getAll())
          pairing.topic: pairing,
    };

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
        await _purgePairingLocally(pairing);
      }
    }

    _approvedProposalIds.clear();
    _reloadStores();
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
      final Future<void> persistFuture = _persistPendingResetMarker();
      _pendingResetMarkerPersist = persistFuture;
      await persistFuture;
      _approvedProposalIds.clear();
      _pendingUnsentResponses.clear();
      if (!_isDisposed) {
        sessions.value = <SessionData>[];
        pairings.value = <PairingInfo>[];
      }
      return;
    }

    _pendingDisconnectEverything = false;
    await disconnectSessions();
    await disconnectAllPairings();
    await _clearPendingResetMarker();
  }

  Future<void> _persistPendingResetMarker() async {
    try {
      await _wcClient!.core.storage.init();
      await _wcClient!.core.storage.set(
        pendingResetStorageKey,
        <String, dynamic>{'pending': true},
      );
    } on Object catch (e, s) {
      _logger.warning('Failed persisting WalletConnect reset marker', e, s);
    }
  }

  bool _hasPendingResetMarker() {
    try {
      return _wcClient!.core.storage.has(pendingResetStorageKey);
    } on Object {
      return false;
    }
  }

  Future<void> _clearPendingResetMarker() async {
    final Future<void>? inFlightPersist = _pendingResetMarkerPersist;
    if (inFlightPersist != null) {
      await inFlightPersist;
      if (identical(_pendingResetMarkerPersist, inFlightPersist)) {
        _pendingResetMarkerPersist = null;
      }
    }
    try {
      if (_wcClient != null &&
          _wcClient!.core.storage.has(pendingResetStorageKey)) {
        await _wcClient!.core.storage.delete(pendingResetStorageKey);
      }
    } on Object catch (e, s) {
      _logger.warning('Failed clearing WalletConnect reset marker', e, s);
    }
  }

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

  Future<void> _onSessionProposal(SessionProposalEvent? event) async {
    if (event == null || _wcClient == null) return;

    if (_approvedProposalIds.contains(event.id) ||
        !_proposalIdsInFlight.add(event.id)) {
      _logger.fine('Ignoring duplicate WalletConnect proposal ${event.id}');
      return;
    }
    if (event.params.pairingTopic.isNotEmpty) {
      _proposalPairingTopicsInFlight[event.id] = event.params.pairingTopic;
    }

    try {
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

      final BuildContext? context = globalNavigatorKey.currentContext;
      if (context == null || !context.mounted) {
        _logger.warning('No navigator context available for session proposal');
        return;
      }

      final String requestedChains = _requestedChainsLabel(event.params);
      final String requestedMethods = _requestedMethodsLabel(event.params);
      final String requestedEvents = _requestedEventsLabel(event.params);
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
              Text('Chains: $requestedChains'),
              kVerticalSpacing,
              Text('Methods: $requestedMethods'),
              kVerticalSpacing,
              Text('Events: $requestedEvents'),
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

      if (accepted ?? false) {
        try {
          final ApproveResponse approveResponse = await _approveSession(
            id: event.id,
          );

          if (approveResponse.session == null) {
            throw StateError('WalletConnect approveSession returned null');
          }

          // Mark the proposal as approved only after approveSession succeeds,
          // so a transient failure leaves the id free for a retried delivery.
          _approvedProposalIds.add(event.id);
          _upsertSession(approveResponse.session!);
          await _sendSuccessfullyApprovedSessionNotification(dAppMetadata);

          _reloadStores();
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

  String _requestedChainsLabel(ProposalData proposal) {
    final Set<String> chains = <String>{};
    for (final MapEntry<String, RequiredNamespace> entry
        in proposal.requiredNamespaces.entries) {
      chains.addAll(_requestedChains(entry.key, entry.value));
    }
    for (final MapEntry<String, RequiredNamespace> entry
        in proposal.optionalNamespaces.entries) {
      chains.addAll(_requestedChains(entry.key, entry.value));
    }
    if (chains.isEmpty) {
      return _namespaceChainId;
    }
    return chains.join(', ');
  }

  String _requestedMethodsLabel(ProposalData proposal) {
    final Set<String> methods = <String>{};
    for (final RequiredNamespace namespace
        in proposal.requiredNamespaces.values) {
      methods.addAll(namespace.methods);
    }
    for (final RequiredNamespace namespace
        in proposal.optionalNamespaces.values) {
      methods.addAll(namespace.methods);
    }
    if (methods.isEmpty) {
      return _supportedNoMMethods.join(', ');
    }
    return methods.join(', ');
  }

  String _requestedEventsLabel(ProposalData proposal) {
    final Set<String> events = <String>{};
    for (final RequiredNamespace namespace
        in proposal.requiredNamespaces.values) {
      events.addAll(namespace.events);
    }
    for (final RequiredNamespace namespace
        in proposal.optionalNamespaces.values) {
      events.addAll(namespace.events);
    }
    if (events.isEmpty) {
      return _supportedNoMEvents.join(', ');
    }
    return events.join(', ');
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

  Future<ApproveResponse> _approveSession({required int id}) async {
    if (!await windowManager.isFocused() || !await windowManager.isVisible()) {
      await windowManager.show();
    }

    final Map<String, Namespace> resolvedNamespaces = <String, Namespace>{
      NoMService.namespace: Namespace(
        chains: <String>[_namespaceChainId],
        accounts: _walletAccounts(),
        methods: _supportedNoMMethods,
        events: _supportedNoMEvents,
      ),
    };

    _logger.info(
      'Approving session with manual namespaces: $resolvedNamespaces',
    );

    return await _wcClient!.approveSession(
      id: id,
      namespaces: resolvedNamespaces,
    );
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
      final List<String>? chains =
          session.namespaces[NoMService.namespace]?.chains;
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
    if (_isInitialized && !_isDisposed) {
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
