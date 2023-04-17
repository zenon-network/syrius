import 'package:flutter/material.dart';
import 'package:walletconnect_flutter_v2/walletconnect_flutter_v2.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/utils/functions.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/main_app_container.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/dialogs.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class WalletConnectService {
  WalletConnectService._internal();

  factory WalletConnectService() => _instance;

  static final WalletConnectService _instance =
      WalletConnectService._internal();

  late Web3Wallet _wcClient;
  late BuildContext _context;
  int? _sessionProposalId;
  String? _sessionTopic;

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
        description: 'A wallet for interacting with the Zenon network',
        url: 'https://zenon.network',
        // TODO: add Zenon icon
        icons: ['https://avatars.githubusercontent.com/u/37784886'],
      ),
    );
    _initListeners();
  }

  Future<PairingInfo> pair(Uri uri) => _wcClient.pair(uri: uri);

  Future<void> sendTx(
      String fromAddress, AccountBlockTemplate accountBlockTemplate) {
    // TODO: implement sendTx
    throw UnimplementedError();
  }

  void _initListeners() {
    _wcClient.onSessionProposal.subscribe((SessionProposalEvent? event) async {
      debugPrint('WalletConnectService: onSessionProposal triggered - $event');
      _sessionProposalId = event?.id;
      if (event != null) {
        debugPrint('Session proposal event: ${event.params.toJson()}');
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

        _sessionTopic = approveResponse.session.topic;
      }
    });

    _wcClient.onSessionRequest.subscribe((SessionRequestEvent? request) async {
      debugPrint('WalletConnectService: onSessionRequest triggered - $request');

      // await _wcClient.respondSessionRequest(
      //   topic: request.topic,
      //   response: JsonRpcResponse<String>(
      //     id: request.id,
      //     result: 'Signed!',
      //   ),
      // );
    });

    _wcClient.onAuthRequest.subscribe((AuthRequest? args) async {
      debugPrint('WalletConnectService: onAuthRequest triggered');
    });

    _wcClient.registerRequestHandler(
      chainId: 'zenon:3',
      method: 'znn_info',
      handler: (topic, params) async {
        if (kCurrentPage != Tabs.lock) {
          final actionWasAccepted = await showDialogWithNoAndYesOptions(
            context: _context,
            title: 'Send Payment',
            description: 'Are you sure you want to '
                'send address, current node and chain ID info ?',
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

    _wcClient.registerRequestHandler(
      chainId: 'zenon:3',
      method: 'znn_sign',
      handler: (topic, params) async {
        if (kCurrentPage != Tabs.lock) {
          final message = params as String;

          final actionWasAccepted = await showDialogWithNoAndYesOptions(
            context: _context,
            title: 'Send Payment',
            description: 'Are you sure you want to '
                'sign message $message ?',
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
            title: 'Send Payment',
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
}
