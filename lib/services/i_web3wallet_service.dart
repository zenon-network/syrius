import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:walletconnect_flutter_v2/walletconnect_flutter_v2.dart';

abstract class IWeb3WalletService extends Disposable {
  abstract ValueNotifier<List<PairingInfo>> pairings;
  abstract ValueNotifier<List<SessionData>> sessions;
  abstract ValueNotifier<List<StoredCacao>> auth;

  void create();
  Future<void> init();
  Web3Wallet getWeb3Wallet();
  Future<PairingInfo> pair(Uri uri);
  Future<void> activatePairing({
    required String topic,
  });
  Future<void> deactivatePairing({
    required String topic,
  });
  Map<String, SessionData> getSessionsForPairing(String pairingTopic);
  Map<String, SessionData> getActiveSessions();
  Future<void> disconnectSessions();
  Future<void> disconnectSession({required String topic});
  Future<void> emitAddressChangeEvent(String newAddress);
  Future<void> emitChainIdChangeEvent(String newChainId);
}
