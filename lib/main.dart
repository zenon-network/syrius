import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';
import 'package:layout/layout.dart';
import 'package:local_notifier/local_notifier.dart';
import 'package:logging/logging.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:path/path.dart' as path;
import 'package:provider/provider.dart';
import 'package:retry/retry.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/auto_unlock_htlc_worker.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/wallet_connect/chains/i_chain.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/wallet_connect/chains/nom_service.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/wallet_connect/wallet_connect_pairings_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/wallet_connect/wallet_connect_sessions_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/handlers/htlc_swaps_handler.dart';
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/screens/screens.dart';
import 'package:zenon_syrius_wallet_flutter/services/htlc_swaps_service.dart';
import 'package:zenon_syrius_wallet_flutter/services/i_web3wallet_service.dart';
import 'package:zenon_syrius_wallet_flutter/services/shared_prefs_service.dart';
import 'package:zenon_syrius_wallet_flutter/services/web3wallet_service.dart';
import 'package:zenon_syrius_wallet_flutter/utils/functions.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

Zenon? zenon;
SharedPrefsService? sharedPrefsService;
HtlcSwapsService? htlcSwapsService;
IWeb3WalletService? web3WalletService;

final sl = GetIt.instance;

final globalNavigatorKey = GlobalKey<NavigatorState>();

main() async {
  WidgetsFlutterBinding.ensureInitialized();

  Provider.debugCheckInvalidValueType = null;

  ensureDirectoriesExist();
  Hive.init(znnDefaultPaths.cache.path);

  // Setup logger
  final syriusLogDir =
      Directory(path.join(znnDefaultCacheDirectory.path, 'log'));
  if (!syriusLogDir.existsSync()) {
    syriusLogDir.createSync(recursive: true);
  }
  final logFile = File(
      '${syriusLogDir.path}${path.separator}syrius-${DateTime.now().millisecondsSinceEpoch}.log',);
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((LogRecord record) {
    if (kDebugMode) {
      print(
          '${record.level.name} ${record.loggerName} ${record.message} ${record.time}: '
          '${record.error} ${record.stackTrace}\n');
    }
    logFile.writeAsString(
      '${record.level.name} ${record.loggerName} ${record.message} ${record.time}: '
      '${record.error} ${record.stackTrace}\n',
      mode: FileMode.append,
      flush: true,
    );
  });

  windowManager.ensureInitialized();
  await windowManager.setPreventClose(true);

  web3WalletService = Web3WalletService();
  web3WalletService!.create();

  // Setup services
  setup();

  retry(() => web3WalletService!.init(),
      retryIf: (e) => e is SocketException || e is TimeoutException,
      maxAttempts: 0x7FFFFFFFFFFFFFFF,);

  // Setup local_notifier
  await localNotifier.setup(
    appName: 's y r i u s',
  );

  // Setup tray manager
  await _setupTrayManager();

  // Load default community nodes from assets
  await _loadDefaultCommunityNodes();

  // Register Hive adapters
  Hive.registerAdapter(NotificationTypeAdapter());
  Hive.registerAdapter(WalletNotificationAdapter());

  if (sharedPrefsService == null) {
    sharedPrefsService = await sl.getAsync<SharedPrefsService>();
  } else {
    await sharedPrefsService!.checkIfBoxIsOpen();
  }

  htlcSwapsService ??= sl.get<HtlcSwapsService>();

  windowManager.waitUntilReadyToShow().then((_) async {
    await windowManager.setTitle('s y r i u s');
    await windowManager.setMinimumSize(const Size(1200, 600));
    await windowManager.show();

    if (sharedPrefsService != null) {
      final double? windowSizeWidth = sharedPrefsService!.get(kWindowSizeWidthKey);
      final double? windowSizeHeight = sharedPrefsService!.get(kWindowSizeHeightKey);
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
        windowPositionX = windowPositionX >= 0 ? windowPositionX : 100;
        windowPositionY = windowPositionY >= 0 ? windowPositionY : 100;
        await windowManager
            .setPosition(Offset(windowPositionX, windowPositionY));
      }

      final bool? windowMaximized = sharedPrefsService!.get(kWindowMaximizedKey);
      if (windowMaximized == true) {
        await windowManager.maximize();
      }
    }
  });

  runApp(
    const MyApp(),
  );
}

Future<void> _setupTrayManager() async {
  await trayManager.setIcon(
    Platform.isWindows
        ? 'assets/images/tray_app_icon.ico'
        : 'assets/images/tray_app_icon.png',
  );
  if (Platform.isMacOS) {
    await trayManager.setToolTip('s y r i u s');
  }
  final items = <MenuItem>[
    MenuItem(
      key: 'show_wallet',
      label: 'Show wallet',
    ),
    MenuItem(
      key: 'hide_wallet',
      label: 'Hide wallet',
    ),
    MenuItem.separator(),
    MenuItem(
      key: 'exit',
      label: 'Exit wallet',
    ),
  ];
  await trayManager.setContextMenu(Menu(items: items));
}

Future<void> _loadDefaultCommunityNodes() async {
  try {
    final nodes = await loadJsonFromAssets('assets/community-nodes.json')
        as List<dynamic>;
    kDefaultCommunityNodes = nodes
        .map((node) => node.toString())
        .where((node) => InputValidators.node(node) == null)
        .toList();
  } catch (e, stackTrace) {
    Logger('main')
        .log(Level.WARNING, '_loadDefaultCommunityNodes', e, stackTrace);
  }
}

void setup() {
  sl.registerSingleton<Zenon>(Zenon());
  zenon = sl<Zenon>();
  sl.registerLazySingletonAsync<SharedPrefsService>(
      () => SharedPrefsService.getInstance().then((value) => value!),);
  sl.registerSingleton<HtlcSwapsService>(HtlcSwapsService.getInstance());

  // Initialize WalletConnect service
  sl.registerSingleton<IWeb3WalletService>(web3WalletService!);
  sl.registerSingleton<IChain>(
    NoMService(reference: NoMChainId.mainnet),
    instanceName: NoMChainId.mainnet.chain(),
  );

  sl.registerSingleton<AutoReceiveTxWorker>(AutoReceiveTxWorker.getInstance());
  sl.registerSingleton<AutoUnlockHtlcWorker>(
      AutoUnlockHtlcWorker.getInstance(),);

  sl.registerSingleton<HtlcSwapsHandler>(HtlcSwapsHandler.getInstance());

  sl.registerSingleton<ReceivePort>(ReceivePort(),
      instanceName: 'embeddedStoppedPort',);
  sl.registerSingleton<Stream>(
      sl<ReceivePort>(instanceName: 'embeddedStoppedPort').asBroadcastStream(),
      instanceName: 'embeddedStoppedStream',);

  sl.registerSingleton<PlasmaStatsBloc>(PlasmaStatsBloc());
  sl.registerSingleton<BalanceBloc>(BalanceBloc());
  sl.registerSingleton<TransferWidgetsBalanceBloc>(
      TransferWidgetsBalanceBloc(),);
  sl.registerSingleton<NotificationsBloc>(NotificationsBloc());
  sl.registerSingleton<AcceleratorBalanceBloc>(AcceleratorBalanceBloc());
  sl.registerSingleton<PowGeneratingStatusBloc>(PowGeneratingStatusBloc());
  sl.registerSingleton<WalletConnectPairingsBloc>(
    WalletConnectPairingsBloc(),
  );
  sl.registerSingleton<WalletConnectSessionsBloc>(
    WalletConnectSessionsBloc(),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<StatefulWidget> createState() {
    return _MyAppState();
  }
}

class _MyAppState extends State<MyApp> with WindowListener, TrayListener {
  @override
  void initState() {
    windowManager.addListener(this);
    trayManager.addListener(this);
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
                final lockBloc =
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
                      child: KeyboardListener(
                        focusNode: FocusNode(),
                        onKeyEvent: (KeyEvent event) {
                          lockBloc.addEvent(LockEvent.resetTimer);
                        },
                        child: Layout(
                          child: MaterialApp(
                            title: 's y r i u s',
                            navigatorKey: globalNavigatorKey,
                            debugShowCheckedModeBanner: false,
                            theme: AppTheme.lightTheme,
                            darkTheme: AppTheme.darkTheme,
                            themeMode: appThemeNotifier.currentThemeMode,
                            initialRoute: SplashScreen.route,
                            scrollBehavior: RemoveOverscrollEffect(),
                            localizationsDelegates: AppLocalizations.localizationsDelegates,
                            supportedLocales: AppLocalizations.supportedLocales,
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
                                final args = settings.arguments!
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
                );
              },
            );
          },
        ),
      ],
    );
  }

  @override
  Future<void> onWindowClose() async {
    final windowMaximized = await windowManager.isMaximized();
    await sharedPrefsService!.put(
      kWindowMaximizedKey,
      windowMaximized,
    );

    if (windowMaximized != true) {
      final windowSize = await windowManager.getSize();
      await sharedPrefsService!.put(
        kWindowSizeWidthKey,
        windowSize.width,
      );
      await sharedPrefsService!.put(
        kWindowSizeHeightKey,
        windowSize.height,
      );

      final windowPosition = await windowManager.getPosition();
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
    await sl.reset();
    super.onWindowClose();
    deactivate();
    dispose();
    exit(0);
  }

  @override
  void onTrayIconMouseDown() {
    trayManager.popUpContextMenu();
  }

  @override
  void onTrayIconRightMouseDown() {}

  @override
  void onTrayIconRightMouseUp() {}

  @override
  Future<void> onTrayMenuItemClick(MenuItem menuItem) async {
    switch (menuItem.key) {
      case 'show_wallet':
        windowManager.show();
      case 'hide_wallet':
        if (!await windowManager.isMinimized()) {
          windowManager.minimize();
        }
      case 'exit':
        windowManager.destroy();
      default:
        break;
    }
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    trayManager.removeListener(this);
    super.dispose();
  }
}
