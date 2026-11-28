import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/notifications/notifications.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/services/shared_prefs_service.dart';
import 'package:zenon_syrius_wallet_flutter/utils/functions.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'settings_security_event.dart';
part 'settings_security_state.dart';

/// Manages wallet security settings, message signing/verification, and
/// file signing/verification in the Settings Security card.
class SettingsSecurityBloc
    extends Bloc<SettingsSecurityEvent, SettingsSecurityState> {
  /// Creates a [SettingsSecurityBloc].
  SettingsSecurityBloc({
    int? initialAutoLockMinutes,
    double? initialAutoEraseAttempts,
    this._prefsService,
    Future<Signature> Function(List<int> message)? signBytes,
    Future<bool> Function(
      List<int> signature,
      List<int> message,
      List<int> publicKey,
    )?
    verifySignature,
    Future<Uint8List> Function(String filePath)? readFileBytes,
    this._addNotification,
    this._reportError,
  }) : _signBytes = signBytes ?? walletSign,
       _verifySignature = verifySignature ?? Crypto.verify,
       _readFileBytes = readFileBytes ?? _defaultReadFileBytes,
       _committedAutoLockMinutes =
           initialAutoLockMinutes ??
           kAutoLockWalletMinutes ??
           kAutoLockWalletDefaultIntervalMinutes,
       _committedAutoEraseAttempts =
           initialAutoEraseAttempts ??
           (kAutoEraseWalletEnabled == false
               ? 0.0
               : (kAutoEraseWalletLimit ?? kAutoEraseNumAttemptsDefault)),
       super(
         SettingsSecurityState(
           autoLockMinutes:
               initialAutoLockMinutes ??
               kAutoLockWalletMinutes ??
               kAutoLockWalletDefaultIntervalMinutes,
           autoEraseAttempts:
               initialAutoEraseAttempts ??
               (kAutoEraseWalletEnabled == false
                   ? 0.0
                   : (kAutoEraseWalletLimit ?? kAutoEraseNumAttemptsDefault)),
         ),
       ) {
    on<SettingsSecurityAutoLockChanged>(_onAutoLockChanged);
    on<SettingsSecurityAutoLockConfirmed>(
      _onAutoLockConfirmed,
      transformer: sequential(),
    );
    on<SettingsSecurityAutoEraseChanged>(_onAutoEraseChanged);
    on<SettingsSecurityAutoEraseConfirmed>(
      _onAutoEraseConfirmed,
      transformer: sequential(),
    );
    on<SettingsSecuritySignMessageRequested>(_onSignMessageRequested);
    on<SettingsSecurityVerifyMessageRequested>(_onVerifyMessageRequested);
    on<SettingsSecuritySignFileRequested>(_onSignFileRequested);
    on<SettingsSecurityVerifyFileRequested>(_onVerifyFileRequested);
  }

  int _committedAutoLockMinutes;
  double _committedAutoEraseAttempts;

  final SharedPrefsService? _prefsService;
  final Future<Signature> Function(List<int> message) _signBytes;
  final Future<bool> Function(
    List<int> signature,
    List<int> message,
    List<int> publicKey,
  )
  _verifySignature;
  final Future<Uint8List> Function(String filePath) _readFileBytes;
  final Future<void> Function(WalletNotification notification)?
  _addNotification;
  final Future<void> Function(Object error, String title)? _reportError;

  SharedPrefsService get _prefs => _prefsService ?? sharedPrefsService!;

  static Future<Uint8List> _defaultReadFileBytes(String filePath) =>
      File(filePath).readAsBytes();

  void _onAutoLockChanged(
    SettingsSecurityAutoLockChanged event,
    Emitter<SettingsSecurityState> emit,
  ) {
    emit(state.copyWith(autoLockMinutes: event.minutes));
  }

  FutureOr<void> _onAutoLockConfirmed(
    SettingsSecurityAutoLockConfirmed event,
    Emitter<SettingsSecurityState> emit,
  ) async {
    final int minutesToSave = state.autoLockMinutes;
    emit(state.copyWith(isConfirmingAutoLock: true));
    try {
      await _prefs.put(kAutoLockWalletMinutesKey, minutesToSave);
      kAutoLockWalletMinutes = minutesToSave;
      _committedAutoLockMinutes = minutesToSave;
      emit(
        state.copyWith(
          isConfirmingAutoLock: false,
          autoLockConfirmedNonce: state.autoLockConfirmedNonce + 1,
        ),
      );
    } on Object catch (error, stackTrace) {
      addError(error, stackTrace);
      emit(
        state.copyWith(
          autoLockMinutes: _committedAutoLockMinutes,
          isConfirmingAutoLock: false,
        ),
      );
      await _sendError(error, event.errorTitle);
    }
  }

  void _onAutoEraseChanged(
    SettingsSecurityAutoEraseChanged event,
    Emitter<SettingsSecurityState> emit,
  ) {
    emit(state.copyWith(autoEraseAttempts: event.attempts));
  }

  FutureOr<void> _onAutoEraseConfirmed(
    SettingsSecurityAutoEraseConfirmed event,
    Emitter<SettingsSecurityState> emit,
  ) async {
    final double attemptsToSave = state.autoEraseAttempts;
    final bool enabledToSave = attemptsToSave > 0;
    // Never persist 0 to the legacy numeric threshold key so older releases
    // cannot interpret "Off" as an immediate-erase threshold on downgrade.
    final double legacyThreshold = enabledToSave
        ? attemptsToSave
        : ((kAutoEraseWalletLimit != null && kAutoEraseWalletLimit! > 0)
              ? kAutoEraseWalletLimit!
              : kAutoEraseNumAttemptsDefault);
    emit(state.copyWith(isConfirmingAutoErase: true));
    try {
      await _prefs.put(kAutoEraseNumAttemptsKey, legacyThreshold);
      await _prefs.put(kAutoEraseEnabledKey, enabledToSave);
      kAutoEraseWalletLimit = legacyThreshold;
      kAutoEraseWalletEnabled = enabledToSave;
      _committedAutoEraseAttempts = enabledToSave ? attemptsToSave : 0.0;
    } on Object catch (error, stackTrace) {
      addError(error, stackTrace);
      emit(
        state.copyWith(
          autoEraseAttempts: _committedAutoEraseAttempts,
          isConfirmingAutoErase: false,
        ),
      );
      await _sendError(error, event.errorTitle);
      return;
    }
    emit(state.copyWith(isConfirmingAutoErase: false));
    try {
      await _sendNotification(
        WalletNotification(
          title: event.notificationTitle,
          details: event.notificationDetails,
          timestamp: DateTime.now().millisecondsSinceEpoch,
          type: NotificationType.autoEraseNumAttemptsChanged,
        ),
      );
    } on Object catch (error, stackTrace) {
      addError(error, stackTrace);
      await _sendError(error, event.errorTitle);
    }
  }

  FutureOr<void> _onSignMessageRequested(
    SettingsSecuritySignMessageRequested event,
    Emitter<SettingsSecurityState> emit,
  ) async {
    emit(state.copyWith(isSigningMessage: true));
    try {
      final Signature signature = await _signBytes(event.message.codeUnits);
      emit(
        state.copyWith(
          isSigningMessage: false,
          signedMessageSignature: signature.signature,
          signedMessagePublicKey: signature.publicKey,
        ),
      );
    } on Object catch (error, stackTrace) {
      addError(error, stackTrace);
      emit(state.copyWith(isSigningMessage: false));
      await _sendError(error, event.errorTitle);
    }
  }

  FutureOr<void> _onVerifyMessageRequested(
    SettingsSecurityVerifyMessageRequested event,
    Emitter<SettingsSecurityState> emit,
  ) async {
    emit(state.copyWith(isVerifyingMessage: true));
    try {
      final bool verified = await _verifySignature(
        FormatUtils.decodeHexString(event.signature),
        Uint8List.fromList(event.message.codeUnits),
        FormatUtils.decodeHexString(event.publicKey),
      );
      if (!verified) {
        throw SyriusException(event.invalidMessage);
      }
      await _sendNotification(
        WalletNotification(
          title: event.successTitle,
          timestamp: DateTime.now().millisecondsSinceEpoch,
          details: event.successDetails,
          type: NotificationType.paymentSent,
        ),
      );
      emit(
        state.copyWith(
          isVerifyingMessage: false,
          messageVerifiedNonce: state.messageVerifiedNonce + 1,
        ),
      );
    } on Object catch (error, stackTrace) {
      addError(error, stackTrace);
      emit(state.copyWith(isVerifyingMessage: false));
      await _sendError(error, event.errorTitle);
    }
  }

  FutureOr<void> _onSignFileRequested(
    SettingsSecuritySignFileRequested event,
    Emitter<SettingsSecurityState> emit,
  ) async {
    emit(state.copyWith(isSigningFile: true));
    try {
      final Uint8List fileBytes = await _readFileBytes(event.filePath);
      final Signature fileSignature = await _signBytes(
        Crypto.digest(fileBytes),
      );
      emit(
        state.copyWith(
          isSigningFile: false,
          signedFileHash: fileSignature.signature,
          signedFilePublicKey: fileSignature.publicKey,
          fileSignedNonce: state.fileSignedNonce + 1,
        ),
      );
    } on Object catch (error, stackTrace) {
      addError(error, stackTrace);
      emit(state.copyWith(isSigningFile: false));
      await _sendError(error, event.errorTitle);
    }
  }

  FutureOr<void> _onVerifyFileRequested(
    SettingsSecurityVerifyFileRequested event,
    Emitter<SettingsSecurityState> emit,
  ) async {
    emit(state.copyWith(isVerifyingFile: true));
    try {
      final Uint8List fileBytes = await _readFileBytes(event.filePath);
      final bool verified = await _verifySignature(
        FormatUtils.decodeHexString(event.signedHash),
        Uint8List.fromList(Crypto.digest(fileBytes)),
        FormatUtils.decodeHexString(event.publicKey),
      );
      if (!verified) {
        throw SyriusException(event.invalidMessage);
      }
      await _sendNotification(
        WalletNotification(
          title: event.successTitle,
          timestamp: DateTime.now().millisecondsSinceEpoch,
          details: event.successDetails,
          type: NotificationType.paymentSent,
        ),
      );
      emit(
        state.copyWith(
          isVerifyingFile: false,
          fileVerifiedNonce: state.fileVerifiedNonce + 1,
        ),
      );
    } on Object catch (error, stackTrace) {
      addError(error, stackTrace);
      emit(state.copyWith(isVerifyingFile: false));
      await _sendError(error, event.errorTitle);
    }
  }

  Future<void> _sendNotification(WalletNotification notification) async {
    if (_addNotification != null) {
      await _addNotification(notification);
      return;
    }
    await sl.get<NotificationsBloc>().addNotification(notification);
  }

  Future<void> _sendError(Object error, String title) async {
    if (_reportError != null) {
      await _reportError(error, title);
      return;
    }
    await NotificationUtils.sendNotificationError(error, title);
  }
}
