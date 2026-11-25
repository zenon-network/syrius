import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:logging/logging.dart';
import 'package:lottie/lottie.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/extensions/buildcontext_extension.dart';
import 'package:zenon_syrius_wallet_flutter/screens/screens.dart';
import 'package:zenon_syrius_wallet_flutter/services/i_web3wallet_service.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

class SplashScreen extends StatefulWidget {
  static const String route = 'splash-screen';

  final bool resetWalletFlow;
  final bool deleteCacheFlow;

  const SplashScreen({
    this.resetWalletFlow = false,
    this.deleteCacheFlow = false,
    Key? key,
  }) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late final Future<LottieComposition> _composition;
  bool _splashStarted = false;
  bool _clearingWalletData = false;

  @override
  void initState() {
    super.initState();
    _composition = AssetLottie('assets/lottie/ic_anim_splash.json').load();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<LottieComposition>(
      future: _composition,
      builder: (context, snapshot) {
        var composition = snapshot.data;
        if (composition != null) {
          if (!_splashStarted) {
            _splashStarted = true;
            Future<void>.delayed(composition.duration, () {
              if (mounted) {
                unawaited(_splashInits());
              }
            });
          }
          return Lottie(composition: composition, repeat: false);
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }

  Future<void> _splashInits() async {
    _clearingWalletData = false;
    try {
      if (widget.resetWalletFlow) {
        await _resetWallet();
      } else if (widget.deleteCacheFlow) {
        _clearingWalletData = true;
        await _deleteCache();
        _clearingWalletData = false;
        exit(0);
      } else {
        await InitUtils.initApp(context);
      }
      if (!mounted) return;
      _navigateToNextScreen();
    } on Object catch (e) {
      final bool failedWhileClearing = _clearingWalletData;
      _clearingWalletData = false;
      if (!mounted) return;
      if (failedWhileClearing &&
          (widget.resetWalletFlow || widget.deleteCacheFlow)) {
        final bool retry =
            await showDialogWithNoAndYesOptions(
              context: context,
              isBarrierDismissible: false,
              title: widget.resetWalletFlow
                  ? context.l10n.walletResetFailed
                  : context.l10n.cacheDeletionFailed,
              content: Text(
                context.l10n.failedToClearLocalWalletData(e.toString()),
              ),
            ) ??
            false;
        if (!mounted) return;
        if (retry) {
          await _splashInits();
          return;
        }
      }
      Navigator.pushReplacementNamed(
        context,
        SyriusErrorWidget.route,
        arguments: CustomSyriusErrorWidgetArguments(e.toString()),
      );
    }
  }

  void _navigateToNextScreen() {
    return kWalletPath != null
        ? _checkForDefaultNode()
        : Navigator.pushReplacementNamed(context, AccessWalletScreen.route);
  }

  void _navigateToHomeScreen() {
    Navigator.of(
      context,
      rootNavigator: true,
    ).pushReplacementNamed(MainAppContainer.route);
  }

  void _navigateToNodeManagementScreen() {
    Navigator.of(
      context,
      rootNavigator: true,
    ).pushReplacementNamed(NodeManagementScreen.route);
  }

  Future<void> _resetWallet() async {
    // In case the notification was not dismissed, we add a null value to be ignored
    // after the user creates or imports a new wallet
    kWalletInitCompleted = false;
    await sl.get<NotificationsBloc>().addNotification(null);
    NodeUtils.stopWebSocketClient();
    if (sl<AutoReceiveTxWorker>().pool.isNotEmpty) {
      sl<AutoReceiveTxWorker>().pool.clear();
    }
    _clearingWalletData = true;
    await _deleteCache();
    await _deleteHtlcSwapsData();
    await _deleteWalletFile();
    _clearingWalletData = false;
    if (!mounted) return;
    await InitUtils.initApp(context);
  }

  Future<void> _deleteHtlcSwapsData() async {
    await sl<HtlcSwapLocalStorageApi>().deleteDatabase();
    await sl<LegacyHtlcSwapsMigrator>().deleteLegacyBoxesOnReset();
  }

  Future<void> _deleteCache() async {
    await _deleteWeb3Cache();
    await sl<HtlcSwapSyncService>().stop();
    await sl<HtlcSwapLocalStorageApi>().close();
    await Hive.close();
    await Future.forEach<String>(
      kCacheBoxesToBeDeleted,
      (boxName) async => await Hive.deleteBoxFromDisk(boxName),
    );
  }

  Future<void> _deleteWeb3Cache() async {
    if (!sl.isRegistered<IWeb3WalletService>()) {
      return;
    }
    try {
      final IWeb3WalletService web3WalletService = sl<IWeb3WalletService>();
      await web3WalletService.disconnectEverything();
    } on Object catch (e, stackTrace) {
      Logger(
        'SplashScreen',
      ).log(Level.WARNING, '_deleteWeb3Cache', e, stackTrace);
      rethrow;
    }
  }

  Future<void> _deleteWalletFile() async {
    await Hive.deleteBoxFromDisk(kKeyStoreBox);
    if (kWalletFile != null) kWalletFile!.close();
    kWalletFile = null;
    if (kWalletPath != null) {
      await FileUtils.deleteFile(kWalletPath!);
      kWalletPath = null;
    }
  }

  void _checkForDefaultNode() =>
      sharedPrefsService!.get(kSelectedNodeKey) != null
      ? _navigateToHomeScreen()
      : _navigateToNodeManagementScreen();

  @override
  void dispose() {
    super.dispose();
  }
}
