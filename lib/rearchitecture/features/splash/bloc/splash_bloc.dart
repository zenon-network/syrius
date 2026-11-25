import 'dart:async';
import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:logging/logging.dart';
import 'package:reown_walletkit/reown_walletkit.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/services/i_web3wallet_service.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';

part 'splash_event.dart';
part 'splash_state.dart';

/// BLoC orchestrating app startup, cache deletion, and full wallet reset flows.
class SplashBloc extends Bloc<SplashEvent, SplashState> {
  /// Creates a [SplashBloc].
  SplashBloc({
    void Function()? setWalletInitIncomplete,
    Future<void> Function()? clearLastNotification,
    void Function()? stopWebSocketClient,
    void Function()? clearAutoReceivePool,
    Future<void> Function()? stopHtlcSwapSync,
    Future<void> Function()? closeHtlcSwapStorage,
    Future<void> Function()? closeHive,
    Future<void> Function(String boxName)? deleteCacheBox,
    Future<void> Function()? deleteWeb3Cache,
    Future<void> Function()? deleteHtlcDatabase,
    Future<void> Function()? deleteLegacyHtlcBoxes,
    Future<void> Function()? deleteKeyStoreBox,
    Future<void> Function()? closeAndDeleteWalletFile,
    String? Function()? getWalletPath,
    String? Function()? getSelectedNode,
    void Function()? exitApp,
  }) : _setWalletInitIncomplete =
           setWalletInitIncomplete ?? _defaultSetWalletInitIncomplete,
       _clearLastNotification =
           clearLastNotification ?? _defaultClearLastNotification,
       _stopWebSocketClient =
           stopWebSocketClient ?? NodeUtils.stopWebSocketClient,
       _clearAutoReceivePool =
           clearAutoReceivePool ?? _defaultClearAutoReceivePool,
       _stopHtlcSwapSync = stopHtlcSwapSync ?? _defaultStopHtlcSwapSync,
       _closeHtlcSwapStorage =
           closeHtlcSwapStorage ?? _defaultCloseHtlcSwapStorage,
       _closeHive = closeHive ?? Hive.close,
       _deleteCacheBox = deleteCacheBox ?? Hive.deleteBoxFromDisk,
       _deleteWeb3Cache = deleteWeb3Cache ?? _defaultDeleteWeb3Cache,
       _deleteHtlcDatabase = deleteHtlcDatabase ?? _defaultDeleteHtlcDatabase,
       _deleteLegacyHtlcBoxes =
           deleteLegacyHtlcBoxes ?? _defaultDeleteLegacyHtlcBoxes,
       _deleteKeyStoreBox = deleteKeyStoreBox ?? _defaultDeleteKeyStoreBox,
       _closeAndDeleteWalletFile =
           closeAndDeleteWalletFile ?? _defaultCloseAndDeleteWalletFile,
       _getWalletPath = getWalletPath ?? _defaultGetWalletPath,
       _getSelectedNode = getSelectedNode ?? _defaultGetSelectedNode,
       _exitApp = exitApp ?? _defaultExitApp,
       super(const SplashInitial()) {
    on<SplashStarted>(_onSplashStarted, transformer: droppable());
  }

  final void Function() _setWalletInitIncomplete;
  final Future<void> Function() _clearLastNotification;
  final void Function() _stopWebSocketClient;
  final void Function() _clearAutoReceivePool;
  final Future<void> Function() _stopHtlcSwapSync;
  final Future<void> Function() _closeHtlcSwapStorage;
  final Future<void> Function() _closeHive;
  final Future<void> Function(String boxName) _deleteCacheBox;
  final Future<void> Function() _deleteWeb3Cache;
  final Future<void> Function() _deleteHtlcDatabase;
  final Future<void> Function() _deleteLegacyHtlcBoxes;
  final Future<void> Function() _deleteKeyStoreBox;
  final Future<void> Function() _closeAndDeleteWalletFile;
  final String? Function() _getWalletPath;
  final String? Function() _getSelectedNode;
  final void Function() _exitApp;

  Future<void> _onSplashStarted(
    SplashStarted event,
    Emitter<SplashState> emit,
  ) async {
    emit(const SplashInProgress());
    try {
      switch (event.flow) {
        case SplashFlow.normal:
          await event.initApp();
          emit(SplashNavigateTo(_resolveDestination()));
        case SplashFlow.development:
          await event.initApp();
          emit(
            SplashNavigateTo(
              _getWalletPath() == null
                  ? SplashDestination.accessWallet
                  : SplashDestination.home,
            ),
          );
        case SplashFlow.deleteCache:
          await _deleteCache();
          emit(const SplashCacheDeleted());
          _exitApp();
        case SplashFlow.resetWallet:
          await _resetWallet(event.initApp);
          emit(SplashNavigateTo(_resolveDestination()));
      }
    } on Object catch (error, stackTrace) {
      addError(error, stackTrace);
      emit(SplashFailure(error));
    }
  }

  SplashDestination _resolveDestination() {
    if (_getWalletPath() == null) {
      return SplashDestination.accessWallet;
    }
    return _getSelectedNode() != null
        ? SplashDestination.home
        : SplashDestination.nodeManagement;
  }

  Future<void> _resetWallet(Future<void> Function() initApp) async {
    // In case the notification was not dismissed, write a null sentinel so it
    // is ignored after the user creates or imports a new wallet.
    _setWalletInitIncomplete();
    await _clearLastNotification();
    _stopWebSocketClient();
    _clearAutoReceivePool();
    await _deleteCache();
    await _deleteHtlcSwapsData();
    await _deleteWalletFile();
    await initApp();
  }

  Future<void> _deleteHtlcSwapsData() async {
    await _deleteHtlcDatabase();
    await _deleteLegacyHtlcBoxes();
  }

  Future<void> _deleteCache() async {
    await _stopHtlcSwapSync();
    await _closeHtlcSwapStorage();
    await _closeHive();
    for (final String boxName in kCacheBoxesToBeDeleted) {
      await _deleteCacheBox(boxName);
    }
    await _deleteWeb3Cache();
  }

  Future<void> _deleteWalletFile() async {
    await _deleteKeyStoreBox();
    await _closeAndDeleteWalletFile();
  }

  static void _defaultSetWalletInitIncomplete() {
    kWalletInitCompleted = false;
  }

  static Future<void> _defaultClearLastNotification() async {
    await sl.get<NotificationsBloc>().addNotification(null);
  }

  static void _defaultClearAutoReceivePool() {
    final AutoReceiveTxWorker worker = sl<AutoReceiveTxWorker>();
    if (worker.pool.isNotEmpty) {
      worker.clearPool();
    }
  }

  static Future<void> _defaultStopHtlcSwapSync() async {
    await sl<HtlcSwapSyncService>().stop();
  }

  static Future<void> _defaultCloseHtlcSwapStorage() async {
    await sl<HtlcSwapLocalStorageApi>().close();
  }

  static Future<void> _defaultDeleteWeb3Cache() async {
    try {
      final IWeb3WalletService service = sl<IWeb3WalletService>();
      for (final PairingInfo pairing in service.pairings.value) {
        await service.deactivatePairing(topic: pairing.topic);
      }
    } on Object catch (e, stackTrace) {
      Logger(
        'SplashScreen',
      ).log(Level.WARNING, '_deleteWeb3Cache', e, stackTrace);
    }
  }

  static Future<void> _defaultDeleteHtlcDatabase() async {
    await sl<HtlcSwapLocalStorageApi>().deleteDatabase();
  }

  static Future<void> _defaultDeleteLegacyHtlcBoxes() async {
    await sl<LegacyHtlcSwapsMigrator>().deleteLegacyBoxesOnReset();
  }

  static Future<void> _defaultDeleteKeyStoreBox() async {
    await Hive.deleteBoxFromDisk(kKeyStoreBox);
  }

  static Future<void> _defaultCloseAndDeleteWalletFile() async {
    if (kWalletFile != null) {
      kWalletFile!.close();
    }
    kWalletFile = null;
    if (kWalletPath != null) {
      await FileUtils.deleteFile(kWalletPath!);
      kWalletPath = null;
    }
  }

  static String? _defaultGetWalletPath() => kWalletPath;

  static String? _defaultGetSelectedNode() =>
      sharedPrefsService?.get(kSelectedNodeKey) as String?;

  static void _defaultExitApp() => exit(0);
}
