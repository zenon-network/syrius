import 'dart:async';
import 'dart:io';

import 'package:app_links/app_links.dart';
import 'package:clipboard_watcher/clipboard_watcher.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:logging/logging.dart';
import 'package:nested/nested.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/extensions/buildcontext_extension.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/theming/syrius_theme_tokens.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/widgets/redesign/redesign.dart';
import 'package:zenon_syrius_wallet_flutter/utils/account_block_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/address_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/clipboard_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/utils/extensions.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:zenon_syrius_wallet_flutter/utils/notification_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/notifiers/app_ui_preferences_notifier.dart';
import 'package:zenon_syrius_wallet_flutter/utils/notifiers/text_scaling_notifier.dart';
import 'package:zenon_syrius_wallet_flutter/utils/wallet_connect_uri_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/wallet_file.dart';
import 'package:zenon_syrius_wallet_flutter/utils/zts_utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/tab_children_widgets/wallet_connect_tab_child.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// Top-level navigation tabs available in [MainAppContainer].
enum Tabs {
  /// Overview dashboard tab.
  dashboard,

  /// Token transfer tab.
  transfer,

  /// Help and support information tab.
  help,

  /// Wallet notifications history tab.
  notifications,

  /// Application settings tab.
  settings,

  /// Wallet lock screen tab.
  lock,

  /// Sentinels management tab.
  sentinels,

  /// Pillars management tab.
  pillars,

  /// Staking management tab.
  staking,

  /// Plasma fusion management tab.
  plasma,

  /// ZTS tokens management tab.
  tokens,

  /// Peer-to-peer swap tab.
  p2pSwap,

  /// Proof-of-work plasma generation status indicator slot.
  generation,

  /// Node synchronization status indicator slot.
  sync,

  /// Accelerator-Z proposals tab.
  accelerator,

  /// WalletConnect sessions and pairings tab.
  walletConnect,
}

/// Dispatches the initial [InfiniteListRequested] event to the singleton
/// transaction BLoCs when a wallet address is selected.
@visibleForTesting
void requestInitialTransactionsForAddress(String? selectedAddress) {
  if (selectedAddress == null || selectedAddress.isEmpty) {
    return;
  }
  final Address address = Address.parse(selectedAddress);
  if (sl.isRegistered<LatestTransactionsBloc>()) {
    final LatestTransactionsBloc latestTransactionsBloc = sl
        .get<LatestTransactionsBloc>();
    if (!latestTransactionsBloc.isClosed) {
      latestTransactionsBloc.add(InfiniteListRequested(address: address));
    }
  }
  if (sl.isRegistered<PendingTransactionsBloc>()) {
    final PendingTransactionsBloc pendingTransactionsBloc = sl
        .get<PendingTransactionsBloc>();
    if (!pendingTransactionsBloc.isClosed) {
      pendingTransactionsBloc.add(InfiniteListRequested(address: address));
    }
  }
}

/// Builds the [MultiBlocProvider] list for [MainAppContainer].
@visibleForTesting
List<SingleChildWidget> buildMainAppContainerBlocProviders() =>
    <SingleChildWidget>[
      BlocProvider<LatestTransactionsBloc>.value(
        value: sl.get<LatestTransactionsBloc>(),
      ),
      BlocProvider<SendTransactionBloc>(create: (_) => SendTransactionBloc()),
      BlocProvider<MultipleBalanceBloc>.value(
        value: sl.get<MultipleBalanceBloc>(),
      ),
      BlocProvider<PendingTransactionsBloc>.value(
        value: sl.get<PendingTransactionsBloc>(),
      ),
      BlocProvider<PillarRewardsHistoryBloc>(
        create: (_) => PillarRewardsHistoryBloc(zenon: zenon!)
          ..add(FetchRequestData(address: Address.parse(kSelectedAddress!))),
      ),
      BlocProvider<SentinelRewardsHistoryBloc>(
        create: (_) => SentinelRewardsHistoryBloc(zenon: zenon!)
          ..add(FetchRequestData(address: Address.parse(kSelectedAddress!))),
      ),
      BlocProvider<StakingRewardsHistoryBloc>(
        create: (_) => StakingRewardsHistoryBloc(zenon: zenon!)
          ..add(FetchRequestData(address: Address.parse(kSelectedAddress!))),
      ),
      BlocProvider<PillarsByOwnerBloc>(
        create: (_) => PillarsByOwnerBloc(zenon: zenon!)
          ..add(FetchRequestData(address: Address.parse(kSelectedAddress!))),
      ),
      BlocProvider<AllTokensBloc>(
        create: (_) =>
            AllTokensBloc(zenon: zenon!)..add(const AllTokensRequested()),
      ),
      BlocProvider<DelegationStatsBloc>(
        create: (_) => DelegationStatsBloc(zenon: zenon!)
          ..add(FetchRequestData(address: Address.parse(kSelectedAddress!))),
      ),
    ];

/// Primary application shell hosting desktop tab navigation and global BLoCs.
class MainAppContainer extends StatefulWidget {
  /// Creates a [MainAppContainer].
  const MainAppContainer({super.key, this.redirectedFromWalletSuccess = false});

  /// Whether navigation arrived immediately after wallet onboarding succeeded.
  final bool redirectedFromWalletSuccess;

  /// Named route identifier for [MainAppContainer].
  static const String route = 'main-app-container';

  @override
  State<MainAppContainer> createState() => _MainAppContainerState();
}

class _MainAppContainerState extends State<MainAppContainer>
    with TickerProviderStateMixin, ClipboardListener, WindowListener {
  late StreamSubscription<WalletLockState> _lockBlockStreamSubscription;
  late StreamSubscription<Uri> _incomingLinkSubscription;
  late LockBloc _lockBloc;

  Timer? _navigateToLockTimer;
  TabController? _tabController;
  bool _initialUriIsHandled = false;
  bool _notificationsDrawerOpen = false;

  final AppLinks _appLinks = AppLinks();
  final ShellNavigationController _shellNavigation =
      ShellNavigationController();
  final NodeSyncStatusCubit _nodeSyncStatusCubit = NodeSyncStatusCubit(
    syncMonitor: sl<NodeSyncMonitor>(),
    zenon: zenon!,
  );

  @override
  void initState() {
    clipboardWatcher.addListener(this);
    windowManager.addListener(this);

    ClipboardUtils.toggleClipboardWatcherStatus();

    _initTabController();
    kCurrentPage = kWalletInitCompleted ? Tabs.dashboard : Tabs.lock;
    if (kWalletInitCompleted) {
      requestInitialTransactionsForAddress(kSelectedAddress);
    }
    _initLockBlock();
    _handleIncomingLinks();
    if (kIsWeb || Platform.isLinux) {
      unawaited(_handleInitialUri());
    }

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: <SingleChildWidget>[
        ...buildMainAppContainerBlocProviders(),
        BlocProvider<NodeSyncStatusCubit>.value(value: _nodeSyncStatusCubit),
        Provider<ShellNavigationController>.value(value: _shellNavigation),
      ],
      child: Consumer2<TextScalingNotifier, AppUiPreferencesNotifier>(
        builder:
            (
              BuildContext context,
              TextScalingNotifier textScalingNotifier,
              AppUiPreferencesNotifier uiPrefs,
              Widget? child,
            ) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(
                  textScalingNotifier.getTextScaleFactor(context),
                ),
              ),
              child: CallbackShortcuts(
                bindings: _buildKeyboardShortcuts(context),
                child: Focus(
                  autofocus: true,
                  child: Scaffold(
                    backgroundColor: context.syriusTheme.shellBackground,
                    body: _buildShellBody(context, uiPrefs),
                  ),
                ),
              ),
            ),
      ),
    );
  }

  Map<ShortcutActivator, VoidCallback> _buildKeyboardShortcuts(
    BuildContext context,
  ) {
    if (_isOnLockScreen()) {
      return const <ShortcutActivator, VoidCallback>{};
    }
    return <ShortcutActivator, VoidCallback>{
      const SingleActivator(LogicalKeyboardKey.keyK, control: true): () =>
          unawaited(_openQuickNav(context)),
      const SingleActivator(LogicalKeyboardKey.keyK, meta: true): () =>
          unawaited(_openQuickNav(context)),
      const SingleActivator(LogicalKeyboardKey.digit1, control: true): () =>
          _navigateTo(Tabs.dashboard),
      const SingleActivator(LogicalKeyboardKey.digit2, control: true): () =>
          _navigateTo(Tabs.transfer),
      const SingleActivator(LogicalKeyboardKey.digit3, control: true): () =>
          _navigateTo(Tabs.staking),
      const SingleActivator(LogicalKeyboardKey.digit4, control: true): () =>
          _navigateTo(Tabs.pillars),
      const SingleActivator(LogicalKeyboardKey.digit5, control: true): () =>
          _navigateTo(Tabs.plasma),
      const SingleActivator(LogicalKeyboardKey.digit6, control: true): () =>
          _navigateTo(Tabs.tokens),
      const SingleActivator(LogicalKeyboardKey.digit7, control: true): () =>
          _navigateTo(Tabs.p2pSwap),
      const SingleActivator(LogicalKeyboardKey.digit8, control: true): () =>
          _navigateTo(Tabs.accelerator),
      const SingleActivator(LogicalKeyboardKey.keyL, control: true): _lockNow,
      const SingleActivator(LogicalKeyboardKey.keyR, control: true):
          _refreshCurrentData,
    };
  }

  bool _isOnLockScreen() {
    if (_tabController == null) {
      return !kWalletInitCompleted;
    }
    return kTabs[_tabController!.index] == Tabs.lock;
  }

  Widget _buildShellBody(
    BuildContext context,
    AppUiPreferencesNotifier uiPrefs,
  ) {
    final SyriusThemeTokens tokens = context.syriusTheme;
    final Tabs currentTab = kTabs[_tabController!.index];

    // Render Lock screen full-window without the navigation rail
    // (Screens 41–43).
    if (currentTab == Tabs.lock) {
      return LockTabChild(_mainLockCallback, _afterAppInitCallback);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _buildTopBrandBar(tokens),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              BlocBuilder<NotificationsBloc, NotificationsState>(
                builder: (_, NotificationsState nState) {
                  return SyriusNavigationRail(
                    activeTab: currentTab,
                    isExpanded: uiPrefs.sidebarExpanded,
                    hasUnreadNotifications: nState.hasActiveNotification,
                    isNotificationsOpen: _notificationsDrawerOpen,
                    onToggleExpanded: uiPrefs.toggleSidebarExpanded,
                    onTabSelected: (Tabs target) {
                      if (_notificationsDrawerOpen) {
                        setState(() => _notificationsDrawerOpen = false);
                      }
                      _navigateTo(target);
                    },
                    onNotificationsPressed: () {
                      setState(() {
                        _notificationsDrawerOpen = !_notificationsDrawerOpen;
                      });
                    },
                    onLockPressed: _lockNow,
                  );
                },
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Expanded(
                      child: Stack(
                        children: <Widget>[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(4, 0, 14, 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: <Widget>[
                                NotificationWidget(
                                  onSeeMorePressed: () {
                                    setState(() {
                                      _notificationsDrawerOpen = true;
                                    });
                                  },
                                  onDismissPressed: () {
                                    setState(() {});
                                  },
                                  onNewNotificationCallback: () {
                                    setState(() {});
                                  },
                                  popBeforeSeeMoreIsPressed: false,
                                ),
                                Expanded(child: _getCurrentPageContainer()),
                              ],
                            ),
                          ),
                          if (_notificationsDrawerOpen) ...<Widget>[
                            Positioned.fill(
                              child: GestureDetector(
                                onTap: () => setState(
                                  () => _notificationsDrawerOpen = false,
                                ),
                                child: ColoredBox(
                                  color: Colors.black.withValues(alpha: 0.25),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 0,
                              bottom: 0,
                              right: 0,
                              child: SyriusNotificationDrawer(
                                onClose: () => setState(
                                  () => _notificationsDrawerOpen = false,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(4, 0, 14, 12),
                      child: SyriusStatusStrip(
                        onNodePressed: () {
                          _shellNavigation.requestSettingsSection(
                            SettingsSection.node,
                          );
                          _navigateTo(Tabs.settings);
                        },
                        onQuickNavPressed: () =>
                            unawaited(_openQuickNav(context)),
                        onUpdatePressed: () {
                          _shellNavigation.requestSettingsSection(
                            SettingsSection.about,
                          );
                          _navigateTo(Tabs.settings);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTopBrandBar(SyriusThemeTokens tokens) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: Alignment.centerLeft,
      child: Text(
        'S Y R I U S',
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w500,
          letterSpacing: 3.2,
          color: tokens.textMuted,
        ),
      ),
    );
  }

  void _lockNow() {
    if (_notificationsDrawerOpen) {
      setState(() => _notificationsDrawerOpen = false);
    }
    unawaited(_onNavigateToLock());
    _navigateTo(Tabs.lock);
  }

  void _refreshCurrentData() {
    if (kSelectedAddress != null && kSelectedAddress!.isNotEmpty) {
      requestInitialTransactionsForAddress(kSelectedAddress);
    }
    if (sl.isRegistered<MultipleBalanceBloc>() &&
        kDefaultAddressList.isNotEmpty) {
      sl<MultipleBalanceBloc>().add(
        MultipleBalanceFetch(
          addresses: kDefaultAddressList.whereType<String>().toList(),
        ),
      );
    }
  }

  Future<void> _openQuickNav(BuildContext context) async {
    final AppUiPreferencesNotifier uiPrefs = context
        .read<AppUiPreferencesNotifier>();
    final List<QuickNavCommand> commands = buildDefaultQuickNavCommands(
      context: context,
      contacts: uiPrefs.contacts,
    );
    final QuickNavCommand? selected = await showSyriusQuickNavDialog(
      context: context,
      commands: commands,
    );
    if (!mounted || selected == null) {
      return;
    }
    if (selected.id == 'action_toggle_privacy') {
      uiPrefs.toggleHideBalances();
      return;
    }
    if (selected.address != null) {
      _shellNavigation.requestTransfer(
        mode: TransferMode.send,
        recipientAddress: selected.address,
      );
      _navigateTo(Tabs.transfer);
      return;
    }
    if (selected.tab == Tabs.lock) {
      _lockNow();
      return;
    }
    if (selected.tab != null) {
      _navigateTo(selected.tab!);
    }
  }

  Future<void> _onNavigateToLock() async {
    final WalletFile? walletFile = kWalletFile;
    kWalletFile = null;
    _navigateToLockTimer?.cancel();
    if (walletFile != null) {
      await walletFile.close();
    }
  }

  bool _isWalletLocked() {
    return _navigateToLockTimer == null ||
        _navigateToLockTimer != null && !_navigateToLockTimer!.isActive;
  }

  Widget _getCurrentPageContainer() {
    return TabBarView(
      physics: const NeverScrollableScrollPhysics(),
      controller: _tabController,
      children: <Widget>[
        DashboardTabChild(changePage: _navigateTo),
        const TransferTabChild(),
        PillarsTabChild(
          onStepperNotificationSeeMorePressed: () =>
              _navigateTo(Tabs.notifications),
        ),
        SentinelsTabChild(
          onStepperNotificationSeeMorePressed: () =>
              _navigateTo(Tabs.notifications),
        ),
        const StakingTabChild(),
        const PlasmaTabChild(),
        TokensTabChild(
          onStepperNotificationSeeMorePressed: () =>
              _navigateTo(Tabs.notifications),
        ),
        const P2pSwapTabChild(),
        if (kWcProjectId.isNotEmpty) const WalletConnectTabChild(),
        AcceleratorTabChild(
          onStepperNotificationSeeMorePressed: () =>
              _navigateTo(Tabs.notifications),
        ),
        const HelpTabChild(),
        const NotificationsCard(),
        SettingsTabChild(
          _onChangeAutoLockTime,
          onStepperNotificationSeeMorePressed: () =>
              _navigateTo(Tabs.notifications),
          onNodeChangedCallback: () => _navigateTo(Tabs.dashboard),
        ),
        const SizedBox(),
        const SizedBox(),
        LockTabChild(_mainLockCallback, _afterAppInitCallback),
      ],
    );
  }

  Future<void> _mainLockCallback(String password) async {
    _navigateToLockTimer = _createAutoLockTimer();
    if (kLastWalletConnectUriNotifier.value != null) {
      _shellNavigation.requestSettingsSection(SettingsSection.apps);
      _tabController!.animateTo(_getTabChildIndex(Tabs.walletConnect));
    } else {
      _lockBloc.add(const LockNavigateToPreviousTabRequested());
    }
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    unawaited(_nodeSyncStatusCubit.close());
    _shellNavigation.dispose();
    _navigateToLockTimer?.cancel();
    unawaited(_lockBlockStreamSubscription.cancel());
    unawaited(_incomingLinkSubscription.cancel());
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _onChangeAutoLockTime() async {
    await sl.get<NotificationsBloc>().addNotification(
      WalletNotification(
        title: 'Auto-lock interval changed successfully',
        details:
            'Auto-lock interval changed successfully to '
            '$kAutoLockWalletMinutes minutes.',
        timestamp: DateTime.now().millisecondsSinceEpoch,
        type: NotificationType.autoLockIntervalChanged,
      ),
    );
    _lockBloc.add(const LockTimerResetRequested());
  }

  void _afterAppInitCallback() {
    unawaited(_nodeSyncStatusCubit.fetchDataPeriodically());
    requestInitialTransactionsForAddress(kSelectedAddress);
    _navigateToLockTimer = _createAutoLockTimer();
    if (kLastWalletConnectUriNotifier.value != null) {
      _shellNavigation.requestSettingsSection(SettingsSection.apps);
      _tabController!.animateTo(_getTabChildIndex(Tabs.walletConnect));
    } else {
      _lockBloc.add(const LockNavigateToDashboardRequested());
    }
  }

  int _getTabChildIndex(Tabs page) => kTabs.indexOf(page);

  void _navigateTo(Tabs page) {
    Tabs target = page;
    if (target == Tabs.walletConnect) {
      _shellNavigation.requestSettingsSection(SettingsSection.apps);
      target = Tabs.settings;
    } else if (target == Tabs.help) {
      _shellNavigation.requestSettingsSection(SettingsSection.about);
      target = Tabs.settings;
    }
    if (kCurrentPage != target) {
      kCurrentPage = target;
      setState(() {
        _tabController!.animateTo(kTabs.indexOf(target));
      });
    }
  }

  void _initTabController() {
    _tabController = TabController(
      initialIndex: kWalletInitCompleted ? 0 : kTabs.length - 1,
      length: kTabs.length,
      vsync: this,
    );

    _tabController!.addListener(() {
      if (kDisabledTabs.contains(kTabs[_tabController!.index])) {
        final int index = _tabController!.previousIndex;
        setState(() {
          _tabController!.index = index;
        });
      } else {
        final Tabs next = kTabs[_tabController!.index];
        if (kCurrentPage != next) {
          setState(() {
            kCurrentPage = next;
          });
        }
      }
    });
  }

  void _initLockBlock() {
    _lockBloc = context.read<LockBloc>();
    _lockBlockStreamSubscription = _lockBloc.stream.listen((
      WalletLockState state,
    ) {
      switch (state.action) {
        case LockAction.initial:
          break;
        case LockAction.countDown:
          if (kCurrentPage != Tabs.lock) {
            _navigateToLockTimer = _createAutoLockTimer();
          }
        case LockAction.navigateToDashboard:
          _tabController!.animateTo(_getTabChildIndex(Tabs.dashboard));
        case LockAction.navigateToLock:
          if (mounted && Navigator.of(context).canPop()) {
            Navigator.popUntil(
              context,
              ModalRoute.withName(MainAppContainer.route),
            );
          }
          unawaited(_onNavigateToLock());
          _tabController!.animateTo(_getTabChildIndex(Tabs.lock));
        case LockAction.resetTimer:
          if (_navigateToLockTimer != null && _navigateToLockTimer!.isActive) {
            _navigateToLockTimer?.cancel();
            _navigateToLockTimer = _createAutoLockTimer();
          }
        case LockAction.navigateToPreviousTab:
          _tabController!.animateTo(_tabController!.previousIndex);
      }
    });
    if (widget.redirectedFromWalletSuccess) {
      _lockBloc.add(const LockCountDownRequested());
    }
  }

  Timer _createAutoLockTimer() {
    return Timer.periodic(Duration(minutes: kAutoLockWalletMinutes!), (
      Timer timer,
    ) async {
      if (!await sl<HtlcSwapSyncService>().hasActiveIncomingSwaps() &&
          mounted &&
          timer.isActive &&
          identical(_navigateToLockTimer, timer)) {
        _lockBloc.add(const LockNavigateToLockRequested());
      }
    });
  }

  void _handleIncomingLinks() {
    if (!kIsWeb && !Platform.isLinux) {
      _incomingLinkSubscription = _appLinks.uriLinkStream.listen(
        (Uri? uri) async {
          if (uri != null) {
            await _handleIncomingUri(uri);
          }
        },
        onDone: () {
          Logger(
            'MainAppContainer',
          ).log(Level.INFO, '_handleIncomingLinks', 'done');
        },
        onError: (Object err) async {
          await NotificationUtils.sendNotificationError(
            err,
            'Handle incoming link failed',
          );
          Logger(
            'MainAppContainer',
          ).log(Level.WARNING, '_handleIncomingLinks', err);
          if (!mounted) return;
        },
      );
    }
  }

  Future<void> _handleIncomingUri(Uri uri) async {
    if (!await windowManager.isFocused() || !await windowManager.isVisible()) {
      await windowManager.show();
    }

    final String uriRaw = uri.toString();

    Logger('MainAppContainer').log(Level.INFO, '_handleIncomingUri $uriRaw');

    if (!context.mounted) {
      return;
    }

    final String? wcUri = extractWalletConnectUri(
      uriRaw,
      isWindows: Platform.isWindows,
    );
    if (wcUri != null) {
      await _updateWalletConnectUri(wcUri);
      return;
    }

    // Deep link query parameters
    String queryAddress = '';
    String queryAmount = ''; // with decimals
    int queryDuration = 0; // in months
    String queryZTS = '';
    String queryPillarName = '';
    Token? token;

    if (uri.hasQuery) {
      uri.queryParametersAll.forEach((String key, List<String> value) async {
        if (key == 'amount') {
          queryAmount = value.first;
        } else if (key == 'zts') {
          queryZTS = value.first;
        } else if (key == 'address') {
          queryAddress = value.first;
        } else if (key == 'duration') {
          queryDuration = int.parse(value.first);
        } else if (key == 'pillar') {
          queryPillarName = value.first;
        }
      });
    }

    if (queryZTS.isNotEmpty) {
      if (queryZTS == 'znn' || queryZTS == 'ZNN') {
        token = kZnnCoin;
      } else if (queryZTS == 'qsr' || queryZTS == 'QSR') {
        token = kQsrCoin;
      } else {
        token = await zenon!.embedded.token.getByZts(
          TokenStandard.parse(queryZTS),
        );
      }
    }

    final SendTransactionBloc sendTransactionBloc = SendTransactionBloc();
    final DelegationBloc delegationBloc = DelegationBloc(
      accountBlockUtils: AccountBlockUtils(),
      zenon: zenon!,
    );
    final FusePlasmaBloc fusePlasmaBloc = FusePlasmaBloc(
      accountBlockUtils: AccountBlockUtils(),
      zenon: zenon!,
      zenonAddressUtils: ZenonAddressUtils(),
    );

    if (context.mounted) {
      switch (uri.host) {
        case 'transfer':
          await sl<NotificationsBloc>().addNotification(
            WalletNotification(
              title: 'Transfer action detected',
              timestamp: DateTime.now().millisecondsSinceEpoch,
              details: 'Deep link: $uriRaw',
              type: NotificationType.paymentReceived,
            ),
          );
          if (!mounted) return;

          if (kCurrentPage != Tabs.lock) {
            _navigateTo(Tabs.transfer);

            if (token != null) {
              final bool? actionAccepted = await showDialogWithNoAndYesOptions(
                context: context,
                title: 'Transfer action',
                isBarrierDismissible: true,
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Text(
                      'Are you sure you want transfer $queryAmount '
                      '${token.symbol} from $kSelectedAddress to '
                      '$queryAddress?',
                    ),
                  ],
                ),
              );
              if (!mounted) return;

              if (actionAccepted ?? false) {
                context.read<SendTransactionBloc>().add(
                  SendTransactionInitiate(
                    fromAddress: kSelectedAddress!,
                    toAddress: queryAddress,
                    amount: queryAmount.extractDecimals(token.decimals),
                    token: token,
                  ),
                );
              }
            }
          }
        case 'stake':
          await sl<NotificationsBloc>().addNotification(
            WalletNotification(
              title: 'Stake action detected',
              timestamp: DateTime.now().millisecondsSinceEpoch,
              details: 'Deep link: $uriRaw',
              type: NotificationType.paymentReceived,
            ),
          );
          if (!mounted) return;

          if (kCurrentPage != Tabs.lock) {
            _navigateTo(Tabs.staking);

            final bool? actionAccepted = await showDialogWithNoAndYesOptions(
              context: context,
              title: 'Stake ${kZnnCoin.symbol} action',
              isBarrierDismissible: true,
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    'Are you sure you want stake $queryAmount '
                    '${kZnnCoin.symbol} for $queryDuration month(s)?',
                  ),
                ],
              ),
            );
            if (!mounted) return;

            if (actionAccepted ?? false) {
              final AccountBlockTemplate block = zenon!.embedded.stake.stake(
                queryDuration * stakeTimeUnitSec,
                queryAmount.extractDecimals(kZnnCoin.decimals),
              );

              sendTransactionBloc.add(
                SendTransactionInitiateFromBlock(
                  block: block,
                  fromAddress: kSelectedAddress!,
                  reasonForGeneratingPlasma: context.l10n.createStake,
                ),
              );
            }
          }

        case 'delegate':
          await sl<NotificationsBloc>().addNotification(
            WalletNotification(
              title: 'Delegate action detected',
              timestamp: DateTime.now().millisecondsSinceEpoch,
              details: 'Deep link: $uriRaw',
              type: NotificationType.paymentReceived,
            ),
          );
          if (!mounted) return;

          if (kCurrentPage != Tabs.lock) {
            _navigateTo(Tabs.pillars);

            final bool? actionAccepted = await showDialogWithNoAndYesOptions(
              context: context,
              title: 'Delegate ${kZnnCoin.symbol} action',
              isBarrierDismissible: true,
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    'Are you sure you want delegate the ${kZnnCoin.symbol} '
                    'from $kSelectedAddress to Pillar $queryPillarName?',
                  ),
                ],
              ),
            );

            if (actionAccepted ?? false) {
              delegationBloc.add(
                DelegationRequested(
                  address: Address.parse(kSelectedAddress!),
                  pillarName: queryPillarName,
                ),
              );
            }
          }

        case 'fuse':
          await sl<NotificationsBloc>().addNotification(
            WalletNotification(
              title: 'Fuse ${kQsrCoin.symbol} action detected',
              timestamp: DateTime.now().millisecondsSinceEpoch,
              details: 'Deep link: $uriRaw',
              type: NotificationType.paymentReceived,
            ),
          );
          if (!mounted) return;

          if (kCurrentPage != Tabs.lock) {
            _navigateTo(Tabs.plasma);

            final bool? actionAccepted = await showDialogWithNoAndYesOptions(
              context: context,
              title: 'Fuse ${kQsrCoin.symbol} action',
              isBarrierDismissible: true,
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    'Are you sure you want fuse $queryAmount '
                    '${kQsrCoin.symbol} for address $queryAddress?',
                  ),
                ],
              ),
            );

            if (actionAccepted ?? false) {
              fusePlasmaBloc.add(
                FusePlasmaRequested(
                  beneficiaryAddress: queryAddress,
                  amount: queryAmount.extractDecimals(kQsrCoin.decimals),
                ),
              );
            }
          }

        case 'sentinel':
          await sl<NotificationsBloc>().addNotification(
            WalletNotification(
              title: 'Deploy Sentinel action detected',
              timestamp: DateTime.now().millisecondsSinceEpoch,
              details: 'Deep link: $uriRaw',
              type: NotificationType.paymentReceived,
            ),
          );

          if (kCurrentPage != Tabs.lock) {
            _navigateTo(Tabs.sentinels);
          }

        case 'pillar':
          await sl<NotificationsBloc>().addNotification(
            WalletNotification(
              title: 'Deploy Pillar action detected',
              timestamp: DateTime.now().millisecondsSinceEpoch,
              details: 'Deep link: $uriRaw',
              type: NotificationType.paymentReceived,
            ),
          );

          if (kCurrentPage != Tabs.lock) {
            _navigateTo(Tabs.pillars);
          }

        default:
          await sl<NotificationsBloc>().addNotification(
            WalletNotification(
              title: 'Incoming link detected',
              timestamp: DateTime.now().millisecondsSinceEpoch,
              details: 'Deep link: $uriRaw',
              type: NotificationType.paymentReceived,
            ),
          );
      }
    }
  }

  Future<void> _handleInitialUri() async {
    if (!_initialUriIsHandled) {
      _initialUriIsHandled = true;
      try {
        final Uri? uri = await _appLinks.getInitialLink();
        if (!mounted) return;
        if (uri != null) {
          Logger('MainAppContainer').log(Level.INFO, '_handleInitialUri $uri');
          await _handleIncomingUri(uri);
        }
      } on PlatformException catch (e, stackTrace) {
        Logger('MainAppContainer').log(
          Level.WARNING,
          '_handleInitialUri PlatformException',
          e,
          stackTrace,
        );
      } on FormatException catch (e, stackTrace) {
        Logger('MainAppContainer').log(
          Level.WARNING,
          '_handleInitialUri FormatException',
          e,
          stackTrace,
        );
        if (!mounted) return;
      }
    }
  }

  @override
  Future<void> onClipboardChanged() async {
    final ClipboardData? newClipboardData = await Clipboard.getData(
      Clipboard.kTextPlain,
    );
    final String text = newClipboardData?.text ?? '';
    final String? wcUri = extractWalletConnectUri(
      text,
      isWindows: Platform.isWindows,
    );
    if (wcUri != null) {
      // This check is needed because onClipboardChanged is sometimes called
      // twice.
      if (kLastWalletConnectUriNotifier.value != wcUri) {
        await _updateWalletConnectUri(wcUri);
      }
    }
  }

  Future<void> _updateWalletConnectUri(String text) async {
    kLastWalletConnectUriNotifier.value = text;
    if (!_isWalletLocked()) {
      if (kCurrentPage != Tabs.walletConnect) {
        await sl<NotificationsBloc>().addNotification(
          WalletNotification(
            title:
                'WalletConnect link detected. '
                'Go to WalletConnect tab to connect.',
            timestamp: DateTime.now().millisecondsSinceEpoch,
            details:
                'A WalletConnect link has been copied to clipboard. '
                'Go to the WalletConnect tab to connect to the dApp through '
                '$text',
            type: NotificationType.copiedToClipboard,
          ),
        );
        _navigateTo(Tabs.walletConnect);
      }
    }
  }
}
