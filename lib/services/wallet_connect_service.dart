import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:walletconnect_flutter_v2/walletconnect_flutter_v2.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/utils/functions.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/main_app_container.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/dialogs.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/icons/link_icon.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class WalletConnectService {
  WalletConnectService._internal();

  factory WalletConnectService() => _instance;

  static final WalletConnectService _instance =
      WalletConnectService._internal();

  late Web3Wallet _wcClient;
  late BuildContext _context;
  String? _sessionTopic;

  final List<ApproveResponse> _dAppsProposalData = [];

  set context(BuildContext context) => _context = context;

  final _walletLockedError = WalletConnectError(
    code: 9000,
    message: 'Wallet is locked',
  );

  Future<void> initClient() async {
    _wcClient = await Web3Wallet.createInstance(
      projectId: kWcProjectId,
      metadata: const PairingMetadata(
        name: 's y r i u s',
        description: 'A wallet for interacting with Zenon Network',
        url: 'https://zenon.network',
        // TODO: add Zenon icon
        icons: ['https://avatars.githubusercontent.com/u/37784886'],
      ),
    );
    _initListeners();
  }

  Future<PairingInfo> pair(Uri uri) => _wcClient.pair(uri: uri);

  void _initListeners() {
    _wcClient.core.relayClient.onRelayClientDisconnect.subscribe((args) {
      _wcClient.core.relayClient.connect();
    });

    _wcClient.onSessionProposal.subscribe((SessionProposalEvent? event) async {
      Logger('WalletConnectService')
          .log(Level.INFO, 'onSessionProposal triggered', event.toString());

      if (event != null) {
        Logger('WalletConnectService')
            .log(Level.INFO, 'session proposal event', event.params.toJson());

        final dAppMetadata = event.params.proposer.metadata;
        final pairingTopic = event.params.pairingTopic;

        final actionWasAccepted = await showDialogWithNoAndYesOptions(
          context: _context,
          title: 'Approve session',
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text('Are you sure you want to '
                  'connect with ${dAppMetadata.name} ?'),
              kVerticalSpacing,
              Image(
                image: NetworkImage(dAppMetadata.icons.first),
                height: 100.0,
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
                  )
                ],
              ),
            ],
          ),
          onYesButtonPressed: () async {
            Navigator.pop(_context, true);
          },
          onNoButtonPressed: () {
            Navigator.pop(_context, false);
          },
        );

        if (actionWasAccepted) {
          await activatePairing(topic: pairingTopic);
          ApproveResponse approveResponse = await _wcClient.approveSession(
            id: event.id,
            namespaces: {
              'zenon': Namespace(
                accounts: _getWalletAccounts(),
                methods: event.params.optionalNamespaces['zenon']?.methods ??
                    [
                      'znn_sign',
                      'znn_info',
                      'znn_send',
                    ],
                events: event.params.optionalNamespaces['zenon']?.events ??
                    [
                      'chainIdChange',
                      'addressChange',
                    ],
              )
            },
          );

          _sendSuccessfullyApprovedSessionNotification(dAppMetadata);
          _dAppsProposalData.add(approveResponse);
          _sessionTopic = approveResponse.session.topic;
        } else {
          await _wcClient.rejectSession(
            id: event.id,
            reason: Errors.getSdkError(
              Errors.USER_REJECTED,
            ),
          );
        }
      }
    });

    _wcClient.onSessionRequest.subscribe((SessionRequestEvent? request) async {
      Logger('WalletConnectService')
          .log(Level.INFO, 'onSessionRequest triggered', request.toString());

    });

    _wcClient.registerRequestHandler(
      chainId: 'zenon:3',
      method: 'znn_info',
      handler: (topic, params) async {
        final dAppMetadata = _dAppsProposalData
            .firstWhere((element) => element.topic == topic)
            .session.peer.metadata;

        if (kCurrentPage != Tabs.lock) {
          final actionWasAccepted = await showDialogWithNoAndYesOptions(
            context: _context,
            title: '${dAppMetadata.name} - Information',
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text('Are you sure you want to allow ${dAppMetadata.name} to '
                    'retrieve the current address, node URL and chain identifier information?'),
                kVerticalSpacing,
                Image(
                  image: NetworkImage(dAppMetadata.icons.first),
                  height: 100.0,
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
                    )
                  ],
                ),
              ],
            ),
            onYesButtonPressed: () async {
              Navigator.pop(_context, true);
            },
            onNoButtonPressed: () {
              Navigator.pop(_context, false);
            },
          );

          if (actionWasAccepted) {
            return {
              'address': kSelectedAddress,
              'nodeUrl': kCurrentNode,
              'chainId': getChainIdentifier(),
            };
          } else {
            throw Errors.getSdkError(Errors.USER_REJECTED);
          }
        } else {
          throw _walletLockedError;
        }
      },
    );

    _wcClient.onAuthRequest.subscribe((AuthRequest? args) async {
      Logger('WalletConnectService')
          .log(Level.INFO, 'onAuthRequest triggered', args.toString());
    });

    _wcClient.registerRequestHandler(
      chainId: 'zenon:3',
      method: 'znn_sign',
      handler: (topic, params) async {
        final dAppMetadata = _dAppsProposalData
            .firstWhere((element) => element.topic == topic)
            .session.peer.metadata;
        if (kCurrentPage != Tabs.lock) {
          final message = params as String;

          final actionWasAccepted = await showDialogWithNoAndYesOptions(
            context: _context,
            title: '${dAppMetadata.name} - Sign Message',
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text('Are you sure you want to '
                    'sign message $message ?'),
                kVerticalSpacing,
                Image(
                  image: NetworkImage(dAppMetadata.icons.first),
                  height: 100.0,
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
                    )
                  ],
                ),
              ],
            ),
            onYesButtonPressed: () async {
              Navigator.pop(_context, true);
            },
            onNoButtonPressed: () {
              Navigator.pop(_context, false);
            },
          );

          if (actionWasAccepted) {
            return await walletSign(message.codeUnits);
          } else {
            throw Errors.getSdkError(Errors.USER_REJECTED);
          }
        } else {
          throw _walletLockedError;
        }
      },
    );

    _wcClient.registerRequestHandler(
      chainId: 'zenon:3',
      method: 'znn_send',
      handler: (topic, params) async {
        final dAppMetadata = _dAppsProposalData
            .firstWhere((element) => element.topic == topic)
            .session.peer.metadata;
        if (kCurrentPage != Tabs.lock) {
          final accountBlock =
              AccountBlockTemplate.fromJson(params['accountBlock']);

          final toAddress = ZenonAddressUtils.getLabel(
            accountBlock.toAddress.toString(),
          );
          final token = kDualCoin.firstWhere(
            (element) => element.tokenStandard == accountBlock.tokenStandard,
          );
          final amount =
              AmountUtils.addDecimals(accountBlock.amount, token.decimals);

          final sendPaymentBloc = SendPaymentBloc();

          final wasActionAccepted = await showDialogWithNoAndYesOptions(
            context: _context,
            title: '${dAppMetadata.name} - Send Payment',
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text('Are you sure you want to transfer '
                    '$amount ${token.symbol} to '
                    '$toAddress ?'),
                kVerticalSpacing,
                Image(
                  image: NetworkImage(dAppMetadata.icons.first),
                  height: 100.0,
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
                    )
                  ],
                ),
              ],
            ),
            description: 'Are you sure you want to transfer '
                '$amount ${token.symbol} to '
                '$toAddress ?',
            onYesButtonPressed: () {
              Navigator.pop(_context, true);
            },
            onNoButtonPressed: () {
              Navigator.pop(_context, false);
            },
          );

          if (wasActionAccepted) {
            sendPaymentBloc.sendTransfer(
              fromAddress: params['fromAddress'],
              block: AccountBlockTemplate.fromJson(params['accountBlock']),
            );

            final result = await sendPaymentBloc.stream.firstWhere(
              (element) => element != null,
            );

            return result!;
          } else {
            throw Errors.getSdkError(Errors.USER_REJECTED);
          }
        } else {
          throw _walletLockedError;
        }
      },
    );
  }

  IPairingStore getPairings() => _wcClient.pairings;

  Future<ApproveResponse> approveSession(
      {required int id, Map<String, Namespace>? namespaces}) {
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
          )
        };
    return _wcClient.approveSession(
      id: id,
      namespaces: namespaces,
    );
  }

  Future<void> rejectSession({
    required int id,
    required WalletConnectError reason,
  }) =>
      _wcClient.rejectSession(id: id, reason: reason);

  String _generateAccount(String address, int chainId) =>
      '$kZenonNameSpace:$chainId:$address';

  List<String> _getWalletAccounts() => kAddressLabelMap.values
      .map(
        (address) => _generateAccount(address, 3),
      )
      .toList();

  Future<void> activatePairing({
    required String topic,
  }) =>
      _wcClient.core.pairing.activate(
        topic: topic,
      );

  Future<void> deactivatePairing({
    required String topic,
  }) =>
      _wcClient.core.pairing.disconnect(topic: topic);

  Future<void> _emitEventForTheDApp({
    required String sessionTopic,
    required String changeName,
    required String newValue,
  }) async {
    return await _wcClient.emitSessionEvent(
      topic: sessionTopic,
      chainId: 'zenon:3',
      event: SessionEventParams(
        name: changeName,
        data: newValue,
      ),
    );
  }

  Future<void> emitAddressChangeEvent(String newAddress) =>
      _emitEventForTheDApp(
        sessionTopic: _sessionTopic!,
        changeName: 'addressChange',
        newValue: newAddress,
      );

  Future<void> emitChainIdChangeEvent(String newChainId) =>
      _emitEventForTheDApp(
        sessionTopic: _sessionTopic!,
        changeName: 'chainIdChange',
        newValue: newChainId,
      );

  Map<String, SessionData> getActiveSessions() => _wcClient.getActiveSessions();

  Map<String, SessionData> getAllSessions(String pairingTopic) =>
      _wcClient.getSessionsForPairing(
        pairingTopic: pairingTopic,
      );

  void _sendSuccessfullyApprovedSessionNotification(PairingMetadata dAppMetadata) {
    sl.get<NotificationsBloc>().addNotification(
          WalletNotification(
            title: 'Successfully connected with ${dAppMetadata.name}',
            timestamp: DateTime.now().millisecondsSinceEpoch,
            details: 'Successfully connected with ${dAppMetadata.name} '
                'via WalletConnect',
            type: NotificationType.paymentSent,
          ),
        );
  }
}
