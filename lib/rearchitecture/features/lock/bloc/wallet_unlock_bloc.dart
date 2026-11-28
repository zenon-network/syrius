import 'dart:async';
import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/utils/extensions.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:zenon_syrius_wallet_flutter/utils/init_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/notification_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/wallet_file.dart';
import 'package:zenon_syrius_wallet_flutter/utils/wallet_utils.dart';
import 'package:znn_ledger_dart/znn_ledger_dart.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'wallet_unlock_event.dart';
part 'wallet_unlock_state.dart';

/// BLoC handling wallet decryption, first-time initialization, failed-attempt
/// tracking, and auto-erase enforcement on the lock screen.
class WalletUnlockBloc extends Bloc<WalletUnlockEvent, WalletUnlockState> {
  /// Creates a [WalletUnlockBloc].
  WalletUnlockBloc({
    required this._afterUnlockCallback,
    required this._afterInitCallback,
    Future<WalletFile> Function(String walletPath, String password)?
    decryptWallet,
    Future<void> Function(List<int> cipherKey)? initWalletAfterDecryption,
    String? Function()? getWalletPath,
    FutureOr<void> Function(WalletFile walletFile)? setWalletFile,
    bool Function()? isWalletInitCompleted,
    int Function()? getNumFailedAttempts,
    Future<void> Function(int numAttempts)? saveNumFailedAttempts,
    int Function()? getAutoEraseWalletLimit,
    void Function()? onFetchBalances,
    Future<void> Function(Object error, String title)? sendErrorNotification,
  }) : _decryptWallet = decryptWallet ?? WalletUtils.decryptWalletFile,
       _initWalletAfterDecryption =
           initWalletAfterDecryption ?? InitUtils.initWalletAfterDecryption,
       _getWalletPath = getWalletPath ?? _defaultGetWalletPath,
       _setWalletFile = setWalletFile ?? _defaultSetWalletFile,
       _isWalletInitCompleted =
           isWalletInitCompleted ?? _defaultIsWalletInitCompleted,
       _getNumFailedAttempts =
           getNumFailedAttempts ?? _defaultGetNumFailedAttempts,
       _saveNumFailedAttempts =
           saveNumFailedAttempts ?? _defaultSaveNumFailedAttempts,
       _getAutoEraseWalletLimit =
           getAutoEraseWalletLimit ?? _defaultGetAutoEraseWalletLimit,
       _onFetchBalances = onFetchBalances ?? _defaultFetchBalances,
       _sendErrorNotification =
           sendErrorNotification ?? NotificationUtils.sendNotificationError,
       super(
         WalletUnlockState(
           autoEraseEnabled:
               (getAutoEraseWalletLimit ?? _defaultGetAutoEraseWalletLimit)() >
               0,
           remainingAttempts: _computeRemainingAttempts(
             limit:
                 (getAutoEraseWalletLimit ?? _defaultGetAutoEraseWalletLimit)(),
             failedAttempts:
                 (getNumFailedAttempts ?? _defaultGetNumFailedAttempts)(),
           ),
         ),
       ) {
    on<WalletUnlockSubmitted>(_onUnlockSubmitted, transformer: droppable());
  }

  final Future<void> Function(String password) _afterUnlockCallback;
  final void Function() _afterInitCallback;
  final Future<WalletFile> Function(String walletPath, String password)
  _decryptWallet;
  final Future<void> Function(List<int> cipherKey) _initWalletAfterDecryption;
  final String? Function() _getWalletPath;
  final FutureOr<void> Function(WalletFile walletFile) _setWalletFile;
  final bool Function() _isWalletInitCompleted;
  final int Function() _getNumFailedAttempts;
  final Future<void> Function(int numAttempts) _saveNumFailedAttempts;
  final int Function() _getAutoEraseWalletLimit;
  final void Function() _onFetchBalances;
  final Future<void> Function(Object error, String title)
  _sendErrorNotification;

  Future<void> _onUnlockSubmitted(
    WalletUnlockSubmitted event,
    Emitter<WalletUnlockState> emit,
  ) async {
    if (event.password.isEmpty) {
      return;
    }

    final int limit = _getAutoEraseWalletLimit();
    final bool autoEraseEnabled = limit > 0;
    final int currentAttempts = _getNumFailedAttempts();
    final int currentRemaining = _computeRemainingAttempts(
      limit: limit,
      failedAttempts: currentAttempts,
    );

    emit(
      WalletUnlockState(
        status: WalletUnlockStatus.decrypting,
        remainingAttempts: currentRemaining,
        autoEraseEnabled: autoEraseEnabled,
        nonce: state.nonce + 1,
      ),
    );

    try {
      final String? walletPath = _getWalletPath();
      if (walletPath == null) {
        throw StateError('Wallet path is not initialized');
      }

      final WalletFile walletFile = await _decryptWallet(
        walletPath,
        event.password,
      );
      await _setWalletFile(walletFile);

      if (!_isWalletInitCompleted()) {
        emit(
          WalletUnlockState(
            status: WalletUnlockStatus.initializing,
            remainingAttempts: currentRemaining,
            autoEraseEnabled: autoEraseEnabled,
            nonce: state.nonce + 1,
          ),
        );
        await _initWalletAfterDecryption(
          Crypto.digest(utf8.encode(event.password)),
        );
        _onFetchBalances();
        _afterInitCallback();
        await _saveNumFailedAttempts(0);
      } else {
        await _saveNumFailedAttempts(0);
        await _afterUnlockCallback(event.password);
      }

      emit(
        WalletUnlockState(
          status: WalletUnlockStatus.success,
          remainingAttempts: autoEraseEnabled ? limit : 0,
          autoEraseEnabled: autoEraseEnabled,
          nonce: state.nonce + 1,
        ),
      );
    } on IncorrectPasswordException catch (error, stackTrace) {
      addError(error, stackTrace);
      await _safeSendErrorNotification(error, event.incorrectPasswordTitle);
      final int updatedAttempts = currentAttempts + 1;
      try {
        await _saveNumFailedAttempts(updatedAttempts);
      } on Object catch (persistError, persistStackTrace) {
        addError(persistError, persistStackTrace);
      }
      final int remaining = _computeRemainingAttempts(
        limit: limit,
        failedAttempts: updatedAttempts,
      );
      if (autoEraseEnabled && updatedAttempts >= limit) {
        emit(
          WalletUnlockState(
            status: WalletUnlockStatus.autoEraseTriggered,
            remainingAttempts: 0,
            autoEraseEnabled: autoEraseEnabled,
            nonce: state.nonce + 1,
          ),
        );
      } else {
        emit(
          WalletUnlockState(
            status: WalletUnlockStatus.failure,
            remainingAttempts: remaining,
            autoEraseEnabled: autoEraseEnabled,
            nonce: state.nonce + 1,
          ),
        );
      }
    } on LedgerError catch (error, stackTrace) {
      addError(error, stackTrace);
      await _safeSendErrorNotification(
        error,
        event.ledgerErrorTitleBuilder(error.toFriendlyString()),
      );
      emit(
        WalletUnlockState(
          status: WalletUnlockStatus.failure,
          remainingAttempts: currentRemaining,
          autoEraseEnabled: autoEraseEnabled,
          nonce: state.nonce + 1,
        ),
      );
    } on Object catch (error, stackTrace) {
      addError(error, stackTrace);
      await _safeSendErrorNotification(error, event.unlockFailedTitle);
      emit(
        WalletUnlockState(
          status: WalletUnlockStatus.failure,
          remainingAttempts: currentRemaining,
          autoEraseEnabled: autoEraseEnabled,
          nonce: state.nonce + 1,
        ),
      );
    }
  }

  Future<void> _safeSendErrorNotification(Object error, String title) async {
    try {
      await _sendErrorNotification(error, title);
    } on Object catch (notificationError, stackTrace) {
      addError(notificationError, stackTrace);
    }
  }

  static int _computeRemainingAttempts({
    required int limit,
    required int failedAttempts,
  }) {
    if (limit <= 0) {
      return 0;
    }
    final int remaining = limit - failedAttempts;
    return remaining < 0 ? 0 : remaining;
  }

  static String? _defaultGetWalletPath() => kWalletPath;

  static Future<void> _defaultSetWalletFile(WalletFile walletFile) =>
      WalletUtils.setWalletFile(walletFile);

  static bool _defaultIsWalletInitCompleted() => kWalletInitCompleted;

  static int _defaultGetNumFailedAttempts() => kNumFailedUnlockAttempts ?? 0;

  static Future<void> _defaultSaveNumFailedAttempts(int numAttempts) async {
    kNumFailedUnlockAttempts = numAttempts;
    await sharedPrefsService!.put(kNumUnlockFailedAttemptsKey, numAttempts);
  }

  static int _defaultGetAutoEraseWalletLimit() =>
      (kAutoEraseWalletLimit ?? kAutoEraseNumAttemptsDefault).toInt();

  static void _defaultFetchBalances() {
    sl.get<MultipleBalanceBloc>().add(
      MultipleBalanceFetch(
        addresses: kDefaultAddressList.whereType<String>().toList(),
      ),
    );
  }
}
