part of 'settings_security_bloc.dart';

/// Base class for [SettingsSecurityBloc] events.
sealed class SettingsSecurityEvent extends Equatable {
  /// Creates a [SettingsSecurityEvent].
  const SettingsSecurityEvent();

  @override
  List<Object?> get props => <Object?>[];
}

/// Updates the pending auto-lock interval in minutes.
final class SettingsSecurityAutoLockChanged extends SettingsSecurityEvent {
  /// Creates a [SettingsSecurityAutoLockChanged] event.
  const SettingsSecurityAutoLockChanged({required this.minutes});

  /// Selected inactivity duration in minutes.
  final int minutes;

  @override
  List<Object?> get props => <Object?>[minutes];
}

/// Persists the selected auto-lock interval.
final class SettingsSecurityAutoLockConfirmed extends SettingsSecurityEvent {
  /// Creates a [SettingsSecurityAutoLockConfirmed] event.
  const SettingsSecurityAutoLockConfirmed({required this.errorTitle});

  /// Localized error title if saving fails.
  final String errorTitle;

  @override
  List<Object?> get props => <Object?>[errorTitle];
}

/// Updates the pending auto-erase failed attempts limit.
final class SettingsSecurityAutoEraseChanged extends SettingsSecurityEvent {
  /// Creates a [SettingsSecurityAutoEraseChanged] event.
  const SettingsSecurityAutoEraseChanged({required this.attempts});

  /// Selected failed-attempt limit.
  final double attempts;

  @override
  List<Object?> get props => <Object?>[attempts];
}

/// Persists the selected auto-erase failed attempts limit.
final class SettingsSecurityAutoEraseConfirmed extends SettingsSecurityEvent {
  /// Creates a [SettingsSecurityAutoEraseConfirmed] event.
  const SettingsSecurityAutoEraseConfirmed({
    required this.notificationTitle,
    required this.notificationDetails,
    required this.errorTitle,
  });

  /// Localized notification title on success.
  final String notificationTitle;

  /// Localized notification details on success.
  final String notificationDetails;

  /// Localized error title if saving fails.
  final String errorTitle;

  @override
  List<Object?> get props => <Object?>[
    notificationTitle,
    notificationDetails,
    errorTitle,
  ];
}

/// Signs [message] using the active wallet address keypair.
final class SettingsSecuritySignMessageRequested extends SettingsSecurityEvent {
  /// Creates a [SettingsSecuritySignMessageRequested] event.
  const SettingsSecuritySignMessageRequested({
    required this.message,
    required this.errorTitle,
  });

  /// Plain text message to sign.
  final String message;

  /// Localized error title on failure.
  final String errorTitle;

  @override
  List<Object?> get props => <Object?>[message, errorTitle];
}

/// Verifies a signed message against [signature] and [publicKey].
final class SettingsSecurityVerifyMessageRequested
    extends SettingsSecurityEvent {
  /// Creates a [SettingsSecurityVerifyMessageRequested] event.
  const SettingsSecurityVerifyMessageRequested({
    required this.message,
    required this.signature,
    required this.publicKey,
    required this.successTitle,
    required this.successDetails,
    required this.invalidMessage,
    required this.errorTitle,
  });

  /// Original plain text message.
  final String message;

  /// Hex-encoded signature string.
  final String signature;

  /// Hex-encoded public key string.
  final String publicKey;

  /// Localized notification title on successful verification.
  final String successTitle;

  /// Localized notification details on successful verification.
  final String successDetails;

  /// Localized error message when signature verification returns false.
  final String invalidMessage;

  /// Localized notification error title when verification fails.
  final String errorTitle;

  @override
  List<Object?> get props => <Object?>[
    message,
    signature,
    publicKey,
    successTitle,
    successDetails,
    invalidMessage,
    errorTitle,
  ];
}

/// Signs the digest of the file located at [filePath].
final class SettingsSecuritySignFileRequested extends SettingsSecurityEvent {
  /// Creates a [SettingsSecuritySignFileRequested] event.
  const SettingsSecuritySignFileRequested({
    required this.filePath,
    required this.errorTitle,
  });

  /// Local filesystem path to the file to sign.
  final String filePath;

  /// Localized error title on failure.
  final String errorTitle;

  @override
  List<Object?> get props => <Object?>[filePath, errorTitle];
}

/// Verifies the digest of the file at [filePath] against [signedHash] and
/// [publicKey].
final class SettingsSecurityVerifyFileRequested extends SettingsSecurityEvent {
  /// Creates a [SettingsSecurityVerifyFileRequested] event.
  const SettingsSecurityVerifyFileRequested({
    required this.filePath,
    required this.signedHash,
    required this.publicKey,
    required this.successTitle,
    required this.successDetails,
    required this.invalidMessage,
    required this.errorTitle,
  });

  /// Local filesystem path to the file to verify.
  final String filePath;

  /// Hex-encoded signed hash.
  final String signedHash;

  /// Hex-encoded public key.
  final String publicKey;

  /// Localized notification title on success.
  final String successTitle;

  /// Localized notification details on success.
  final String successDetails;

  /// Localized error message when verification returns false.
  final String invalidMessage;

  /// Localized notification error title on failure.
  final String errorTitle;

  @override
  List<Object?> get props => <Object?>[
    filePath,
    signedHash,
    publicKey,
    successTitle,
    successDetails,
    invalidMessage,
    errorTitle,
  ];
}
