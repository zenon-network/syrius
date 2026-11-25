part of 'settings_security_bloc.dart';

/// State managed by [SettingsSecurityBloc].
class SettingsSecurityState extends Equatable {
  /// Creates a [SettingsSecurityState].
  const SettingsSecurityState({
    required this.autoLockMinutes,
    required this.autoEraseAttempts,
    this.isConfirmingAutoLock = false,
    this.isConfirmingAutoErase = false,
    this.isSigningMessage = false,
    this.isVerifyingMessage = false,
    this.isSigningFile = false,
    this.isVerifyingFile = false,
    this.signedMessageSignature = '',
    this.signedMessagePublicKey = '',
    this.signedFileHash = '',
    this.signedFilePublicKey = '',
    this.autoLockConfirmedNonce = 0,
    this.messageVerifiedNonce = 0,
    this.fileSignedNonce = 0,
    this.fileVerifiedNonce = 0,
  });

  /// Selected wallet auto-lock timeout in minutes.
  final int autoLockMinutes;

  /// Selected failed password attempts threshold before auto-erase.
  final double autoEraseAttempts;

  /// Whether auto-lock persistence is in progress.
  final bool isConfirmingAutoLock;

  /// Whether auto-erase persistence is in progress.
  final bool isConfirmingAutoErase;

  /// Whether message signing is in progress.
  final bool isSigningMessage;

  /// Whether message verification is in progress.
  final bool isVerifyingMessage;

  /// Whether file signing is in progress.
  final bool isSigningFile;

  /// Whether file verification is in progress.
  final bool isVerifyingFile;

  /// Latest generated message signature hex string.
  final String signedMessageSignature;

  /// Public key corresponding to [signedMessageSignature].
  final String signedMessagePublicKey;

  /// Latest generated signed file hash hex string.
  final String signedFileHash;

  /// Public key corresponding to [signedFileHash].
  final String signedFilePublicKey;

  /// Incremented whenever the auto-lock interval is saved successfully.
  final int autoLockConfirmedNonce;

  /// Incremented whenever a message is verified successfully.
  final int messageVerifiedNonce;

  /// Incremented whenever a file is signed successfully.
  final int fileSignedNonce;

  /// Incremented whenever a file is verified successfully.
  final int fileVerifiedNonce;

  /// Returns a copy of this state with updated fields.
  SettingsSecurityState copyWith({
    int? autoLockMinutes,
    double? autoEraseAttempts,
    bool? isConfirmingAutoLock,
    bool? isConfirmingAutoErase,
    bool? isSigningMessage,
    bool? isVerifyingMessage,
    bool? isSigningFile,
    bool? isVerifyingFile,
    String? signedMessageSignature,
    String? signedMessagePublicKey,
    String? signedFileHash,
    String? signedFilePublicKey,
    int? autoLockConfirmedNonce,
    int? messageVerifiedNonce,
    int? fileSignedNonce,
    int? fileVerifiedNonce,
  }) {
    return SettingsSecurityState(
      autoLockMinutes: autoLockMinutes ?? this.autoLockMinutes,
      autoEraseAttempts: autoEraseAttempts ?? this.autoEraseAttempts,
      isConfirmingAutoLock: isConfirmingAutoLock ?? this.isConfirmingAutoLock,
      isConfirmingAutoErase:
          isConfirmingAutoErase ?? this.isConfirmingAutoErase,
      isSigningMessage: isSigningMessage ?? this.isSigningMessage,
      isVerifyingMessage: isVerifyingMessage ?? this.isVerifyingMessage,
      isSigningFile: isSigningFile ?? this.isSigningFile,
      isVerifyingFile: isVerifyingFile ?? this.isVerifyingFile,
      signedMessageSignature:
          signedMessageSignature ?? this.signedMessageSignature,
      signedMessagePublicKey:
          signedMessagePublicKey ?? this.signedMessagePublicKey,
      signedFileHash: signedFileHash ?? this.signedFileHash,
      signedFilePublicKey: signedFilePublicKey ?? this.signedFilePublicKey,
      autoLockConfirmedNonce:
          autoLockConfirmedNonce ?? this.autoLockConfirmedNonce,
      messageVerifiedNonce: messageVerifiedNonce ?? this.messageVerifiedNonce,
      fileSignedNonce: fileSignedNonce ?? this.fileSignedNonce,
      fileVerifiedNonce: fileVerifiedNonce ?? this.fileVerifiedNonce,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    autoLockMinutes,
    autoEraseAttempts,
    isConfirmingAutoLock,
    isConfirmingAutoErase,
    isSigningMessage,
    isVerifyingMessage,
    isSigningFile,
    isVerifyingFile,
    signedMessageSignature,
    signedMessagePublicKey,
    signedFileHash,
    signedFilePublicKey,
    autoLockConfirmedNonce,
    messageVerifiedNonce,
    fileSignedNonce,
    fileVerifiedNonce,
  ];
}
