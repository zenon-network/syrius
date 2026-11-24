import 'dart:async';

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:reown_walletkit/reown_walletkit.dart';
import 'package:window_manager/window_manager.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/notifications_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/wallet_connect/chains/i_chain.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/wallet_connect/chains/nom_service.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/wallet_connect/wallet_connect_pairings_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/wallet_connect/wallet_connect_sessions_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/model/database/notification_type.dart';
import 'package:zenon_syrius_wallet_flutter/model/database/wallet_notification.dart';
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

  final Logger _logger = Logger('WalletConnectService');
  final IChain Function(String chainId)? _chainResolver;

  ReownWalletKit? _wcClient;
  Future<void>? _initFuture;
  bool _isInitialized = false;
  bool _listenersSubscribed = false;

  final Set<int> _approvedProposalIds = <int>{};
  final Set<int> _proposalIdsInFlight = <int>{};
  final Set<int> _inFlightRequestIds = <int>{};
  final Set<int> _completedRequestIds = <int>{};
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

    registerAccountsIfNeeded();

    _isInitialized = true;
    _reloadStores();
    _refreshUi();
    unawaited(_drainPendingSessionRequests());
  }

  @override
  FutureOr<void> onDispose() {
    if (_wcClient != null && _listenersSubscribed) {
      _unsubscribeListeners();
    }

    _approvedProposalIds.clear();
    _proposalIdsInFlight.clear();
    _inFlightRequestIds.clear();
    _completedRequestIds.clear();
    _stalePendingTopics.clear();
    _registeredAccounts.clear();
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
    _refreshUi();
    return pairing;
  }

  Future<void> _cleanupStalePairings() async {
    if (_wcClient == null) return;

    final List<PairingInfo> currentPairings = List<PairingInfo>.from(
      _wcClient!.pairings.getAll(),
    );

    for (final PairingInfo pairing in currentPairings) {
      final Map<String, SessionData> sessionsForPairing = _wcClient!
          .getSessionsForPairing(pairingTopic: pairing.topic);

      if (sessionsForPairing.isEmpty) {
        try {
          _logger.info('Removing orphan pairing: ${pairing.topic}');
          await _wcClient!.core.pairing.disconnect(topic: pairing.topic);
        } on Object catch (e, s) {
          _logger.warning(
            'Failed to remove orphan pairing ${pairing.topic}',
            e,
            s,
          );
        }
      }
    }

    _reloadStores();
    _refreshUi();
  }

  @override
  Future<void> activatePairing({required String topic}) async {
    if (_wcClient == null) {
      return;
    }
    await _wcClient!.core.pairing.activate(topic: topic);
    _reloadStores();
    _refreshUi();
  }

  @override
  Future<void> deactivatePairing({required String topic}) async {
    if (_wcClient == null) {
      return;
    }
    try {
      await _wcClient!.core.pairing.disconnect(topic: topic);
      _approvedProposalIds.clear();
      _reloadStores();
      _refreshUi();
    } on ReownCoreError catch (e) {
      _logger.warning('Failed to deactivate pairing: ${e.code} ${e.message}');
    } on Object catch (e, s) {
      _logger.severe('Unexpected error while deactivating pairing', e, s);
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

    final List<SessionData> currentSessions = List<SessionData>.from(
      sessions.value,
    );

    for (final SessionData session in currentSessions) {
      try {
        await _wcClient!.disconnectSession(
          topic: session.topic,
          reason: Errors.getSdkError(Errors.USER_DISCONNECTED).toSignError(),
        );
      } on Object catch (e, s) {
        _logger.warning('Failed to disconnect session ${session.topic}', e, s);
      }
    }

    _approvedProposalIds.clear();
    _reloadStores();
    _refreshUi();
  }

  @override
  Future<void> disconnectAllPairings() async {
    if (_wcClient == null) {
      return;
    }

    final List<PairingInfo> currentPairings = List<PairingInfo>.from(
      pairings.value,
    );

    for (final PairingInfo pairing in currentPairings) {
      try {
        await _wcClient!.core.pairing.disconnect(topic: pairing.topic);
      } on Object catch (e, s) {
        _logger.warning('Failed to disconnect pairing ${pairing.topic}', e, s);
      }
    }

    _approvedProposalIds.clear();
    _reloadStores();
    _refreshUi();
  }

  @override
  Future<void> disconnectEverything() async {
    await disconnectSessions();
    await disconnectAllPairings();
  }

  @override
  Future<void> disconnectSession({required String topic}) async {
    if (_wcClient == null) {
      return;
    }

    await _wcClient!.disconnectSession(
      topic: topic,
      reason: Errors.getSdkError(Errors.USER_DISCONNECTED).toSignError(),
    );

    _reloadStores();
    _refreshUi();
  }

  @override
  Map<String, SessionData> getActiveSessions() {
    if (_wcClient == null) {
      return <String, SessionData>{};
    }
    return _wcClient!.getActiveSessions();
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
        _wcClient!.registerRequestHandler(
          chainId: chainId,
          method: method,
        );
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

    final IChain Function(String chainId)? customResolver = _chainResolver;
    if (customResolver != null) {
      return customResolver(resolvedChainId);
    }

    return sl<IChain>(instanceName: resolvedChainId);
  }

  Future<dynamic> _handleZnnInfoRequest(
    String topic,
    dynamic params, {
    String? chainId,
    int? requestId,
  }) {
    final IChain chain = _resolveChainService(topic, chainId: chainId);
    if (chain is NoMService) {
      return chain.handleZnnInfo(topic, params, requestId: requestId);
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
  }) {
    final IChain chain = _resolveChainService(topic, chainId: chainId);
    if (chain is NoMService) {
      return chain.handleZnnSign(topic, params, requestId: requestId);
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
  }) {
    final IChain chain = _resolveChainService(topic, chainId: chainId);
    if (chain is NoMService) {
      return chain.handleZnnSend(topic, params, requestId: requestId);
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
  }) async {
    if (_wcClient == null) return;

    if (!_markRequestInFlight(id)) {
      return;
    }

    if (!_hasActiveSessionTopic(topic)) {
      _markRequestCompleted(id);
      final String staleKey = '$method:$topic';
      if (_stalePendingTopics.add(staleKey)) {
        _logger.finer(
          'Skipping stale WalletConnect request without active session '
          '($sourceLabel): $method ($id) topic=$topic',
        );
      }
      return;
    }

    try {
      _logger.fine(
        'Handling WalletConnect session request ($sourceLabel): $method ($id)',
      );

      final dynamic result = await _dispatchSessionRequest(
        topic: topic,
        chainId: chainId,
        requestId: id,
        method: method,
        params: params,
      );

      await _respondSuccess(topic: topic, requestId: id, result: result);

      _markRequestCompleted(id);
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

      try {
        await _respondError(
          topic: topic,
          requestId: id,
          error: walletConnectErrorToJsonRpcError(e),
        );
        _markRequestCompleted(id);
      } on Object catch (responseError, responseStack) {
        if (_isStaleSessionError(responseError)) {
          _logger.finer(
            'WalletConnect stale error response skipped ($sourceLabel): '
            '$method ($id) topic=$topic error=$responseError',
          );
          _markRequestCompleted(id);
        } else if (_isAlreadyRespondedError(responseError)) {
          _logger.fine(
            'WalletConnect error response skipped (already responded): '
            '$method ($id)',
          );
          _markRequestCompleted(id);
        } else {
          _markRequestFailed(id);
          _logger.severe(
            'Failed sending error response for request $id',
            responseError,
            responseStack,
          );
        }
      }
    }
  }

  Future<dynamic> _dispatchSessionRequest({
    required String topic,
    required String method,
    required dynamic params,
    String? chainId,
    int? requestId,
  }) {
    switch (method) {
      case 'znn_info':
        return _handleZnnInfoRequest(
          topic,
          params,
          chainId: chainId,
          requestId: requestId,
        );
      case 'znn_sign':
        return _handleZnnSignRequest(
          topic,
          params,
          chainId: chainId,
          requestId: requestId,
        );
      case 'znn_send':
        return _handleZnnSendRequest(
          topic,
          params,
          chainId: chainId,
          requestId: requestId,
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
  }

  void _markRequestFailed(int id) {
    _inFlightRequestIds.remove(id);
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
        message.contains("proposal id doesn't exist");
  }

  Future<void> _respondSuccess({
    required String topic,
    required int requestId,
    required dynamic result,
  }) {
    final JsonRpcResponse<dynamic> response = JsonRpcResponse<dynamic>(
      id: requestId,
      result: result,
    );

    return _wcClient!.respondSessionRequest(topic: topic, response: response);
  }

  Future<void> _respondError({
    required String topic,
    required int requestId,
    required JsonRpcError error,
  }) {
    final JsonRpcResponse<dynamic> response = JsonRpcResponse<dynamic>(
      id: requestId,
      error: error,
    );

    return _wcClient!.respondSessionRequest(topic: topic, response: response);
  }

  void _reloadStores() {
    if (_wcClient == null) return;

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

  void _refreshUi() {
    if (sl.isRegistered<WalletConnectPairingsBloc>()) {
      sl.get<WalletConnectPairingsBloc>().refreshResults();
    }
    if (sl.isRegistered<WalletConnectSessionsBloc>()) {
      sl.get<WalletConnectSessionsBloc>().refreshResults();
    }
  }

  Future<void> _onSessionProposal(SessionProposalEvent? event) async {
    if (event == null || _wcClient == null) return;

    if (_approvedProposalIds.contains(event.id) ||
        !_proposalIdsInFlight.add(event.id)) {
      _logger.fine('Ignoring duplicate WalletConnect proposal ${event.id}');
      return;
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
        _proposalIdsInFlight.remove(event.id);
        _reloadStores();
        _refreshUi();
      }
      return;
    }

    if (!await windowManager.isFocused() || !await windowManager.isVisible()) {
      await windowManager.show();
    }

    final BuildContext? context = globalNavigatorKey.currentContext;
    if (context == null || !context.mounted) {
      _logger.warning('No navigator context available for session proposal');
      _proposalIdsInFlight.remove(event.id);
      return;
    }

    final String requestedChains = _requestedChainsLabel(event.params);
    final String requestedMethods = _requestedMethodsLabel(event.params);
    final String requestedEvents = _requestedEventsLabel(event.params);

    final bool? accepted = await showDialogWithNoAndYesOptions(
      context: context,
      isBarrierDismissible: false,
      title: 'Approve session',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text('Are you sure you want to connect to $dAppName?'),
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
        _refreshUi();
      } on Object catch (e, s) {
        _logger.severe('Failed approving WalletConnect session', e, s);
        await NotificationUtils.sendNotificationError(
          e,
          'WalletConnect session approval failed',
        );
      } finally {
        _proposalIdsInFlight.remove(event.id);
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
      _proposalIdsInFlight.remove(event.id);
      _reloadStores();
      _refreshUi();
    }
  }

  /// Validates [requiredNamespaces] against the currently active Zenon chain
  /// and supported methods/events, returning a human-readable rejection reason
  /// or `null` when conforming.
  @visibleForTesting
  String? unsupportedRequiredNamespaceReason(
    Map<String, RequiredNamespace> requiredNamespaces,
  ) {
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
          .where((String chainId) => chainId != _namespaceChainId)
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
    _refreshUi();
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

  String _dAppName(PairingMetadata metadata) {
    return _metadataValue(metadata.name, 'Unknown dApp');
  }

  String _dAppDescription(PairingMetadata metadata) {
    return _metadataValue(metadata.description, 'No description provided');
  }

  String? _dAppUrl(PairingMetadata metadata) {
    final String value = _metadataValue(metadata.url, '');
    final Uri? uri = Uri.tryParse(value);
    if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
      return null;
    }
    return value;
  }

  String? _dAppIconUrl(PairingMetadata metadata) {
    for (final String icon in metadata.icons) {
      final String value = _metadataValue(icon, '');
      final Uri? uri = Uri.tryParse(value);
      if (uri != null && (uri.scheme == 'http' || uri.scheme == 'https')) {
        return value;
      }
    }
    return null;
  }

  String _metadataValue(String value, String fallback) {
    final String trimmed = value.trim();
    if (trimmed.isEmpty || trimmed.toLowerCase() == 'null') {
      return fallback;
    }
    return trimmed;
  }

  void _upsertSession(SessionData session) {
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
    _refreshUi();
  }

  void _onPairingsSync(StoreSyncEvent? args) {
    if (args == null) return;
    _reloadStores();
    _refreshUi();
  }

  void _onSessionDelete(SessionDelete? args) {
    _reloadStores();
    _refreshUi();
  }

  void _onSessionProposalError(SessionProposalErrorEvent? args) {
    _logger.severe('Session proposal error: $args');

    if (args != null) {
      _proposalIdsInFlight.remove(args.id);
    }
    _reloadStores();
    _refreshUi();
  }

  void _onPairingCreate(PairingEvent? args) {
    _reloadStores();
    _refreshUi();
  }

  void _onPairingActivate(PairingActivateEvent? args) {
    _reloadStores();
    _refreshUi();
  }

  void _onPairingPing(PairingEvent? args) {
    _reloadStores();
    _refreshUi();
  }

  void _onPairingInvalid(PairingInvalidEvent? args) {
    _reloadStores();
    _refreshUi();
  }

  void _onPairingDelete(PairingEvent? args) {
    _reloadStores();
    _refreshUi();
  }

  void _onRelayClientConnect(dynamic args) {
    _reloadStores();
    _refreshUi();
  }

  void _onRelayClientDisconnect(dynamic args) {
    _reloadStores();
    _refreshUi();
  }

  void _onRelayClientError(dynamic args) {
    _logger.warning('Relay client error: $args');
  }
}
