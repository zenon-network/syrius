import 'dart:async';
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:file_selector/file_selector.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/notifications/notifications.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'export_wallet_event.dart';
part 'export_wallet_state.dart';

/// Exports an encrypted Seed Vault JSON file to a user-selected location.
class ExportWalletBloc extends Bloc<ExportWalletEvent, ExportWalletState> {
  /// Creates an [ExportWalletBloc].
  ExportWalletBloc({
    Future<String?> Function({required String suggestedName})? pickSavePath,
    Future<void> Function({
      required String seed,
      required String password,
      required String filePath,
    })?
    saveKeyStore,
    this._addNotification,
    this._reportError,
    DateTime Function()? now,
  }) : _pickSavePath = pickSavePath ?? _defaultPickSavePath,
       _saveKeyStore = saveKeyStore ?? _defaultSaveKeyStore,
       _now = now ?? DateTime.now,
       super(const ExportWalletInitial()) {
    on<ExportWalletRequested>(_onRequested);
  }

  final Future<String?> Function({required String suggestedName}) _pickSavePath;
  final Future<void> Function({
    required String seed,
    required String password,
    required String filePath,
  })
  _saveKeyStore;
  final Future<void> Function(WalletNotification notification)?
  _addNotification;
  final Future<void> Function(Object error, String title)? _reportError;
  final DateTime Function() _now;

  static Future<String?> _defaultPickSavePath({
    required String suggestedName,
  }) async {
    String? initialDirectory;
    if (Platform.isMacOS || Platform.isWindows || Platform.isLinux) {
      initialDirectory = (await getApplicationDocumentsDirectory()).path;
    }
    final FileSaveLocation? location = await getSaveLocation(
      acceptedTypeGroups: <XTypeGroup>[
        const XTypeGroup(label: 'file', extensions: <String>['json']),
      ],
      initialDirectory: initialDirectory,
      suggestedName: suggestedName,
    );
    return location?.path;
  }

  static Future<void> _defaultSaveKeyStore({
    required String seed,
    required String password,
    required String filePath,
  }) async {
    final KeyStoreManager keyStoreManager = KeyStoreManager(
      walletPath: Directory(path.dirname(filePath)),
    );
    final KeyStore keyStore = KeyStore.fromMnemonic(seed);
    await keyStoreManager.saveKeyStore(
      keyStore,
      password,
      name: path.basename(filePath),
    );
  }

  FutureOr<void> _onRequested(
    ExportWalletRequested event,
    Emitter<ExportWalletState> emit,
  ) async {
    emit(const ExportWalletLoading());
    try {
      final String formattedTimestamp = FormatUtils.formatDate(
        _now().millisecondsSinceEpoch,
        dateFormat: 'yyyy-MM-dd-HHmm',
      );
      final String suggestedName =
          'zenon-syrius-wallet-backup-$formattedTimestamp.json';

      final String? selectedPath = await _pickSavePath(
        suggestedName: suggestedName,
      );
      if (selectedPath == null) {
        emit(const ExportWalletInitial());
        return;
      }

      await _saveKeyStore(
        seed: event.seed,
        password: event.password,
        filePath: selectedPath,
      );

      if (event.backupWalletFlow) {
        await _sendNotification(
          WalletNotification(
            title: event.successTitle,
            timestamp: _now().millisecondsSinceEpoch,
            details: event.successDetailsBuilder(selectedPath),
            type: NotificationType.paymentSent,
          ),
        );
      }

      emit(
        ExportWalletSuccess(
          savedPath: selectedPath,
          backupWalletFlow: event.backupWalletFlow,
        ),
      );
    } on Object catch (error, stackTrace) {
      addError(error, stackTrace);
      await _sendError(error, event.errorTitle);
      emit(ExportWalletFailure(error: error));
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
