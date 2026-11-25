part of 'settings_wallet_options_bloc.dart';

/// State managed by [SettingsWalletOptionsBloc].
class SettingsWalletOptionsState extends Equatable {
  /// Creates a [SettingsWalletOptionsState].
  const SettingsWalletOptionsState({
    required this.launchAtStartup,
    required this.enableDesktopNotifications,
    required this.enableClipboardWatcher,
    required this.autoReceive,
  });

  /// Whether the wallet launches automatically on OS startup.
  final bool launchAtStartup;

  /// Whether desktop OS notifications are enabled.
  final bool enableDesktopNotifications;

  /// Whether the WalletConnect clipboard watcher is enabled.
  final bool enableClipboardWatcher;

  /// Whether incoming transactions are automatically received.
  final bool autoReceive;

  /// Returns a copy of this state with updated fields.
  SettingsWalletOptionsState copyWith({
    bool? launchAtStartup,
    bool? enableDesktopNotifications,
    bool? enableClipboardWatcher,
    bool? autoReceive,
  }) {
    return SettingsWalletOptionsState(
      launchAtStartup: launchAtStartup ?? this.launchAtStartup,
      enableDesktopNotifications:
          enableDesktopNotifications ?? this.enableDesktopNotifications,
      enableClipboardWatcher:
          enableClipboardWatcher ?? this.enableClipboardWatcher,
      autoReceive: autoReceive ?? this.autoReceive,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    launchAtStartup,
    enableDesktopNotifications,
    enableClipboardWatcher,
    autoReceive,
  ];
}
