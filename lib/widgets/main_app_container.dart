import 'dart:async';
import 'dart:io';

import 'package:app_links/app_links.dart';
import 'package:clipboard_watcher/clipboard_watcher.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:logging/logging.dart';
import 'package:nested/nested.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/extensions/buildcontext_extension.dart';
import 'package:zenon_syrius_wallet_flutter/utils/account_block_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/address_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';
import 'package:zenon_syrius_wallet_flutter/utils/clipboard_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/utils/extensions.dart';
import 'package:zenon_syrius_wallet_flutter/utils/format_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:zenon_syrius_wallet_flutter/utils/notification_utils.dart';
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
      BlocProvider<SendTransactionBloc>(
        create: (_) => SendTransactionBloc(),
      ),
      BlocProvider<MultipleBalanceBloc>.value(
        value: sl.get<MultipleBalanceBloc>(),
      ),
      BlocProvider<PendingTransactionsBloc>.value(
        value: sl.get<PendingTransactionsBloc>(),
      ),
      BlocProvider<PillarRewardsHistoryBloc>(
        create: (_) =>
            PillarRewardsHistoryBloc(
              zenon: zenon!,
            )..add(
              FetchRequestData(
                address: Address.parse(kSelectedAddress!),
              ),
            ),
      ),
      BlocProvider<SentinelRewardsHistoryBloc>(
        create: (_) =>
            SentinelRewardsHistoryBloc(
              zenon: zenon!,
            )..add(
              FetchRequestData(
                address: Address.parse(kSelectedAddress!),
              ),
            ),
      ),
      BlocProvider<StakingRewardsHistoryBloc>(
        create: (_) =>
            StakingRewardsHistoryBloc(
              zenon: zenon!,
            )..add(
              FetchRequestData(
                address: Address.parse(kSelectedAddress!),
              ),
            ),
      ),
      BlocProvider<PillarsByOwnerBloc>(
        create: (_) =>
            PillarsByOwnerBloc(
              zenon: zenon!,
            )..add(
              FetchRequestData(
                address: Address.parse(kSelectedAddress!),
              ),
            ),
      ),
      BlocProvider<AllTokensBloc>(
        create: (_) => AllTokensBloc(
          zenon: zenon!,
        )..add(const AllTokensRequested()),
      ),
      BlocProvider<DelegationStatsBloc>(
        create: (_) => DelegationStatsBloc(zenon: zenon!)
          ..add(FetchRequestData(address: Address.parse(kSelectedAddress!))),
      ),
    ];

/// Primary application shell hosting desktop tab navigation and global BLoCs.
class MainAppContainer extends StatefulWidget {
  /// Creates a [MainAppContainer].
  const MainAppContainer({
    super.key,
    this.redirectedFromWalletSuccess = false,
  });

  /// Whether navigation arrived immediately after wallet onboarding succeeded.
  final bool redirectedFromWalletSuccess;

  /// Named route identifier for [MainAppContainer].
  static const String route = 'main-app-container';

  @override
  State<MainAppContainer> createState() => _MainAppContainerState();
}

class _MainAppContainerState extends State<MainAppContainer>
    with TickerProviderStateMixin, ClipboardListener, WindowListener {
  late AnimationController _animationController;
  late Animation<double> _animation;
  late StreamSubscription<WalletLockState> _lockBlockStreamSubscription;
  late StreamSubscription<Uri> _incomingLinkSubscription;
  late LockBloc _lockBloc;

  Timer? _navigateToLockTimer;
  TabController? _tabController;
  bool _initialUriIsHandled = false;

  final AppLinks _appLinks = AppLinks();
  final FocusNode _focusNode = FocusNode(
    skipTraversal: true,
    canRequestFocus: false,
  );
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
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _animationController.repeat(reverse: true);
    _animation = Tween<double>(begin: 1, end: 3).animate(_animationController);
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
      providers: buildMainAppContainerBlocProviders(),
      child: Consumer<TextScalingNotifier>(
        builder:
            (
              BuildContext context,
              TextScalingNotifier textScalingNotifier,
              Widget? child,
            ) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(
                  textScalingNotifier.getTextScaleFactor(context),
                ),
              ),
              child: Scaffold(
                body: Container(
                  margin: const EdgeInsets.all(
                    20,
                  ),
                  child: Column(
                    children: <Widget>[
                      _getDesktopNavigationContainer(),
                      SizedBox(
                        height: NotificationUtils.shouldShowNotification()
                            ? 15.0
                            : 20.0,
                      ),
                      NotificationWidget(
                        onSeeMorePressed: () {
                          _navigateTo(Tabs.notifications);
                        },
                        onDismissPressed: () {
                          setState(() {});
                        },
                        onNewNotificationCallback: () {
                          setState(() {});
                        },
                        popBeforeSeeMoreIsPressed: false,
                      ),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(
                            15,
                          ),
                          child: Container(
                            child: _getCurrentPageContainer(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
      ),
    );
  }

  Widget _getDesktopNavigationContainer() {
    final Color borderColor =
        NotificationUtils.activeNotification()?.getColor() ??
        Colors.transparent;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (BuildContext context, Widget? widget) {
        return Row(
          children: <Widget>[
            Expanded(
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.all(
                    Radius.circular(
                      15,
                    ),
                  ),
                  boxShadow: (borderColor != Colors.transparent)
                      ? <BoxShadow>[
                          BoxShadow(
                            color: borderColor,
                            blurRadius: _animation.value,
                            spreadRadius: _animation.value,
                          ),
                        ]
                      : <BoxShadow>[
                          const BoxShadow(
                            color: Colors.transparent,
                          ),
                        ],
                ),
                child: Material(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: const BorderRadius.all(
                    Radius.circular(
                      15,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                    ),
                    child: Focus(
                      focusNode: _focusNode,
                      onKeyEvent: (FocusNode focusNode, KeyEvent event) {
                        if ((event.physicalKey == PhysicalKeyboardKey.tab ||
                                event.physicalKey ==
                                    PhysicalKeyboardKey.enter ||
                                event.physicalKey ==
                                    PhysicalKeyboardKey.numpadEnter ||
                                event.physicalKey ==
                                    PhysicalKeyboardKey.space) &&
                            _isWalletLocked()) {
                          return KeyEventResult.handled;
                        }
                        return KeyEventResult.ignored;
                      },
                      child: IgnorePointer(
                        ignoring: _isWalletLocked(),
                        child: TabBar(
                          labelStyle: Theme.of(context).textTheme.headlineSmall!
                              .copyWith(
                                fontSize: 15,
                              ),
                          labelColor: Theme.of(
                            context,
                          ).textTheme.headlineSmall!.color,
                          onTap: (int index) {
                            if (_isTabSelected(Tabs.lock)) {
                              unawaited(_onNavigateToLock());
                            }
                          },
                          labelPadding: const EdgeInsets.symmetric(
                            vertical: 5,
                          ),
                          indicator: UnderlineTabIndicator(
                            borderSide: BorderSide(
                              color: NotificationUtils.shouldShowNotification()
                                  ? Colors.transparent
                                  : _isIconTabSelected()
                                  ? Colors.transparent
                                  : AppColors.znnColor,
                              width: 2,
                            ),
                          ),
                          dividerHeight: 0,
                          controller: _tabController,
                          tabs: _getTabs(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
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

  List<Tab> _getTabs() {
    return _getTextTabs() + _getIconTabs();
  }

  List<Tab> _getTextTabs() {
    return kTabsWithTextTitles
        .map<Tab>(
          (Tabs e) => e == Tabs.p2pSwap
              ? const Tab(text: 'P2P Swap')
              : Tab(
                  text: FormatUtils.extractNameFromEnum<Tabs>(e).capitalize(),
                ),
        )
        .toList();
  }

  List<Tab> _getIconTabs() {
    return <Tab>[
      if (kWcProjectId.isNotEmpty)
        Tab(
          child: SvgPicture.asset(
            'assets/svg/walletconnect-logo.svg',
            width: 24,
            fit: BoxFit.fitWidth,
            colorFilter: _isTabSelected(Tabs.walletConnect)
                ? const ColorFilter.mode(AppColors.znnColor, BlendMode.srcIn)
                : ColorFilter.mode(
                    Theme.of(context).iconTheme.color!,
                    BlendMode.srcIn,
                  ),
          ),
        ),
      Tab(
        child: Icon(
          MaterialCommunityIcons.rocket,
          size: 24,
          color: _isTabSelected(Tabs.accelerator)
              ? AppColors.znnColor
              : Theme.of(context).iconTheme.color,
        ),
      ),
      Tab(
        child: Icon(
          Icons.info,
          size: 24,
          color: _isTabSelected(Tabs.help)
              ? AppColors.znnColor
              : Theme.of(context).iconTheme.color,
        ),
      ),
      Tab(
        child: Icon(
          Icons.notifications,
          size: 24,
          color: _isTabSelected(Tabs.notifications)
              ? AppColors.znnColor
              : Theme.of(context).iconTheme.color,
        ),
      ),
      Tab(
        child: Icon(
          Icons.settings,
          size: 24,
          color: _isTabSelected(Tabs.settings)
              ? AppColors.znnColor
              : Theme.of(context).iconTheme.color,
        ),
      ),
      Tab(
        child: _getGenerationStatus(),
      ),
      Tab(
        child: BlocProvider<NodeSyncStatusCubit>.value(
          value: _nodeSyncStatusCubit,
          child: const NodeSyncStatusIcon(),
        ),
      ),
      Tab(
        child: _isTabSelected(Tabs.lock)
            ? Icon(
                Icons.lock,
                size: 24,
                color: _isTabSelected(Tabs.lock)
                    ? AppColors.znnColor
                    : Theme.of(context).iconTheme.color,
              )
            : Icon(
                MaterialCommunityIcons.lock_open_variant,
                size: 24,
                color: Theme.of(context).iconTheme.color,
              ),
      ),
    ];
  }

  Widget _getGenerationStatus() {
    return const PowGeneratingStatusIcon();
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
          onStepperNotificationSeeMorePressed: () => _navigateTo(
            Tabs.notifications,
          ),
          onNodeChangedCallback: () => _navigateTo(
            Tabs.dashboard,
          ),
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
      _tabController!.animateTo(_getTabChildIndex(Tabs.walletConnect));
    } else {
      _lockBloc.add(const LockNavigateToPreviousTabRequested());
    }
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    unawaited(_nodeSyncStatusCubit.close());
    _animationController.dispose();
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
      _tabController!.animateTo(_getTabChildIndex(Tabs.walletConnect));
    } else {
      _lockBloc.add(const LockNavigateToDashboardRequested());
    }
  }

  bool _isTabSelected(Tabs page) =>
      _tabController!.index == kTabs.indexOf(page);

  bool _isIconTabSelected() => kTabsWithIconTitles.contains(
    kTabs[_tabController!.index],
  );

  int _getTabChildIndex(Tabs page) => kTabs.indexOf(page);

  void _navigateTo(Tabs page) {
    if (kCurrentPage != page) {
      kCurrentPage = page;
      _tabController!.animateTo(kTabs.indexOf(page));
    }
  }

  void _initTabController() {
    _tabController = TabController(
      initialIndex: kWalletInitCompleted ? 0 : kTabs.length - 1,
      length: kTabs.length,
      vsync: this,
    );

    _tabController!.addListener(
      () {
        if (kDisabledTabs.contains(
          kTabs[_tabController!.index],
        )) {
          final int index = _tabController!.previousIndex;
          setState(() {
            _tabController!.index = index;
          });
        } else if (_tabController!.indexIsChanging) {
          kCurrentPage = kTabs[_tabController!.index];
        }
      },
    );
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
          _tabController!.animateTo(
            _getTabChildIndex(Tabs.lock),
          );
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
      uri.queryParametersAll.forEach((
        String key,
        List<String> value,
      ) async {
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
                    amount: queryAmount.extractDecimals(
                      token.decimals,
                    ),
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
                  amount: queryAmount.extractDecimals(
                    kQsrCoin.decimals,
                  ),
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
