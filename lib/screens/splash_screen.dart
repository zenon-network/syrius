import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:lottie/lottie.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/screens/screens.dart';
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

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Lottie.asset(
      'assets/lottie/ic_anim_splash.json',
      animate: true,
      controller: _controller,
      onLoaded: (composition) {
        _controller
          ..duration = composition.duration
          ..forward().whenComplete(
            () => _splashInits(),
          );
      },
    );
  }

  Future<void> _splashInits() async {
    try {
      widget.resetWalletFlow
          ? await _resetWallet()
          : widget.deleteCacheFlow
              ? await _deleteCache().then((value) => exit(0))
              : await InitUtils.initApp(context);
      _navigateToNextScreen();
    } on Exception catch (e) {
      Navigator.pushReplacementNamed(
        context,
        SyriusErrorWidget.route,
        arguments: CustomSyriusErrorWidgetArguments(e.toString()),
      );
    }
  }

  void _navigateToNextScreen() {
    _controller.stop();
    return kKeyStorePath != null
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
    await _deleteKeyStoreFile();
    await Hive.deleteFromDisk();
    if (!mounted) return;
    await InitUtils.initApp(context);
  }

  Future<void> _deleteCache() async => Future.forEach<String>(
        kCacheBoxesToBeDeleted,
        (boxName) async => await Hive.deleteBoxFromDisk(boxName),
      );

  Future<void> _deleteKeyStoreFile() async {
    await FileUtils.deleteFile(kKeyStorePath!);
    kKeyStorePath = null;
  }

  void _checkForDefaultNode() => sharedPrefsService!.get(
            kSelectedNodeKey,
          ) !=
          null
      ? _navigateToHomeScreen()
      : _navigateToNodeManagementScreen();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
