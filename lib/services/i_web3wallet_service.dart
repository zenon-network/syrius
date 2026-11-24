import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:reown_walletkit/reown_walletkit.dart';

/// Contract for the desktop WalletConnect v2 service.
abstract class IWeb3WalletService extends Disposable {
  /// Currently known WalletConnect pairings.
  abstract ValueNotifier<List<PairingInfo>> pairings;

  /// Currently active WalletConnect sessions.
  abstract ValueNotifier<List<SessionData>> sessions;

  /// Creates the underlying WalletConnect client and subscribes to events.
  void create();

  /// Initializes the WalletConnect client and syncs stored pairings/sessions.
  Future<void> init();

  /// Registers all unlocked wallet addresses for the active Zenon chain ID.
  void registerAccountsIfNeeded();

  /// Returns the underlying [ReownWalletKit] instance.
  ReownWalletKit getWeb3Wallet();

  /// Initiates a WalletConnect pairing with the given [uri].
  Future<PairingInfo> pair(Uri uri);

  /// Activates an existing pairing by [topic].
  Future<void> activatePairing({
    required String topic,
  });

  /// Disconnects and deactivates a pairing by [topic].
  Future<void> deactivatePairing({
    required String topic,
  });

  /// Returns active sessions associated with [pairingTopic].
  Map<String, SessionData> getSessionsForPairing(String pairingTopic);

  /// Returns all active WalletConnect sessions keyed by session topic.
  Map<String, SessionData> getActiveSessions();

  /// Disconnects all active WalletConnect sessions.
  Future<void> disconnectSessions();

  /// Disconnects all WalletConnect pairings.
  Future<void> disconnectAllPairings();

  /// Disconnects all active sessions and pairings.
  Future<void> disconnectEverything();

  /// Disconnects a single WalletConnect session by [topic].
  Future<void> disconnectSession({required String topic});

  /// Emits an `addressChange` session event to all paired dApps.
  Future<void> emitAddressChangeEvent(String newAddress);

  /// Emits a `chainIdChange` session event to all paired dApps.
  Future<void> emitChainIdChangeEvent(String newChainId);
}
