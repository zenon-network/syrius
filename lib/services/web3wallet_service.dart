import 'dart:async';

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:reown_walletkit/reown_walletkit.dart';
import 'package:window_manager/window_manager.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/notifications_bloc.dart';
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

  final Logger _logger = Logger('WalletConnectService');

  ReownWalletKit? _wcClient;
  Timer? _pendingRequestsPollTimer;

  final Set<int> _approvedProposalIds = <int>{};
  final Set<int> _handledRequestIds = <int>{};

  @override
  ValueNotifier<List<PairingInfo>> pairings =
      ValueNotifier<List<PairingInfo>>([]);

  @override
  ValueNotifier<List<SessionData>> sessions =
      ValueNotifier<List<SessionData>>([]);

  bool get _isCreated => _wcClient != null;
  String get _namespaceChainId => 'zenon:${getChainIdentifier()}';

  @override
  void create() {
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
    _registerRequestHandlers();
    _startPendingRequestsPolling();
  }

  @override
  Future<void> init() async {
    if (!_isCreated) {
      _logger.warning('init called before create');
      return;
    }

    await _wcClient!.init();

    pairings.value = List<PairingInfo>.from(_wcClient!.pairings.getAll());
    sessions.value = List<SessionData>.from(_wcClient!.sessions.getAll());
  }

  @override
  FutureOr<void> onDispose() {
    _pendingRequestsPollTimer?.cancel();
    _pendingRequestsPollTimer = null;

    if (_wcClient != null) {
      _unsubscribeListeners();
    }

    _approvedProposalIds.clear();
    _handledRequestIds.clear();

    pairings.dispose();
    sessions.dispose();
  }

  @override
  ReownWalletKit getWeb3Wallet() => _wcClient!;

  @override
  Future<PairingInfo> pair(Uri uri) {
    return _wcClient!.pair(uri: uri);
  }

  @override
  Future<void> activatePairing({
    required String topic,
  }) {
    return _wcClient!.core.pairing.activate(topic: topic);
  }

  @override
  Future<void> deactivatePairing({
    required String topic,
  }) async {
    try {
      await _wcClient!.core.pairing.disconnect(topic: topic);
      _approvedProposalIds.clear();
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
    for (final pairing in pairings.value) {
      await _wcClient!.disconnectSession(
        topic: pairing.topic,
        reason: Errors.getSdkError(Errors.USER_DISCONNECTED).toSignError(),
      );
    }

    _approvedProposalIds.clear();
  }

  @override
  Future<void> disconnectSession({required String topic}) {
    return _wcClient!.disconnectSession(
      topic: topic,
      reason: Errors.getSdkError(Errors.USER_DISCONNECTED).toSignError(),
    );
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
    _wcClient!.onSessionRequest.subscribe(_onSessionRequest);
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
    _wcClient!.onSessionRequest.unsubscribe(_onSessionRequest);
    _wcClient!.onSessionProposalError.unsubscribe(_onSessionProposalError);
    _wcClient!.onSessionDelete.unsubscribe(_onSessionDelete);
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

      if (id == null || topic == null || method == null || chainId == null) {
        continue;
      }

      if (_handledRequestIds.contains(id)) {
        continue;
      }

      _handledRequestIds.add(id);

      try {
        final result = await _dispatchSessionRequest(
          topic: topic,
          chainId: chainId,
          method: method,
          params: params,
        );

        await _respondSuccess(
          topic: topic,
          requestId: id,
          result: result,
        );
      } catch (e, s) {
        _logger.severe('Failed handling session request: $method', e, s);

        try {
          await _respondError(
            topic: topic,
            requestId: id,
            code: 5000,
            message: e.toString(),
          );
        } catch (responseError, responseStack) {
          _logger.severe(
            'Failed sending error response for request $id',
            responseError,
            responseStack,
          );
        }
      }
    }
  }

  Map<dynamic, dynamic> _safeGetPendingRequests() {
    try {
      return _wcClient!.getPendingSessionRequests();
    } catch (_) {
      return const {};
    }
  }

  T? _tryGet<T>(T Function() fn) {
    try {
      return fn();
    } catch (_) {
      return null;
    }
  }

  Future<dynamic> _dispatchSessionRequest({
    required String topic,
    required String chainId,
    required String method,
    required dynamic params,
  }) {
    switch (method) {
      case 'znn_info':
        return _handleZnnInfoRequest(topic, params);
      case 'znn_sign':
        return _handleZnnSignRequest(topic, params);
      case 'znn_send':
        return _handleZnnSendRequest(topic, params);
      default:
        throw UnsupportedError('Unsupported WalletConnect method: $method');
    }
  }

  Future<dynamic> _handleZnnInfoRequest(String topic, dynamic params) async {
    final address = _primaryAddress();

    return <String, dynamic>{
      'address': address,
      'chainId': getChainIdentifier(),
      'nodeUrl': kCurrentNode,
    };
  }

  Future<dynamic> _handleZnnSignRequest(String topic, dynamic params) async {
    throw UnimplementedError('znn_sign is not implemented');
  }

  Future<dynamic> _handleZnnSendRequest(String topic, dynamic params) async {
    throw UnimplementedError('znn_send is not implemented');
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

  String _primaryAddress() {
    if (kAddressLabelMap.isEmpty) {
      throw StateError('No Zenon address available');
    }

    return kAddressLabelMap.keys.first;
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
    );

    if (accepted == true) {
      if (_approvedProposalIds.contains(event.id)) return;
      _approvedProposalIds.add(event.id);

      try {
        final approveResponse = await _approveSession(id: event.id);

        await _sendSuccessfullyApprovedSessionNotification(dAppMetadata);

        if (approveResponse.session != null) {
          _upsertSession(approveResponse.session!);
        }
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
  }

  void _onSessionConnect(SessionConnect? args) {
    if (args != null) {
      _upsertSession(args.session);
    }

    Future.delayed(const Duration(seconds: 3)).then(
      (_) => sl.get<WalletConnectSessionsBloc>().refreshResults(),
    );
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
    Map<String, Namespace>? namespaces,
  }) async {
    if (!await windowManager.isFocused() || !await windowManager.isVisible()) {
      await windowManager.show();
    }

    namespaces ??= {
      'zenon': Namespace(
        chains: [_namespaceChainId],
        accounts: _walletAccounts(),
        methods: const ['znn_sign', 'znn_info', 'znn_send'],
        events: const ['chainIdChange', 'addressChange'],
      ),
    };

    return _wcClient!.approveSession(
      id: id,
      namespaces: namespaces,
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
    final sessionTopics =
        pairings.value.fold<List<String>>(<String>[], (topics, pairing) {
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

  Future<void> _onSessionRequest(SessionRequestEvent? args) async {
    if (args == null) return;

    if (_handledRequestIds.contains(args.id)) {
      return;
    }

    _handledRequestIds.add(args.id);

    try {
      final result = await _dispatchSessionRequest(
        topic: args.topic,
        chainId: args.chainId,
        method: args.method,
        params: args.params,
      );

      await _respondSuccess(
        topic: args.topic,
        requestId: args.id,
        result: result,
      );
    } catch (e, s) {
      _logger.severe('Session request failed: ${args.method}', e, s);

      await _respondError(
        topic: args.topic,
        requestId: args.id,
        code: 5000,
        message: e.toString(),
      );
    }
  }

  void _onSessionsSync(StoreSyncEvent? args) {
    if (args == null) return;
    sessions.value = List<SessionData>.from(_wcClient!.sessions.getAll());
  }

  void _onPairingsSync(StoreSyncEvent? args) {
    if (args == null) return;
    pairings.value = List<PairingInfo>.from(_wcClient!.pairings.getAll());
  }

  void _onSessionDelete(SessionDelete? args) {
    sl.get<WalletConnectSessionsBloc>().refreshResults();
  }

  void _onSessionProposalError(SessionProposalErrorEvent? args) {
    _logger.severe('Session proposal error: $args');
    sl.get<WalletConnectPairingsBloc>().refreshResults();
  }

  void _onPairingCreate(PairingEvent? args) {
    sl.get<WalletConnectPairingsBloc>().refreshResults();
  }

  void _onPairingActivate(PairingActivateEvent? args) {
    sl.get<WalletConnectPairingsBloc>().refreshResults();
  }

  void _onPairingPing(PairingEvent? args) {}

  void _onPairingInvalid(PairingInvalidEvent? args) {}

  void _onPairingDelete(PairingEvent? args) {}

  void _onRelayClientConnect(dynamic args) {}

  void _onRelayClientDisconnect(dynamic args) {}

  void _onRelayClientError(dynamic args) {
    _logger.warning('Relay client error: $args');
  }
}
