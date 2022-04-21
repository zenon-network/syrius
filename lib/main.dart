import 'dart:io';
import 'dart:isolate';

import 'package:feedback/feedback.dart';
import 'package:flutter/foundation.dart'
    show debugDefaultTargetPlatformOverride;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';
import 'package:layout/layout.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/accelerator/accelerator_balance_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/auto_receive_tx_worker.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/dashboard/balance_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/lock_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/notifications_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/plasma/plasma_stats_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/pow_generating_status_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/transfer/transfer_widgets_balance_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/model/database/notification_type.dart';
import 'package:zenon_syrius_wallet_flutter/model/database/wallet_notification.dart';
import 'package:zenon_syrius_wallet_flutter/model/navigation_arguments.dart';
import 'package:zenon_syrius_wallet_flutter/screens/node_management_screen.dart';
import 'package:zenon_syrius_wallet_flutter/screens/onboarding/access_wallet_screen.dart';
import 'package:zenon_syrius_wallet_flutter/screens/splash_screen.dart';
import 'package:zenon_syrius_wallet_flutter/services/shared_prefs_service.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_theme.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:zenon_syrius_wallet_flutter/utils/keyboard_fixer.dart';
import 'package:zenon_syrius_wallet_flutter/utils/network_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/node_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/notifiers/app_theme_notifier.dart';
import 'package:zenon_syrius_wallet_flutter/utils/notifiers/default_address_notifier.dart';
import 'package:zenon_syrius_wallet_flutter/utils/notifiers/plasma_beneficiary_address_notifier.dart';
import 'package:zenon_syrius_wallet_flutter/utils/notifiers/plasma_generated_notifier.dart';
import 'package:zenon_syrius_wallet_flutter/utils/notifiers/text_scaling_notifier.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/main_app_container.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/error_widget.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

Zenon? zenon;
SharedPrefsService? sharedPrefsService;

final sl = GetIt.instance;

main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Provider.debugCheckInvalidValueType = null;
  debugDefaultTargetPlatformOverride = TargetPlatform.fuchsia;

  ensureDirectoriesExist();
  Hive.init(znnDefaultPaths.cache.path.toString());

  windowManager.ensureInitialized();
  await windowManager.setPreventClose(true);

  // Setup services
  setup();

  // Register Hive adapters
  Hive.registerAdapter(NotificationTypeAdapter());
  Hive.registerAdapter(WalletNotificationAdapter());

  if (sharedPrefsService == null) {
    sharedPrefsService = await sl.getAsync<SharedPrefsService>();
  } else {
    await sharedPrefsService!.checkIfBoxIsOpen();
  }

  windowManager.waitUntilReadyToShow().then((_) async {
    await windowManager.setTitle('s y r i u s');
    await windowManager.setMinimumSize(const Size(1200, 600));
    await windowManager.show();

    if (sharedPrefsService != null) {
      double? windowSizeWidth = sharedPrefsService!.get(kWindowSizeWidthKey);
      double? windowSizeHeight = sharedPrefsService!.get(kWindowSizeHeightKey);
      if (windowSizeWidth != null &&
          windowSizeWidth >= 1200 &&
          windowSizeHeight != null &&
          windowSizeHeight >= 600) {
        await windowManager.setSize(Size(windowSizeWidth, windowSizeHeight));
      } else {
        await windowManager.setSize(const Size(1200, 600));
      }

      double? windowPositionX = sharedPrefsService!.get(kWindowPositionXKey);
      double? windowPositionY = sharedPrefsService!.get(kWindowPositionYKey);
      if (windowPositionX != null && windowPositionY != null) {
        await windowManager
            .setPosition(Offset(windowPositionX, windowPositionY));
      }

      bool? windowMaximized = sharedPrefsService!.get(kWindowMaximizedKey);
      if (windowMaximized == true) {
        await windowManager.maximize();
      }
    }
  });

  runApp(BetterFeedback(
    child: Builder(
      builder: (_) => const MyApp(),
    ),
    theme: FeedbackThemeData(
      background: Colors.black,
      activeFeedbackModeColor: AppColors.znnColor,
      drawColors: [
        AppColors.znnColor,
        AppColors.qsrColor,
        AppColors.errorColor,
      ],
    ),
  ));
}

void setup() {
  sl.registerSingleton<Zenon>(Zenon());
  zenon = sl<Zenon>();
  sl.registerLazySingletonAsync<SharedPrefsService>(
      (() => SharedPrefsService.getInstance().then((value) => value!)));

  sl.registerSingleton<AutoReceiveTxWorker>(AutoReceiveTxWorker.getInstance());

  sl.registerSingleton<ReceivePort>(ReceivePort(),
      instanceName: 'embeddedStoppedPort');
  sl.registerSingleton<Stream>(
      sl<ReceivePort>(instanceName: 'embeddedStoppedPort').asBroadcastStream(),
      instanceName: 'embeddedStoppedStream');

  sl.registerSingleton<PlasmaStatsBloc>(PlasmaStatsBloc());
  sl.registerSingleton<BalanceBloc>(BalanceBloc());
  sl.registerSingleton<TransferWidgetsBalanceBloc>(
      TransferWidgetsBalanceBloc());
  sl.registerSingleton<NotificationsBloc>(NotificationsBloc());
  sl.registerSingleton<AcceleratorBalanceBloc>(AcceleratorBalanceBloc());
  sl.registerSingleton<PowGeneratingStatusBloc>(PowGeneratingStatusBloc());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _MyAppState();
  }
}

class _MyAppState extends State<MyApp> with WindowListener {
  @override
  void initState() {
    windowManager.addListener(this);
    initPlatformState();
    super.initState();
  }

  // Platform messages are asynchronous, so we initialize in an async method
  Future<void> initPlatformState() async {
    kLocalIpAddress =
        await NetworkUtils.getLocalIpAddress(InternetAddressType.IPv4);

    if (!mounted) return;
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SelectedAddressNotifier>(
          create: (_) => SelectedAddressNotifier(),
        ),
        ChangeNotifierProvider<PlasmaBeneficiaryAddressNotifier>(
          create: (_) => PlasmaBeneficiaryAddressNotifier(),
        ),
        ChangeNotifierProvider<PlasmaGeneratedNotifier>(
          create: (_) => PlasmaGeneratedNotifier(),
        ),
        ChangeNotifierProvider<TextScalingNotifier>(
          create: (_) => TextScalingNotifier(),
        ),
        ChangeNotifierProvider<AppThemeNotifier>(
          create: (_) => AppThemeNotifier(),
        ),
        ChangeNotifierProvider<ValueNotifier<List<String>>>(
          create: (_) => ValueNotifier<List<String>>(
            [],
          ),
        ),
        Provider<LockBloc>(
          create: (_) => LockBloc(),
          builder: (context, child) {
            return Consumer<AppThemeNotifier>(
              builder: (_, appThemeNotifier, __) {
                LockBloc lockBloc =
                    Provider.of<LockBloc>(context, listen: false);
                return OverlaySupport(
                  child: Listener(
                    onPointerSignal: (event) {
                      if (event is PointerScrollEvent) {
                        lockBloc.addEvent(LockEvent.resetTimer);
                      }
                    },
                    onPointerCancel: (_) =>
                        lockBloc.addEvent(LockEvent.resetTimer),
                    onPointerDown: (_) =>
                        lockBloc.addEvent(LockEvent.resetTimer),
                    onPointerHover: (_) =>
                        lockBloc.addEvent(LockEvent.resetTimer),
                    onPointerMove: (_) =>
                        lockBloc.addEvent(LockEvent.resetTimer),
                    onPointerUp: (_) => lockBloc.addEvent(LockEvent.resetTimer),
                    child: MouseRegion(
                      onEnter: (_) => lockBloc.addEvent(LockEvent.resetTimer),
                      onExit: (_) => lockBloc.addEvent(LockEvent.resetTimer),
                      child: RawKeyboardListener(
                        focusNode: FocusNode(),
                        onKey: (RawKeyEvent event) {
                          lockBloc.addEvent(LockEvent.resetTimer);
                        },
                        child: KeyboardFixer(
                          child: Layout(
                            child: MaterialApp(
                              title: 's y r i u s',
                              debugShowCheckedModeBanner: false,
                              theme: AppTheme.lightTheme,
                              darkTheme: AppTheme.darkTheme,
                              themeMode: appThemeNotifier.currentThemeMode,
                              initialRoute: SplashScreen.route,
                              routes: {
                                AccessWalletScreen.route: (context) =>
                                    const AccessWalletScreen(),
                                SplashScreen.route: (context) =>
                                    const SplashScreen(),
                                MainAppContainer.route: (context) =>
                                    const MainAppContainer(),
                                NodeManagementScreen.route: (_) =>
                                    const NodeManagementScreen(),
                              },
                              onGenerateRoute: (settings) {
                                if (settings.name == SyriusErrorWidget.route) {
                                  final args = settings.arguments
                                      as CustomSyriusErrorWidgetArguments;
                                  return MaterialPageRoute(
                                    builder: (context) =>
                                        SyriusErrorWidget(args.errorText),
                                  );
                                }
                                return null;
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  @override
  void onWindowClose() async {
    bool windowMaximized = await windowManager.isMaximized();
    await sharedPrefsService!.put(
      kWindowMaximizedKey,
      windowMaximized,
    );

    if (windowMaximized != true) {
      Size windowSize = await windowManager.getSize();
      await sharedPrefsService!.put(
        kWindowSizeWidthKey,
        windowSize.width,
      );
      await sharedPrefsService!.put(
        kWindowSizeHeightKey,
        windowSize.height,
      );

      Offset windowPosition = await windowManager.getPosition();
      await sharedPrefsService!.put(
        kWindowPositionXKey,
        windowPosition.dx,
      );
      await sharedPrefsService!.put(
        kWindowPositionYKey,
        windowPosition.dy,
      );
    }

    sl<Zenon>().wsClient.stop();
    Future.delayed(const Duration(seconds: 60)).then((value) => exit(0));
    await NodeUtils.closeEmbeddedNode();
    super.onWindowClose();
    deactivate();
    dispose();
    exit(0);
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    sl.unregister();
    super.dispose();
  }
}
