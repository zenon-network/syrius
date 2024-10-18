import 'dart:async';

import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:walletconnect_flutter_v2/walletconnect_flutter_v2.dart';
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
  Web3Wallet? _wcClient;

  /// The list of requests from the dapp
  /// Potential types include, but aren't limited to:
  /// [SessionProposalEvent], [AuthRequest]
  @override
  ValueNotifier<List<PairingInfo>> pairings =
      ValueNotifier<List<PairingInfo>>([]);
  @override
  ValueNotifier<List<SessionData>> sessions =
      ValueNotifier<List<SessionData>>([]);
  @override
  ValueNotifier<List<StoredCacao>> auth = ValueNotifier<List<StoredCacao>>([]);

  final List<int> _idSessionsApproved = [];

  @override
  void create() {
    if (kWcProjectId.isNotEmpty) {
      _wcClient = Web3Wallet(
        core: Core(
          projectId: kWcProjectId,
        ),
        metadata: const PairingMetadata(
          name: 's y r i u s',
          description: 'A wallet for interacting with Zenon Network',
          url: 'https://zenon.network',
          icons: [
            'https://raw.githubusercontent.com/zenon-network/syrius/master/macos/Runner/Assets.xcassets/AppIcon.appiconset/Icon-MacOS-512x512%402x.png',
          ],
        ),
      );

      // Setup our listeners
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
      // _wcClient!.onAuthRequest.subscribe(_onAuthRequest);
    } else {
      Logger('WalletConnectService').log(Level.INFO, 'kWcProjectId missing');
    }
  }

  @override
  Future<void> init() async {
    // Await the initialization of the web3wallet
    Logger('WalletConnectService').log(Level.INFO, 'initialization');
    await _wcClient!.init();

    pairings.value = _wcClient!.pairings.getAll();
    sessions.value = _wcClient!.sessions.getAll();
    auth.value = _wcClient!.completeRequests.getAll();
  }

  @override
  FutureOr onDispose() {
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
    // _wcClient!.onAuthRequest.unsubscribe(_onAuthRequest);

    pairings.dispose();
    sessions.dispose();
    auth.dispose();
  }

  @override
  Web3Wallet getWeb3Wallet() {
    return _wcClient!;
  }

  @override
  Future<PairingInfo> pair(Uri uri) {
    return _wcClient!.pair(uri: uri);
  }

  @override
  Future<void> activatePairing({
    required String topic,
  }) {
    return _wcClient!.core.pairing.activate(
      topic: topic,
    );
  }

  @override
  Future<void> deactivatePairing({
    required String topic,
  }) async {
    try {
      _wcClient!.core.pairing.disconnect(topic: topic);
      _idSessionsApproved.clear();
    } on WalletConnectError catch (e) {
      // technically look for WalletConnectError 6 : Expired.  to consider it a warning
      Logger('WalletConnectService')
          .log(Level.INFO, 'deactivatePairing ${e.code} : ${e.message}');
    } catch (e, s) {
      // Catch anything else (not just Exceptions) and log stack
      Logger('WalletConnectService').log(Level.INFO,
          'disconnectAllParings - Unexpected error: $e, topic $topic\n$s',);
    }
  }

  @override
  Map<String, SessionData> getSessionsForPairing(String pairingTopic) {
    return _wcClient!.getSessionsForPairing(
      pairingTopic: pairingTopic,
    );
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
    Logger('WalletConnectService')
        .log(Level.INFO, 'disconnectSessions triggered');
    for (var i = 0; i < pairings.value.length; i++) {
      await _wcClient!.disconnectSession(
          topic: pairings.value[i].topic,
          reason: Errors.getSdkError(Errors.USER_DISCONNECTED),);
    }
    _idSessionsApproved.clear();
  }

  @override
  Future<void> disconnectSession({required String topic}) async {
    Logger('WalletConnectService')
        .log(Level.INFO, 'disconnectSession triggered', topic);
    _wcClient!.disconnectSession(
      topic: topic,
      reason: Errors.getSdkError(Errors.USER_DISCONNECTED),
    );
  }

  @override
  Map<String, SessionData> getActiveSessions() {
    Logger('WalletConnectService')
        .log(Level.INFO, 'getActiveSessions triggered');
    return _wcClient!.getActiveSessions();
  }

  Future<void> _onRelayClientConnect(var args) async {
    Logger('WalletConnectService')
        .log(Level.INFO, '_onRelayClientConnect triggered', args.toString());
  }

  Future<void> _onRelayClientDisconnect(var args) async {
    Logger('WalletConnectService')
        .log(Level.INFO, '_onRelayClientDisconnect triggered', args.toString());
  }

  Future<void> _onRelayClientError(var args) async {
    Logger('WalletConnectService')
        .log(Level.INFO, '_onRelayClientError triggered', args.toString());
  }

  Future<void> _onSessionsSync(StoreSyncEvent? args) async {
    if (args != null) {
      Logger('WalletConnectService')
          .log(Level.INFO, '_onSessionsSync triggered', args.toString());
      sessions.value = _wcClient!.sessions.getAll();
    }
  }

  Future<void> _onPairingCreate(PairingEvent? args) async {
    Logger('WalletConnectService')
        .log(Level.INFO, 'onPairingCreate triggered', args.toString());
    sl.get<WalletConnectPairingsBloc>().refreshResults();
  }

  Future<void> _onPairingActivate(PairingActivateEvent? args) async {
    Logger('WalletConnectService')
        .log(Level.INFO, '_onPairingActivate triggered', args.toString());
    sl.get<WalletConnectPairingsBloc>().refreshResults();
  }

  Future<void> _onPairingPing(PairingEvent? args) async {
    Logger('WalletConnectService')
        .log(Level.INFO, '_onPairingPing triggered', args.toString());
  }

  void _onPairingInvalid(PairingInvalidEvent? args) {
    Logger('WalletConnectService')
        .log(Level.INFO, 'onPairingInvalid triggered', args.toString());
  }

  Future<void> _onPairingDelete(PairingEvent? args) async {
    Logger('WalletConnectService')
        .log(Level.INFO, '_onPairingDelete triggered', args.toString());
  }

  Future<void> _onPairingsSync(StoreSyncEvent? args) async {
    if (args != null) {
      Logger('WalletConnectService')
          .log(Level.INFO, '_onPairingsSync triggered', args.toString());
      pairings.value = _wcClient!.pairings.getAll();
    }
  }

  Future<void> _onSessionRequest(SessionRequestEvent? args) async {
    Logger('WalletConnectService')
        .log(Level.INFO, '_onSessionRequest triggered', args.toString());
  }

  void _onSessionDelete(SessionDelete? args) {
    Logger('WalletConnectService')
        .log(Level.INFO, '_onSessionDelete triggered', args.toString());
    sl.get<WalletConnectSessionsBloc>().refreshResults();
  }

  void _onSessionProposalError(SessionProposalErrorEvent? args) {
    Logger('WalletConnectService')
        .log(Level.INFO, '_onSessionProposalError triggered', args.toString());
    sl.get<WalletConnectPairingsBloc>().refreshResults();
  }

  Future<void> _onSessionProposal(SessionProposalEvent? event) async {
    Logger('WalletConnectService')
        .log(Level.INFO, '_onSessionProposal triggered', event.toString());

    if (event != null) {
      Logger('WalletConnectService')
          .log(Level.INFO, '_onSessionProposal event', event.params.toJson());

      final dAppMetadata = event.params.proposer.metadata;

      final actionWasAccepted = await showDialogWithNoAndYesOptions(
        context: globalNavigatorKey.currentContext!,
        isBarrierDismissible: false,
        title: 'Approve session',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Are you sure you want to '
                'connect to ${dAppMetadata.name} ?'),
            kVerticalSpacing,
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
                Text(dAppMetadata.url),
                LinkIcon(
                  url: dAppMetadata.url,
                ),
              ],
            ),
          ],
        ),
        onYesButtonPressed: () async {},
        onNoButtonPressed: () async {},
      );

      if (actionWasAccepted) {
        if (!_idSessionsApproved.contains(event.id)) {
          _idSessionsApproved.add(event.id);
          try {
            final approveResponse =
                await _approveSession(id: event.id);
            await _sendSuccessfullyApprovedSessionNotification(dAppMetadata);
            sessions.value.add(approveResponse.session);
          } catch (e, stackTrace) {
            await NotificationUtils.sendNotificationError(
                e, 'WalletConnect session approval failed',);
            Logger('WalletConnectService').log(
                Level.INFO, 'onSessionProposal approveResponse', e, stackTrace,);
          }
        }
      } else {
        await _wcClient!.rejectSession(
          id: event.id,
          reason: Errors.getSdkError(
            Errors.USER_REJECTED,
          ),
        );
      }
    }
  }

  void _onSessionConnect(SessionConnect? args) {
    if (args != null) {
      sessions.value.add(args.session);
    }
    Logger('WalletConnectService')
        .log(Level.INFO, '_onSessionConnect triggered', args.toString());
    Future.delayed(const Duration(seconds: 3))
        .then((value) => sl.get<WalletConnectSessionsBloc>().refreshResults());
  }

  Future<void> _sendSuccessfullyApprovedSessionNotification(
      PairingMetadata dAppMetadata,) async {
    await sl.get<NotificationsBloc>().addNotification(
          WalletNotification(
            title: 'Successfully connected to ${dAppMetadata.name}',
            timestamp: DateTime.now().millisecondsSinceEpoch,
            details: 'Successfully connected to ${dAppMetadata.name} '
                'via WalletConnect',
            type: NotificationType.paymentSent,
          ),
        );
  }

  Future<ApproveResponse> _approveSession(
      {required int id, Map<String, Namespace>? namespaces,}) async {
    if (!await windowManager.isFocused() || !await windowManager.isVisible()) {
      windowManager.show();
    }
    namespaces = namespaces ??
        {
          'zenon': Namespace(
            accounts: _getWalletAccounts(),
            methods: [
              'znn_sign',
              'znn_info',
              'znn_send',
            ],
            events: ['chainIdChange', 'addressChange'],
          ),
        };
    return _wcClient!.approveSession(
      id: id,
      namespaces: namespaces,
    );
  }

  String _generateAccount(String address, int chainId) =>
      '$kZenonNameSpace:1:$address';

  List<String> _getWalletAccounts() => kAddressLabelMap.values
      .map(
        (address) => _generateAccount(address, getChainIdentifier()),
      )
      .toList();

  Future<void> _emitEventPairedDApps({
    required String changeName,
    required String newValue,
  }) async {
    final sessionTopics =
        pairings.value.fold<List<String>>(<String>[], (previousValue, pairing) {
      if (pairing.active) {
        previousValue.addAll(getSessionsForPairing(pairing.topic).keys);
        return previousValue;
      }
      return previousValue;
    });

    for (final sessionTopic in sessionTopics) {
      _emitDAppEvent(
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
      chainId: 'zenon:1',
      event: SessionEventParams(
        name: changeName,
        data: newValue,
      ),
    );
  }
}
