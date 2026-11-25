part of 'settings_wallet_options_bloc.dart';

/// Base class for [SettingsWalletOptionsBloc] events.
sealed class SettingsWalletOptionsEvent extends Equatable {
  /// Creates a [SettingsWalletOptionsEvent].
  const SettingsWalletOptionsEvent();

  @override
  List<Object?> get props => <Object?>[];
}

/// Toggles launch-at-startup preference.
final class SettingsWalletOptionsLaunchAtStartupToggled
    extends SettingsWalletOptionsEvent {
  /// Creates a [SettingsWalletOptionsLaunchAtStartupToggled] event.
  const SettingsWalletOptionsLaunchAtStartupToggled({
    required this.enabled,
    required this.notificationTitle,
    required this.notificationDetails,
    required this.errorTitle,
  });

  /// Desired preference value.
  final bool enabled;

  /// Localized notification title on success.
  final String notificationTitle;

  /// Localized notification details on success.
  final String notificationDetails;

  /// Localized error title on failure.
  final String errorTitle;

  @override
  List<Object?> get props => <Object?>[
    enabled,
    notificationTitle,
    notificationDetails,
    errorTitle,
  ];
}

/// Toggles desktop notifications preference.
final class SettingsWalletOptionsDesktopNotificationsToggled
    extends SettingsWalletOptionsEvent {
  /// Creates a [SettingsWalletOptionsDesktopNotificationsToggled] event.
  const SettingsWalletOptionsDesktopNotificationsToggled({
    required this.enabled,
    required this.notificationTitle,
    required this.notificationDetails,
    required this.errorTitle,
  });

  /// Desired preference value.
  final bool enabled;

  /// Localized notification title on success.
  final String notificationTitle;

  /// Localized notification details on success.
  final String notificationDetails;

  /// Localized error title on failure.
  final String errorTitle;

  @override
  List<Object?> get props => <Object?>[
    enabled,
    notificationTitle,
    notificationDetails,
    errorTitle,
  ];
}

/// Toggles clipboard watcher preference.
final class SettingsWalletOptionsClipboardWatcherToggled
    extends SettingsWalletOptionsEvent {
  /// Creates a [SettingsWalletOptionsClipboardWatcherToggled] event.
  const SettingsWalletOptionsClipboardWatcherToggled({
    required this.enabled,
    required this.notificationTitle,
    required this.notificationDetails,
    required this.errorTitle,
  });

  /// Desired preference value.
  final bool enabled;

  /// Localized notification title on success.
  final String notificationTitle;

  /// Localized notification details on success.
  final String notificationDetails;

  /// Localized error title on failure.
  final String errorTitle;

  @override
  List<Object?> get props => <Object?>[
    enabled,
    notificationTitle,
    notificationDetails,
    errorTitle,
  ];
}

/// Toggles auto-receiver preference.
final class SettingsWalletOptionsAutoReceiveToggled
    extends SettingsWalletOptionsEvent {
  /// Creates a [SettingsWalletOptionsAutoReceiveToggled] event.
  const SettingsWalletOptionsAutoReceiveToggled({
    required this.enabled,
    required this.notificationTitle,
    required this.notificationDetails,
    required this.errorTitle,
  });

  /// Desired preference value.
  final bool enabled;

  /// Localized notification title on success.
  final String notificationTitle;

  /// Localized notification details on success.
  final String notificationDetails;

  /// Localized error title on failure.
  final String errorTitle;

  @override
  List<Object?> get props => <Object?>[
    enabled,
    notificationTitle,
    notificationDetails,
    errorTitle,
  ];
}
