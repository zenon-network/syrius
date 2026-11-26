import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb, visibleForTesting;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get_it/get_it.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:layout/layout.dart';
import 'package:logging/logging.dart';
import 'package:nested/nested.dart';
import 'package:overlay_support/overlay_support.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:retry/retry.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/p2p_swaps/services/htlc_swap_auto_unlock_service.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/p2p_swaps/services/htlc_swap_sync_service.dart';
import 'package:zenon_syrius_wallet_flutter/hive/hive_registrar.g.dart';
import 'package:zenon_syrius_wallet_flutter/l10n/app_localizations.dart';
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/services/i_chain.dart';
import 'package:zenon_syrius_wallet_flutter/services/i_web3wallet_service.dart';
import 'package:zenon_syrius_wallet_flutter/services/nom_service.dart';
import 'package:zenon_syrius_wallet_flutter/services/shared_prefs_service.dart';
import 'package:zenon_syrius_wallet_flutter/services/web3wallet_service.dart';
import 'package:zenon_syrius_wallet_flutter/utils/functions.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

Zenon? zenon;
SharedPrefsService? sharedPrefsService;
IWeb3WalletService? web3WalletService;

const String _znnDataDirectoryName = String.fromEnvironment(
  'ZNN_DATA_DIRECTORY',
);

final GetIt sl = GetIt.instance;
final FlutterLocalNotificationsPlugin desktopNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

final GlobalKey<NavigatorState> globalNavigatorKey =
    GlobalKey<NavigatorState>();

TrayIcon? _trayIcon;

Future<void> initializeDesktopNotifications() async {
  if (!isDesktopPlatform()) {
    return;
  }

  const InitializationSettings initializationSettings = InitializationSettings(
    macOS: DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    ),
    linux: LinuxInitializationSettings(
      defaultActionName: 'Open notification',
    ),
    windows: WindowsInitializationSettings(
      appName: 's y r i u s',
      appUserModelId: 'Network.Zenon.Syrius',
      // Randomly generated
      guid: 'a796cf2f-0772-4ad3-b140-d44f0144fbc6',
      iconPath: 'assets/images/tray_app_icon.png',
    ),
  );

  await desktopNotificationsPlugin.initialize(
    settings: initializationSettings,
  );
}

main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Bloc.observer = CustomBlocObserver();
  if (Platform.isWindows) {
    registerProtocolHandler(kDeepLinkingUrlScheme);
  }
  _configureZnnDataDirectories();
  ensureDirectoriesExist();

  final Directory hydratedStorageDirectory = _znnDataDirectoryName.isEmpty
      ? await getTemporaryDirectory()
      : Directory(path.join(znnDefaultCacheDirectory.path, 'hydrated_bloc'));
  if (!hydratedStorageDirectory.existsSync()) {
    hydratedStorageDirectory.createSync(recursive: true);
  }
  // Init hydrated bloc storage
  HydratedBloc.storage = await HydratedStorage.build(
    storageDirectory: kIsWeb
        ? HydratedStorageDirectory.web
        : HydratedStorageDirectory(hydratedStorageDirectory.path),
  );
  Provider.debugCheckInvalidValueType = null;

  Hive.init(znnDefaultPaths.cache.path);

  // Setup logger
  final Directory syriusLogDir = Directory(
    path.join(znnDefaultCacheDirectory.path, 'log'),
  );
  if (!syriusLogDir.existsSync()) {
    syriusLogDir.createSync(recursive: true);
  }
  final File logFile = File(
    '${syriusLogDir.path}${path.separator}syrius-${DateTime.now().millisecondsSinceEpoch}.log',
  );
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((LogRecord record) {
    if (kDebugMode) {
      print(
        '${record.level.name} ${record.loggerName} ${record.message} ${record.time}: '
        '${record.error} ${record.stackTrace}\n',
      );
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

  retry(
    () => web3WalletService!.init(),
    retryIf: (e) => e is SocketException || e is TimeoutException,
    maxAttempts: 0x7FFFFFFFFFFFFFFF,
  );

  await initializeDesktopNotifications();

  // Setup tray manager
  _setupTrayManager();

  // Load default community nodes from assets
  await _loadDefaultCommunityNodes();

  // Register Hive adapters
  Hive.registerAdapters();

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
      final double? windowSizeWidth = sharedPrefsService!.get(
        kWindowSizeWidthKey,
      );
      final double? windowSizeHeight = sharedPrefsService!.get(
        kWindowSizeHeightKey,
      );
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
        await windowManager.setPosition(
          Offset(windowPositionX, windowPositionY),
        );
      }

      final bool? windowMaximized = sharedPrefsService!.get(
        kWindowMaximizedKey,
      );
      if (windowMaximized == true) {
        await windowManager.maximize();
      }
    }
  });

  runApp(
    const MyApp(),
  );
}

void _configureZnnDataDirectories() {
  if (_znnDataDirectoryName.isEmpty) {
    return;
  }

  final Directory root = Directory(
    path.join(znnDefaultDirectory.parent.path, _znnDataDirectoryName),
  );
  znnDefaultPaths = ZnnPaths(
    main: root,
    wallet: Directory(path.join(root.path, 'wallet')),
    cache: Directory(path.join(root.path, 'syrius')),
  );
  znnDefaultDirectory = znnDefaultPaths.main;
  znnDefaultWalletDirectory = znnDefaultPaths.wallet;
  znnDefaultCacheDirectory = znnDefaultPaths.cache;
}

void _setupTrayManager() {
  final TrayIcon trayIcon =
      TrayIcon.create() ?? (throw StateError('Unable to create the tray icon'));
  _trayIcon = trayIcon;

  final String iconPath = Platform.isWindows
      ? 'assets/images/tray_app_icon.ico'
      : 'assets/images/tray_app_icon.png';
  trayIcon.icon =
      ImageAsset.fromAsset(iconPath) ??
      (throw StateError('Unable to load the tray icon'));
  if (Platform.isMacOS) {
    trayIcon.setTooltip('s y r i u s');
  }

  final Menu menu = Menu.create()!;
  final MenuItem showWalletItem = MenuItem.createWithLabelAndType(
    'Show wallet',
    MenuItemType.normal,
  )!;
  final MenuItem hideWalletItem = MenuItem.createWithLabelAndType(
    'Hide wallet',
    MenuItemType.normal,
  )!;
  final MenuItem exitWalletItem = MenuItem.createWithLabelAndType(
    'Exit wallet',
    MenuItemType.normal,
  )!;

  showWalletItem.addListener((MenuEvent event) {
    if (event is MenuItemClickedEvent) {
      unawaited(windowManager.show());
    }
  });
  hideWalletItem.addListener((MenuEvent event) {
    if (event is MenuItemClickedEvent) {
      unawaited(_minimizeWindow());
    }
  });
  exitWalletItem.addListener((MenuEvent event) {
    if (event is MenuItemClickedEvent) {
      unawaited(windowManager.destroy());
    }
  });

  menu
    ..addItem(showWalletItem)
    ..addItem(hideWalletItem)
    ..addSeparator()
    ..addItem(exitWalletItem);

  trayIcon
    ..addListener((TrayIconEvent event) {
      if (event is TrayIconClickedEvent) {
        trayIcon.openContextMenu();
      }
    })
    ..setContextMenu(menu)
    ..setVisible(true);
}

Future<void> _minimizeWindow() async {
  if (!await windowManager.isMinimized()) {
    await windowManager.minimize();
  }
}

Future<void> _loadDefaultCommunityNodes() async {
  try {
    final List nodes =
        await loadJsonFromAssets('assets/community-nodes.json')
            as List<dynamic>;
    kDefaultCommunityNodes = nodes
        .map((node) => node.toString())
        .where((String node) => InputValidators.node(node) == null)
        .toList();
  } catch (e, stackTrace) {
    Logger(
      'main',
    ).log(Level.WARNING, '_loadDefaultCommunityNodes', e, stackTrace);
  }
}

void setup() {
  sl.registerSingleton<Zenon>(Zenon());
  zenon = sl<Zenon>();
  sl.registerSingleton<NodeSyncMonitor>(
    NodeSyncMonitor(zenon: sl<Zenon>()),
  );
  sl.registerLazySingletonAsync<SharedPrefsService>(
    () => SharedPrefsService.getInstance().then(
      (SharedPrefsService? value) => value!,
    ),
  );
  sl.registerLazySingleton<HtlcSwapLocalStorageApi>(
    () => HtlcSwapLocalStorageApi(),
  );
  sl.registerLazySingleton<HtlcSwapRepository>(
    () => HtlcSwapRepository(
      chainIdProvider: () => kNodeChainId,
      dataProvider: sl<HtlcSwapLocalStorageApi>(),
    ),
  );
  sl.registerLazySingleton<LegacyHtlcSwapsMigrator>(
    () => LegacyHtlcSwapsMigrator(
      swapRepository: sl<HtlcSwapRepository>(),
    ),
  );

  // Initialize WalletConnect service
  sl.registerSingleton<IWeb3WalletService>(web3WalletService!);
  for (final NoMChainId chainId in NoMChainId.values) {
    sl.registerSingleton<IChain>(
      NoMService(reference: chainId),
      instanceName: chainId.chain(),
    );
  }

  sl.registerSingleton<LatestTransactionsBloc>(
    LatestTransactionsBloc(
      zenon: zenon!,
    ),
  );
  sl.registerSingleton<PendingTransactionsBloc>(
    PendingTransactionsBloc(
      zenon: zenon!,
    ),
  );
  sl.registerSingleton<MultipleBalanceBloc>(MultipleBalanceBloc(zenon: zenon!));
  sl.registerSingleton<AutoReceiveTxWorker>(AutoReceiveTxWorker());
  sl.registerSingleton<NotificationsBloc>(NotificationsBloc());
  sl.registerSingleton<HtlcSwapUnlockService>(
    HtlcSwapUnlockService(
      accountBlockUtils: AccountBlockUtils(
        publishSuccessNotification: false,
      ),
      zenon: sl<Zenon>(),
    ),
  );
  sl.registerSingleton<HtlcSwapAutoUnlockService>(
    HtlcSwapAutoUnlockService(
      notificationsBloc: sl<NotificationsBloc>(),
      syncMonitor: sl<NodeSyncMonitor>(),
      unlockService: sl<HtlcSwapUnlockService>(),
    ),
  );

  sl.registerSingleton<HtlcSwapSyncService>(
    HtlcSwapSyncService(
      swapRepository: sl<HtlcSwapRepository>(),
      autoUnlockService: sl<HtlcSwapAutoUnlockService>(),
      zenon: sl<Zenon>(),
    ),
  );

  sl.registerSingleton<ReceivePort>(
    ReceivePort(),
    instanceName: 'embeddedStoppedPort',
  );
  sl.registerSingleton<Stream>(
    sl<ReceivePort>(instanceName: 'embeddedStoppedPort').asBroadcastStream(),
    instanceName: 'embeddedStoppedStream',
  );

  sl.registerSingleton<PowGeneratingStatusBloc>(PowGeneratingStatusBloc());
}

/// Builds the root [MultiBlocProvider] list for [MyApp].
@visibleForTesting
List<SingleChildWidget> buildMyAppBlocProviders() => <SingleChildWidget>[
  BlocProvider<NotificationsBloc>.value(
    value: sl.get<NotificationsBloc>(),
  ),
  BlocProvider<LatestTransactionsBloc>.value(
    value: sl.get<LatestTransactionsBloc>(),
  ),
  BlocProvider<PendingTransactionsBloc>.value(
    value: sl.get<PendingTransactionsBloc>(),
  ),
  BlocProvider<SendTransactionBloc>(
    create: (_) => SendTransactionBloc(),
  ),
  BlocProvider<MultipleBalanceBloc>.value(
    value: sl.get<MultipleBalanceBloc>(),
  ),
  BlocProvider<AllTokensBloc>(
    create: (_) => AllTokensBloc(zenon: zenon!)
      ..add(
        const AllTokensRequested(),
      ),
  ),
  BlocProvider<PlasmaStatsBloc>(
    create: (_) => PlasmaStatsBloc(zenon: zenon!)
      ..add(
        const InfiniteListRequested(),
      ),
  ),
];

class MyApp extends StatefulWidget {
  const MyApp({super.key});

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
    kLocalIpAddress = await NetworkUtils.getLocalIpAddress(
      InternetAddressType.IPv4,
    );

    if (!mounted) return;
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: buildMyAppBlocProviders(),
      child: MultiProvider(
        providers: <SingleChildWidget>[
          ChangeNotifierProvider<SelectedAddressNotifier>(
            create: (_) => SelectedAddressNotifier(),
          ),
          BlocProvider<PlasmaBeneficiaryAddressCubit>(
            create: (_) => PlasmaBeneficiaryAddressCubit(),
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
              <String>[],
            ),
          ),
          BlocProvider<LockBloc>(
            create: (_) => LockBloc(),
            child: Builder(
              builder: (BuildContext context) {
                return Consumer<AppThemeNotifier>(
                  builder: (_, AppThemeNotifier appThemeNotifier, __) {
                    final LockBloc lockBloc = context.read<LockBloc>();
                    return OverlaySupport(
                      child: Listener(
                        onPointerSignal: (PointerSignalEvent event) {
                          if (event is PointerScrollEvent) {
                            lockBloc.add(const LockTimerResetRequested());
                          }
                        },
                        onPointerCancel: (_) =>
                            lockBloc.add(const LockTimerResetRequested()),
                        onPointerDown: (_) =>
                            lockBloc.add(const LockTimerResetRequested()),
                        onPointerHover: (_) =>
                            lockBloc.add(const LockTimerResetRequested()),
                        onPointerMove: (_) =>
                            lockBloc.add(const LockTimerResetRequested()),
                        onPointerUp: (_) =>
                            lockBloc.add(const LockTimerResetRequested()),
                        child: MouseRegion(
                          onEnter: (_) =>
                              lockBloc.add(const LockTimerResetRequested()),
                          onExit: (_) =>
                              lockBloc.add(const LockTimerResetRequested()),
                          child: KeyboardListener(
                            focusNode: FocusNode(),
                            onKeyEvent: (KeyEvent event) {
                              lockBloc.add(const LockTimerResetRequested());
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
                                localizationsDelegates:
                                    AppLocalizations.localizationsDelegates,
                                supportedLocales:
                                    AppLocalizations.supportedLocales,
                                routes: <String, WidgetBuilder>{
                                  AccessWalletScreen.route:
                                      (BuildContext context) =>
                                          const AccessWalletScreen(),
                                  SplashScreen.route: (BuildContext context) =>
                                      const SplashScreen(),
                                  MainAppContainer.route:
                                      (BuildContext context) =>
                                          const MainAppContainer(),
                                  NodeManagementScreen.route: (_) =>
                                      const NodeManagementScreen(),
                                },
                                onGenerateRoute: (RouteSettings settings) {
                                  if (settings.name ==
                                      SyriusErrorWidget.route) {
                                    final CustomSyriusErrorWidgetArguments
                                    args =
                                        settings.arguments!
                                            as CustomSyriusErrorWidgetArguments;
                                    return MaterialPageRoute(
                                      builder: (BuildContext context) =>
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
          ),
        ],
      ),
    );
  }

  @override
  Future<void> onWindowClose() async {
    final bool windowMaximized = await windowManager.isMaximized();
    await sharedPrefsService!.put(
      kWindowMaximizedKey,
      windowMaximized,
    );

    if (windowMaximized != true) {
      final Size windowSize = await windowManager.getSize();
      await sharedPrefsService!.put(
        kWindowSizeWidthKey,
        windowSize.width,
      );
      await sharedPrefsService!.put(
        kWindowSizeHeightKey,
        windowSize.height,
      );

      final Offset windowPosition = await windowManager.getPosition();
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
    await sl<HtlcSwapSyncService>().stop();
    await sl<HtlcSwapLocalStorageApi>().close();
    await NodeUtils.closeEmbeddedNode();
    await sl.reset();
    super.onWindowClose();
    deactivate();
    dispose();
    exit(0);
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    _trayIcon?.dispose();
    _trayIcon = null;
    super.dispose();
  }
}
