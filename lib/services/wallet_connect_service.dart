import 'package:flutter/material.dart';
import 'package:walletconnect_flutter_v2/walletconnect_flutter_v2.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class WalletConnectService {

  WalletConnectService._internal();

  factory WalletConnectService() => _instance;

  static final WalletConnectService _instance = WalletConnectService._internal();

  late Web3Wallet _wcClient;
  int? _sessionProposalId;

  Future<void> initClient() async {
    _wcClient = await Web3Wallet.createInstance(
      core: Core(
        relayUrl: 'wss://relay.walletconnect.com', // The relay websocket URL
        projectId: kWcProjectId,
      ),
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

  Future<PairingInfo> pair(Uri uri) async => await _wcClient.pair(uri: uri);

  Future<void> sendTx(String fromAddress, AccountBlockTemplate accountBlockTemplate) {
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
    });

    _wcClient.onAuthRequest.subscribe((AuthRequest? args) async {
      debugPrint('WalletConnectService: onAuthRequest triggered');
    });
  }
}
