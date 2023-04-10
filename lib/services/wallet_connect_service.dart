import 'package:flutter/material.dart';
import 'package:walletconnect_flutter_v2/walletconnect_flutter_v2.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class WalletConnectService {
  WalletConnectService._internal();

  factory WalletConnectService() => _instance;

  static final WalletConnectService _instance =
      WalletConnectService._internal();

  late Web3Wallet _wcClient;
  int? _sessionProposalId;

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

  Future<void> signMessage(String message) {
    // TODO: implement signMessage
    throw UnimplementedError();
  }

  void _initListeners() {
    _wcClient.onSessionProposal.subscribe((SessionProposalEvent? event) async {
      debugPrint('WalletConnectService: onSessionProposal triggered');
      _sessionProposalId = event?.id;
      if (event != null) {
        debugPrint('Session proposal event: ${event.params.toJson()}');
        ApproveResponse approveResponse = await _wcClient.approveSession(
          id: event.id,
          namespaces: {
            'zenon': Namespace(
              accounts: _getWalletAccounts(),
              methods: event.params.optionalNamespaces['zenon']?.methods ??
                  ['znn_sign'],
              events: event.params.optionalNamespaces['zenon']?.events ?? [],
            )
          },
        );
      }
    });

    _wcClient.onSessionRequest.subscribe((SessionRequestEvent? request) async {
      debugPrint('WalletConnectService: onSessionProposal triggered');

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
  }

  IPairingStore getPairings() => _wcClient.pairings;

  Future<ApproveResponse> approveSession(
      {required int id, Map<String, Namespace>? namespaces}) {
    namespaces = namespaces ??
        {
          'zenon': Namespace(
            accounts: _getWalletAccounts(),
            methods: ['znn_sign'],
            events: [],
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
}
