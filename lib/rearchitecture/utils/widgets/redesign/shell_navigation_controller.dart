import 'package:flutter/foundation.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// Active sub-mode inside the redesigned Transfer screen (Screens 07–11).
enum TransferMode {
  /// Standard ZNN/QSR/ZTS send form.
  send,

  /// Address display and optional QR request form.
  receive,

  /// Send a Zap with optional message.
  zap,
}

/// Target section inside the redesigned split-pane Settings screen
/// (Screens 30–38).
enum SettingsSection {
  /// Wallet addresses, contacts, and account chain stats.
  addresses,

  /// Nodes list, embedded node status, chain ID, peers, sporks.
  node,

  /// Auto-lock, auto-erase, password, backup, sign/verify, remove wallet.
  security,

  /// Theme, text size, language, menu rail, hide balances, explorer.
  display,

  /// Auto-receive, desktop notifications, startup, modes, cache, wallets.
  wallet,

  /// Web apps and WalletConnect sessions/pairings.
  apps,

  /// App version, links, this computer, licences, and Originals gallery.
  about,
}

/// Optional transfer navigation payload (e.g. jump straight to Zap or
/// pre-fill a recipient address from Home / Contacts / Ctrl+K).
class TransferNavigationRequest {
  /// Creates a [TransferNavigationRequest].
  const TransferNavigationRequest({
    required this.mode,
    this.recipientAddress,
    this.token,
    this.nonce = 0,
  });

  /// Target transfer mode.
  final TransferMode mode;

  /// Optional address to pre-fill in the recipient field.
  final String? recipientAddress;

  /// Optional token to pre-select in the Send form.
  final Token? token;

  /// Monotonic counter so repeated requests with identical fields still fire.
  final int nonce;
}

/// Shared navigation intent controller linking Home, Shell, Transfer, and
/// Settings without tight coupling.
class ShellNavigationController {
  /// Pending transfer sub-mode and optional recipient.
  final ValueNotifier<TransferNavigationRequest> transferRequest =
      ValueNotifier<TransferNavigationRequest>(
        const TransferNavigationRequest(mode: TransferMode.send),
      );

  /// Active settings sub-section.
  final ValueNotifier<SettingsSection> settingsSection =
      ValueNotifier<SettingsSection>(SettingsSection.addresses);

  int _nonce = 0;

  /// Requests switching the Transfer tab to [mode] with an optional
  /// [recipientAddress] and [token].
  void requestTransfer({
    required TransferMode mode,
    String? recipientAddress,
    Token? token,
  }) {
    _nonce += 1;
    transferRequest.value = TransferNavigationRequest(
      mode: mode,
      recipientAddress: recipientAddress,
      token: token,
      nonce: _nonce,
    );
  }

  /// Requests switching the Settings tab to [section].
  void requestSettingsSection(SettingsSection section) {
    if (settingsSection.value == section) {
      return;
    }
    settingsSection.value = section;
  }

  /// Disposes internal notifiers.
  void dispose() {
    transferRequest.dispose();
    settingsSection.dispose();
  }
}
