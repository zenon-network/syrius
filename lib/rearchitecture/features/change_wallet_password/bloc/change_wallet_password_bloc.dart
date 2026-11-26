import 'dart:async';
import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:logging/logging.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/p2p_swaps/data/htlc_swap_local_storage_api.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/p2p_swaps/data/legacy_htlc_swaps_migrator.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/p2p_swaps/services/htlc_swap_sync_service.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/wallet_file.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'change_wallet_password_event.dart';
part 'change_wallet_password_state.dart';

/// Verifies the current wallet password and atomically migrates legacy HTLC
/// swaps, rekeys Drift swap storage, and updates the encrypted wallet file.
class ChangeWalletPasswordBloc
    extends Bloc<ChangeWalletPasswordEvent, ChangeWalletPasswordState> {
  /// Creates a [ChangeWalletPasswordBloc].
  ChangeWalletPasswordBloc({
    Future<WalletFile> Function(String walletPath, String password)?
    decryptWalletFile,
    String? Function()? walletPathProvider,
    WalletFile? Function()? walletFileProvider,
    String? Function()? walletBaseAddressProvider,
    this._syncService,
    this._storageApi,
    this._legacyMigrator,
    this._reportError,
  }) : _decryptWalletFile = decryptWalletFile ?? WalletUtils.decryptWalletFile,
       _walletPathProvider = walletPathProvider ?? _defaultWalletPath,
       _walletFileProvider = walletFileProvider ?? _defaultWalletFile,
       _walletBaseAddressProvider =
           walletBaseAddressProvider ?? _defaultWalletBaseAddress,
       super(const ChangeWalletPasswordInitial()) {
    on<ChangeWalletPasswordSubmitted>(_onSubmitted, transformer: droppable());
    on<ChangeWalletPasswordErrorCleared>(_onErrorCleared);
  }

  final Future<WalletFile> Function(String walletPath, String password)
  _decryptWalletFile;
  final String? Function() _walletPathProvider;
  final WalletFile? Function() _walletFileProvider;
  final String? Function() _walletBaseAddressProvider;
  final HtlcSwapSyncService? _syncService;
  final HtlcSwapLocalStorageApi? _storageApi;
  final LegacyHtlcSwapsMigrator? _legacyMigrator;
  final Future<void> Function(Object error, String title)? _reportError;

  static Future<void> _serializedTransactions = Future<void>.value();

  static Future<T> _runSerialized<T>(Future<T> Function() action) {
    final Completer<T> completer = Completer<T>();
    _serializedTransactions = _serializedTransactions.then((_) async {
      try {
        completer.complete(await action());
      } on Object catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });
    return completer.future;
  }

  static String? _defaultWalletPath() => kWalletPath;

  static WalletFile? _defaultWalletFile() => kWalletFile;

  static String? _defaultWalletBaseAddress() {
    if (kDefaultAddressList.isNotEmpty && kDefaultAddressList.first != null) {
      return WalletUtils.baseAddress.toString();
    }
    return null;
  }

  void _onErrorCleared(
    ChangeWalletPasswordErrorCleared event,
    Emitter<ChangeWalletPasswordState> emit,
  ) {
    if (state is ChangeWalletPasswordIncorrectCurrentPassword) {
      emit(const ChangeWalletPasswordInitial());
    }
  }

  FutureOr<void> _onSubmitted(
    ChangeWalletPasswordSubmitted event,
    Emitter<ChangeWalletPasswordState> emit,
  ) async {
    if (state is ChangeWalletPasswordLoading) {
      return;
    }
    emit(const ChangeWalletPasswordLoading());

    await _runSerialized<void>(() async {
      try {
        final WalletFile verifiedWalletFile = await _decryptWalletFile(
          _walletPathProvider()!,
          event.currentPassword,
        );
        if (!identical(verifiedWalletFile, _walletFileProvider())) {
          try {
            await verifiedWalletFile.close();
          } on Object catch (closeError, closeStackTrace) {
            Logger('ChangeWalletPasswordBloc').log(
              Level.WARNING,
              'Failed to close temporary WalletFile',
              closeError,
              closeStackTrace,
            );
          }
        }
      } on IncorrectPasswordException {
        if (!isClosed) {
          emit(const ChangeWalletPasswordIncorrectCurrentPassword());
        }
        return;
      } on Object catch (error, stackTrace) {
        if (!isClosed) {
          addError(error, stackTrace);
          emit(ChangeWalletPasswordFailure(error: error));
        }
        await _sendError(error, event.decryptErrorTitle);
        return;
      }

      try {
        await _changePasswordAtomically(
          currentPassword: event.currentPassword,
          newPassword: event.newPassword,
        );
        if (!isClosed) {
          emit(const ChangeWalletPasswordSuccess());
        }
      } on Object catch (error, stackTrace) {
        if (!isClosed) {
          addError(error, stackTrace);
          emit(ChangeWalletPasswordFailure(error: error));
        }
        await _sendError(error, event.changePasswordErrorTitle);
      }
    });
  }

  Future<void> _changePasswordAtomically({
    required String currentPassword,
    required String newPassword,
  }) async {
    final HtlcSwapSyncService handler =
        _syncService ?? sl<HtlcSwapSyncService>();
    final HtlcSwapLocalStorageApi dataProvider =
        _storageApi ?? sl<HtlcSwapLocalStorageApi>();
    final LegacyHtlcSwapsMigrator migrator =
        _legacyMigrator ?? sl<LegacyHtlcSwapsMigrator>();

    final List<int> oldEncryptionKey = Crypto.digest(
      utf8.encode(currentPassword),
    );
    final List<int> newEncryptionKey = Crypto.digest(utf8.encode(newPassword));

    await handler.stop();
    try {
      final String? baseAddress = _walletBaseAddressProvider();
      if (baseAddress != null) {
        await migrator.migrateIfNeeded(
          walletBaseAddress: baseAddress,
          encryptionKey: oldEncryptionKey,
        );
      }
      await dataProvider.beginRekey(
        oldEncryptionKey: oldEncryptionKey,
        newEncryptionKey: newEncryptionKey,
      );
      try {
        await _walletFileProvider()!.changePassword(
          currentPassword,
          newPassword,
        );
      } on Object {
        await dataProvider.rollbackRekey(oldEncryptionKey);
        rethrow;
      }
      await dataProvider.commitRekey();
    } finally {
      handler.start();
    }
  }

  Future<void> _sendError(Object error, String title) async {
    if (_reportError != null) {
      await _reportError(error, title);
      return;
    }
    await NotificationUtils.sendNotificationError(error, title);
  }
}
