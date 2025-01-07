import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:logging/logging.dart';
import 'package:lottie/lottie.dart';
import 'package:walletconnect_flutter_v2/apis/core/pairing/utils/pairing_models.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/screens/screens.dart';
import 'package:zenon_syrius_wallet_flutter/services/i_web3wallet_service.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

class SplashScreen extends StatefulWidget {

  const SplashScreen({
    this.resetWalletFlow = false,
    this.deleteCacheFlow = false,
    super.key,
  });
  static const String route = 'splash-screen';

  final bool resetWalletFlow;
  final bool deleteCacheFlow;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late final Future<LottieComposition> _composition;

  // The lottie uses a cache to load a file, if the file was previously loaded
  // the Future.builder will fire twice with the snapshot.hasData = true, and
  // it will call _splashInits method twice
  bool _splashInitsCalled = false;

  @override
  void initState() {
    super.initState();
    _composition = AssetLottie('assets/lottie/ic_anim_splash.json').load();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<LottieComposition>(
      future: _composition,
      builder: (BuildContext context, AsyncSnapshot<LottieComposition> snapshot) {
        final LottieComposition? composition = snapshot.data;
        if (composition != null) {
          Future<void>.delayed(composition.duration, _splashInits);
          return Lottie(
            composition: composition,
            repeat: false,
          );
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }

  Future<void> _splashInits() async {
    try {
      if (!_splashInitsCalled) {
        _splashInitsCalled = true;
        widget.resetWalletFlow
            ? await _resetWallet()
            : widget.deleteCacheFlow
                ? await _deleteCache().then((value) => exit(0))
                : await InitUtils.initApp(context);
        _navigateToNextScreen();
      }
    } on Exception catch (e) {
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
        : Navigator.pushReplacementNamed(
            context,
            AccessWalletScreen.route,
          );
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
    await _deleteCache();
    await _deleteWalletFile();
    if (!mounted) return;
    await InitUtils.initApp(context);
  }

  Future<void> _deleteCache() async {
    await Hive.close();
    await Future.forEach<String>(
      kCacheBoxesToBeDeleted,
      (String boxName) async => Hive.deleteBoxFromDisk(boxName),
    );
    await _deleteWeb3Cache();
  }

  Future<void> _deleteWeb3Cache() async {
    try {
      final IWeb3WalletService web3WalletService = sl<IWeb3WalletService>();
      for (final PairingInfo pairing in web3WalletService.pairings.value) {
        await web3WalletService.deactivatePairing(topic: pairing.topic);
      }
    } catch (e, stackTrace) {
      Logger('SplashScreen')
          .log(Level.WARNING, '_deleteWeb3Cache', e, stackTrace);
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

  void _checkForDefaultNode() => sharedPrefsService!.get(
            kSelectedNodeKey,
          ) !=
          null
      ? _navigateToHomeScreen()
      : _navigateToNodeManagementScreen();

  @override
  void dispose() {
    super.dispose();
  }
}
