import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:reown_walletkit/reown_walletkit.dart';

abstract class IWeb3WalletService extends Disposable {
  abstract ValueNotifier<List<PairingInfo>> pairings;
  abstract ValueNotifier<List<SessionData>> sessions;

  void create();
  Future<void> init();
  ReownWalletKit getWeb3Wallet();
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
