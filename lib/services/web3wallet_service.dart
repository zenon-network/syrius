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
import 'package:zenon_syrius_wallet_flutter/services/i_web3wallet_service.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/dialogs.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/icons/link_icon.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class Web3WalletService extends IWeb3WalletService {
  static const Duration _pendingRequestsPollInterval = Duration(seconds: 1);
  static Web3WalletService? _instance;

  static Web3WalletService getInstance() {
    _instance ??= Web3WalletService();
    _instance!.create();
    return _instance!;
  }

  final Logger _logger = Logger('WalletConnectService');

  ReownWalletKit? _wcClient;
  Timer? _pendingRequestsPollTimer;
  final Set<int> _approvedProposalIds = <int>{};
  final Set<int> _inFlightRequestIds = <int>{};
  final Set<int> _completedRequestIds = <int>{};
  final Set<String> _stalePendingTopics = <String>{};
  @override
  ValueNotifier<List<PairingInfo>> pairings =
      ValueNotifier<List<PairingInfo>>(<PairingInfo>[]);

  @override
  ValueNotifier<List<SessionData>> sessions =
      ValueNotifier<List<SessionData>>(<SessionData>[]);

  bool get _isCreated => _wcClient != null;
  String get _namespaceChainId => 'zenon:${getChainIdentifier()}';

  @override
  void create() {
    if (_wcClient != null) {
      return;
    }

    if (kWcProjectId.isEmpty) {
      _logger.warning('WalletConnect project id missing');
      return;
    }

    _wcClient = ReownWalletKit(
      core: ReownCore(projectId: kWcProjectId),
      metadata: const PairingMetadata(
        name: 's y r i u s',
        description: 'A wallet for interacting with Zenon Network',
        url: 'https://zenon.network',
        icons: [
          'https://raw.githubusercontent.com/zenon-network/syrius/master/macos/Runner/Assets.xcassets/AppIcon.appiconset/Icon-MacOS-512x512%402x.png',
        ],
      ),
    );

    _subscribeListeners();
    _registerEventEmitters();
    _registerRequestHandlers();
    _startPendingRequestsPolling();
  }

  @override
  Future<void> init() async {
    if (!_isCreated) {
      _logger.warning('init called before create');
      return;
    }

    _registerAccountsIfNeeded();

    await _wcClient!.init();

    _reloadStores();
    _refreshUi();
  }

  @override
  FutureOr<void> onDispose() {
    _pendingRequestsPollTimer?.cancel();
    _pendingRequestsPollTimer = null;
    if (_wcClient != null) {
      _unsubscribeListeners();
    }

    _approvedProposalIds.clear();
    _inFlightRequestIds.clear();
    _completedRequestIds.clear();
    _stalePendingTopics.clear();
    _wcClient = null;

    _registeredAccounts.clear();
  }

  @override
  ReownWalletKit getWeb3Wallet() => _wcClient!;

  @override
  Future<PairingInfo> pair(Uri uri) async {
    await _cleanupStalePairings();
    if (_wcClient == null) {
      throw StateError('WalletConnect client not created');
    }

    if (kAddressLabelMap.isEmpty) {
      throw StateError('No wallet addresses available');
    }

    _registerAccountsIfNeeded();
    await _cleanupStalePairings();

    final pairing = await _wcClient!.pair(uri: uri);
    _reloadStores();
    _refreshUi();
    return pairing;
  }

  Future<void> _cleanupStalePairings() async {
    if (_wcClient == null) return;

    final currentPairings =
        List<PairingInfo>.from(_wcClient!.pairings.getAll());

    for (final pairing in currentPairings) {
      final sessionsForPairing =
          _wcClient!.getSessionsForPairing(pairingTopic: pairing.topic);

      final hasSessions = sessionsForPairing.isNotEmpty;

      if (!hasSessions) {
        try {
          _logger.info('Removing orphan pairing: ${pairing.topic}');
          await _wcClient!.core.pairing.disconnect(topic: pairing.topic);
        } catch (e, s) {
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
  Future<void> activatePairing({
    required String topic,
  }) async {
    await _wcClient!.core.pairing.activate(topic: topic);
    _reloadStores();
    _refreshUi();
  }

  @override
  Future<void> deactivatePairing({
    required String topic,
  }) async {
    try {
      await _wcClient!.core.pairing.disconnect(topic: topic);
      _approvedProposalIds.clear();
      _reloadStores();
      _refreshUi();
    } on ReownCoreError catch (e) {
      _logger.warning('Failed to deactivate pairing: ${e.code} ${e.message}');
    } catch (e, s) {
      _logger.severe('Unexpected error while deactivating pairing', e, s);
    }
  }

  @override
  Map<String, SessionData> getSessionsForPairing(String pairingTopic) {
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
    return _emitEventPairedDApps(
      changeName: 'chainIdChange',
      newValue: newChainId,
    );
  }

  @override
  Future<void> disconnectSessions() async {
    final currentSessions = List<SessionData>.from(sessions.value);

    for (final session in currentSessions) {
      try {
        await _wcClient!.disconnectSession(
          topic: session.topic,
          reason: Errors.getSdkError(Errors.USER_DISCONNECTED).toSignError(),
        );
      } catch (e, s) {
        _logger.warning(
          'Failed to disconnect session ${session.topic}',
          e,
          s,
        );
      }
    }

    _approvedProposalIds.clear();
    _reloadStores();
    _refreshUi();
  }

  Future<void> disconnectAllPairings() async {
    final currentPairings = List<PairingInfo>.from(pairings.value);

    for (final pairing in currentPairings) {
      try {
        await _wcClient!.core.pairing.disconnect(topic: pairing.topic);
      } catch (e, s) {
        _logger.warning(
          'Failed to disconnect pairing ${pairing.topic}',
          e,
          s,
        );
      }
    }

    _approvedProposalIds.clear();
    _reloadStores();
    _refreshUi();
  }

  Future<void> disconnectEverything() async {
    await disconnectSessions();
    await disconnectAllPairings();
  }

  @override
  Future<void> disconnectSession({required String topic}) async {
    await _wcClient!.disconnectSession(
      topic: topic,
      reason: Errors.getSdkError(Errors.USER_DISCONNECTED).toSignError(),
    );

    _reloadStores();
    _refreshUi();
  }

  @override
  Map<String, SessionData> getActiveSessions() {
    return _wcClient!.getActiveSessions();
  }

  void _subscribeListeners() {
    _wcClient!.core.relayClient.onRelayClientConnect
        .subscribe(_onRelayClientConnect);
    _wcClient!.core.relayClient.onRelayClientDisconnect
        .subscribe(_onRelayClientDisconnect);
    _wcClient!.core.relayClient.onRelayClientError
        .subscribe(_onRelayClientError);

    _wcClient!.core.pairing.onPairingCreate.subscribe(_onPairingCreate);
    _wcClient!.core.pairing.onPairingActivate.subscribe(_onPairingActivate);
    _wcClient!.core.pairing.onPairingPing.subscribe(_onPairingPing);
    _wcClient!.core.pairing.onPairingInvalid.subscribe(_onPairingInvalid);
    _wcClient!.core.pairing.onPairingDelete.subscribe(_onPairingDelete);

    _wcClient!.pairings.onSync.subscribe(_onPairingsSync);
    _wcClient!.sessions.onSync.subscribe(_onSessionsSync);

    _wcClient!.onSessionProposal.subscribe(_onSessionProposal);
    _wcClient!.onSessionConnect.subscribe(_onSessionConnect);
    _wcClient!.onSessionProposalError.subscribe(_onSessionProposalError);
    _wcClient!.onSessionDelete.subscribe(_onSessionDelete);
  }

  void _unsubscribeListeners() {
    _wcClient!.core.relayClient.onRelayClientConnect
        .unsubscribe(_onRelayClientConnect);
    _wcClient!.core.relayClient.onRelayClientDisconnect
        .unsubscribe(_onRelayClientDisconnect);
    _wcClient!.core.relayClient.onRelayClientError
        .unsubscribe(_onRelayClientError);

    _wcClient!.core.pairing.onPairingCreate.unsubscribe(_onPairingCreate);
    _wcClient!.core.pairing.onPairingActivate.unsubscribe(_onPairingActivate);
    _wcClient!.core.pairing.onPairingPing.unsubscribe(_onPairingPing);
    _wcClient!.core.pairing.onPairingInvalid.unsubscribe(_onPairingInvalid);
    _wcClient!.core.pairing.onPairingDelete.unsubscribe(_onPairingDelete);

    _wcClient!.pairings.onSync.unsubscribe(_onPairingsSync);
    _wcClient!.sessions.onSync.unsubscribe(_onSessionsSync);

    _wcClient!.onSessionProposal.unsubscribe(_onSessionProposal);
    _wcClient!.onSessionConnect.unsubscribe(_onSessionConnect);
    _wcClient!.onSessionProposalError.unsubscribe(_onSessionProposalError);
    _wcClient!.onSessionDelete.unsubscribe(_onSessionDelete);
  }

  final Set<String> _registeredAccounts = <String>{};

  void _registerAccountsIfNeeded() {
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

    for (final address in kAddressLabelMap.keys) {
      final accountKey = '$_namespaceChainId::$address';

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
    const events = <String>[
      'chainIdChange',
      'addressChange',
    ];

    for (final event in events) {
      _wcClient!.registerEventEmitter(
        chainId: _namespaceChainId,
        event: event,
      );
    }
  }

  void _registerRequestHandlers() {
    _wcClient!.registerRequestHandler(
      chainId: _namespaceChainId,
      method: 'znn_info',
      handler: _handleZnnInfoRequest,
    );

    _wcClient!.registerRequestHandler(
      chainId: _namespaceChainId,
      method: 'znn_sign',
      handler: _handleZnnSignRequest,
    );

    _wcClient!.registerRequestHandler(
      chainId: _namespaceChainId,
      method: 'znn_send',
      handler: _handleZnnSendRequest,
    );
  }

  IChain _resolveChainService(
    String topic, {
    String? chainId,
  }) {
    String resolvedChainId = chainId ?? _namespaceChainId;

    try {
      final session = _wcClient!
          .getActiveSessions()
          .values
          .firstWhere((element) => element.topic == topic);

      final chains = session.namespaces['zenon']?.chains;
      if (chains != null && chains.isNotEmpty) {
        resolvedChainId = chains.first;
      }
    } catch (_) {
      // Session may not be in active store yet; fallback to provided chainId.
    }

    return sl<IChain>(instanceName: resolvedChainId);
  }

  Future<dynamic> _handleZnnInfoRequest(
    String topic,
    dynamic params, {
    String? chainId,
  }) {
    final chain = _resolveChainService(topic, chainId: chainId);
    if (chain is NoMService) {
      return chain.handleZnnInfo(topic, params);
    }
    throw UnsupportedError(
        'znn_info not implemented for chain ${chain.getChainId()}');
  }

  Future<dynamic> _handleZnnSignRequest(
    String topic,
    dynamic params, {
    String? chainId,
  }) {
    final chain = _resolveChainService(topic, chainId: chainId);
    if (chain is NoMService) {
      return chain.handleZnnSign(topic, params);
    }
    throw UnsupportedError(
        'znn_sign not implemented for chain ${chain.getChainId()}');
  }

  Future<dynamic> _handleZnnSendRequest(
    String topic,
    dynamic params, {
    String? chainId,
  }) {
    final chain = _resolveChainService(topic, chainId: chainId);
    if (chain is NoMService) {
      return chain.handleZnnSend(topic, params);
    }
    throw UnsupportedError(
        'znn_send not implemented for chain ${chain.getChainId()}');
  }

  void _startPendingRequestsPolling() {
    _pendingRequestsPollTimer?.cancel();
    _pendingRequestsPollTimer = Timer.periodic(
      _pendingRequestsPollInterval,
      (_) => _drainPendingSessionRequests(),
    );
  }

  Future<void> _drainPendingSessionRequests() async {
    if (_wcClient == null) return;

    final pendingRequests = _safeGetPendingRequests();
    if (pendingRequests.isEmpty) return;

    for (final request in pendingRequests.values) {
      final int? id = _tryGet(() => request.id);
      final String? topic = _tryGet(() => request.topic);
      final String? method = _tryGet(() => request.method);
      final String? chainId = _tryGet(() => request.chainId);
      final dynamic params = _tryGet(() => request.params);

      if (id == null || topic == null || method == null) {
        continue;
      }

      if (!_markRequestInFlight(id)) {
        continue;
      }

      if (!_hasActiveSessionTopic(topic)) {
        _markRequestCompleted(id);
        final staleKey = '$method:$topic';
        if (_stalePendingTopics.add(staleKey)) {
          _logger.finer(
            'Skipping stale pending WalletConnect request without active session: '
            '$method ($id) topic=$topic',
          );
        }
        continue;
      }

      try {
        _logger.fine(
          'Draining pending WalletConnect request as fallback: '
          '$method ($id)',
        );

        final result = await _dispatchSessionRequest(
          topic: topic,
          chainId: chainId,
          requestId: id,
          method: method,
          params: params,
        );

        await _respondSuccess(
          topic: topic,
          requestId: id,
          result: result,
        );

        _markRequestCompleted(id);
      } catch (e, s) {
        if (_isStaleSessionError(e)) {
          _logger.finer(
            'Dropping stale pending WalletConnect request: $method ($id) '
            'topic=$topic error=$e',
          );
          _markRequestCompleted(id);
          continue;
        }

        if (_isAlreadyRespondedError(e)) {
          _logger.fine(
            'WalletConnect request already responded by live handler: '
            '$method ($id)',
          );
          _markRequestCompleted(id);
          continue;
        }

        _logger.severe(
          'Failed handling pending session request: $method',
          e,
          s,
        );

        try {
          await _respondError(
            topic: topic,
            requestId: id,
            code: 5000,
            message: e.toString(),
          );
          _markRequestCompleted(id);
        } catch (responseError, responseStack) {
          if (_isStaleSessionError(responseError)) {
            _logger.finer(
              'WalletConnect stale error response skipped: $method ($id) '
              'topic=$topic error=$responseError',
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
  }

  Future<dynamic> _dispatchSessionRequest({
    required String topic,
    String? chainId,
    int? requestId,
    required String method,
    required dynamic params,
  }) {
    switch (method) {
      case 'znn_info':
        return _handleZnnInfoRequest(topic, params, chainId: chainId);
      case 'znn_sign':
        return _handleZnnSignRequest(topic, params, chainId: chainId);
      case 'znn_send':
        return _handleZnnSendRequest(topic, params, chainId: chainId);
      default:
        throw UnsupportedError('Unsupported WalletConnect method: $method');
    }
  }

  Map<dynamic, dynamic> _safeGetPendingRequests() {
    try {
      return _wcClient!.getPendingSessionRequests();
    } catch (_) {
      return const {};
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
    } catch (_) {
      return false;
    }
  }

  bool _isStaleSessionError(Object error) {
    final message = error.toString().toLowerCase();
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
    final message = error.toString().toLowerCase();
    return message.contains('already responded') ||
        message.contains('response already') ||
        message.contains('request already') ||
        message.contains('duplicate response') ||
        message.contains('request not found');
  }

  T? _tryGet<T>(T Function() fn) {
    try {
      return fn();
    } catch (_) {
      return null;
    }
  }

  Future<void> _respondSuccess({
    required String topic,
    required int requestId,
    required dynamic result,
  }) {
    final response = JsonRpcResponse<dynamic>(
      id: requestId,
      jsonrpc: '2.0',
      result: result,
    );

    return _wcClient!.respondSessionRequest(
      topic: topic,
      response: response,
    );
  }

  Future<void> _respondError({
    required String topic,
    required int requestId,
    required int code,
    required String message,
  }) {
    final response = JsonRpcResponse<dynamic>(
      id: requestId,
      jsonrpc: '2.0',
      error: JsonRpcError(
        code: code,
        message: message,
      ),
    );

    return _wcClient!.respondSessionRequest(
      topic: topic,
      response: response,
    );
  }

  void _reloadStores() {
    if (_wcClient == null) return;

    final updatedPairings =
        List<PairingInfo>.from(_wcClient!.pairings.getAll());
    final updatedSessions =
        List<SessionData>.from(_wcClient!.sessions.getAll());

    pairings.value = updatedPairings;
    sessions.value = updatedSessions;

    _logger.info(
      'Reloaded WalletConnect stores: '
      '${updatedPairings.length} pairings, ${updatedSessions.length} sessions',
    );
  }

  void _refreshUi() {
    sl.get<WalletConnectPairingsBloc>().refreshResults();
    sl.get<WalletConnectSessionsBloc>().refreshResults();
  }

  Future<void> _onSessionProposal(SessionProposalEvent? event) async {
    if (event == null) return;

    final context = globalNavigatorKey.currentContext;
    if (context == null) {
      _logger.warning('No navigator context available for session proposal');
      return;
    }

    final dAppMetadata = event.params.proposer.metadata;

    final accepted = await showDialogWithNoAndYesOptions(
      context: context,
      isBarrierDismissible: false,
      title: 'Approve session',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text('Are you sure you want to connect to ${dAppMetadata.name}?'),
          kVerticalSpacing,
          if (dAppMetadata.icons.isNotEmpty)
            Image(
              image: NetworkImage(dAppMetadata.icons.first),
              height: 100,
              fit: BoxFit.fitHeight,
            ),
          kVerticalSpacing,
          Text(dAppMetadata.description),
          kVerticalSpacing,
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  dAppMetadata.url,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              LinkIcon(url: dAppMetadata.url),
            ],
          ),
        ],
      ),
      onYesButtonPressed: () async {},
      onNoButtonPressed: () async {},
    );

    if (accepted == true) {
      if (_approvedProposalIds.contains(event.id)) {
        return;
      }

      _approvedProposalIds.add(event.id);

      try {
        final approveResponse = await _approveSession(
          id: event.id,
        );

        await _sendSuccessfullyApprovedSessionNotification(dAppMetadata);

        if (approveResponse.session != null) {
          _upsertSession(approveResponse.session!);
        }

        _reloadStores();
        _refreshUi();
      } catch (e, s) {
        _logger.severe('Failed approving WalletConnect session', e, s);
        await NotificationUtils.sendNotificationError(
          e,
          'WalletConnect session approval failed',
        );
      }
      return;
    }

    await _wcClient!.rejectSession(
      id: event.id,
      reason: Errors.getSdkError(Errors.USER_REJECTED).toSignError(),
    );


    _reloadStores();
    _refreshUi();
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
    return sl.get<NotificationsBloc>().addNotification(
          WalletNotification(
            title: 'Successfully connected to ${dAppMetadata.name}',
            timestamp: DateTime.now().millisecondsSinceEpoch,
            details:
                'Successfully connected to ${dAppMetadata.name} via WalletConnect',
            type: NotificationType.paymentSent,
          ),
        );
  }

  Future<ApproveResponse> _approveSession({
    required int id,
  }) async {
    if (!await windowManager.isFocused() || !await windowManager.isVisible()) {
      await windowManager.show();
    }

    final resolvedNamespaces = <String, Namespace>{
      'zenon': Namespace(
        chains: [_namespaceChainId],
        accounts: _walletAccounts(),
        methods: const ['znn_sign', 'znn_info', 'znn_send'],
        events: const ['chainIdChange', 'addressChange'],
      ),
    };

    _logger
        .info('Approving session with manual namespaces: $resolvedNamespaces');

    return _wcClient!.approveSession(
      id: id,
      namespaces: resolvedNamespaces,
    );
  }

  List<String> _walletAccounts() {
    final chainId = getChainIdentifier();
    return kAddressLabelMap.keys
        .map((address) => '$kZenonNameSpace:$chainId:$address')
        .toList();
  }

  void _upsertSession(SessionData session) {
    final updated = List<SessionData>.from(sessions.value);
    final index = updated.indexWhere((item) => item.topic == session.topic);

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
    final currentPairings = List<PairingInfo>.from(pairings.value);

    final sessionTopics =
        currentPairings.fold<List<String>>(<String>[], (topics, pairing) {
      if (pairing.active) {
        topics.addAll(getSessionsForPairing(pairing.topic).keys);
      }
      return topics;
    });

    for (final sessionTopic in sessionTopics) {
      await _emitDAppEvent(
        sessionTopic: sessionTopic,
        changeName: changeName,
        newValue: newValue,
      );
    }
  }

  Future<void> _emitDAppEvent({
    required String sessionTopic,
    required String changeName,
    required String newValue,
  }) {
    return _wcClient!.emitSessionEvent(
      topic: sessionTopic,
      chainId: _namespaceChainId,
      event: SessionEventParams(
        name: changeName,
        data: newValue,
      ),
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

    unawaited(_recoverFromProposalError());
  }

  Future<void> _recoverFromProposalError() async {
    try {
      await _cleanupStalePairings();
    } catch (e, s) {
      _logger.warning('Failed to recover from proposal error', e, s);
    } finally {
      _reloadStores();
      _refreshUi();
    }
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
