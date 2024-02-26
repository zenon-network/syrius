import 'dart:async';
import 'dart:io';

import 'package:app_links/app_links.dart';
import 'package:clipboard_watcher/clipboard_watcher.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:logging/logging.dart';
import 'package:provider/provider.dart';
import 'package:wallet_connect_uri_validator/wallet_connect_uri_validator.dart';
import 'package:window_manager/window_manager.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/handlers/htlc_swaps_handler.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/services/wallet_connect_service.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';
import 'package:zenon_syrius_wallet_flutter/utils/clipboard_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/utils/extensions.dart';
import 'package:zenon_syrius_wallet_flutter/utils/format_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:zenon_syrius_wallet_flutter/utils/notification_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/notifiers/text_scaling_notifier.dart';
import 'package:zenon_syrius_wallet_flutter/utils/zts_utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/tab_children_widgets/wallet_connect_tab_child.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

enum Tabs {
  dashboard,
  transfer,
  help,
  notifications,
  settings,
  lock,
  sentinels,
  pillars,
  staking,
  plasma,
  tokens,
  p2pSwap,
  resyncWallet,
  accelerator,
  walletConnect,
}

class MainAppContainer extends StatefulWidget {
  final bool redirectedFromWalletSuccess;

  static const String route = 'main-app-container';

  const MainAppContainer({
    Key? key,
    this.redirectedFromWalletSuccess = false,
  }) : super(key: key);

  @override
  State<MainAppContainer> createState() => _MainAppContainerState();
}

class _MainAppContainerState extends State<MainAppContainer>
    with TickerProviderStateMixin, ClipboardListener, WindowListener {
  late AnimationController _animationController;
  late Animation _animation;

  final NodeSyncStatusBloc _netSyncStatusBloc = NodeSyncStatusBloc();

  late StreamSubscription _lockBlockStreamSubscription;
  late StreamSubscription _incomingLinkSubscription;

  Timer? _navigateToLockTimer;

  late LockBloc _lockBloc;

  TabController? _tabController;

  TransferTabChild? _transferTabChild;

  final FocusNode _focusNode = FocusNode(
    skipTraversal: true,
    canRequestFocus: false,
  );

  bool _initialUriIsHandled = false;

  final _appLinks = AppLinks();

  @override
  void initState() {
    sl<WalletConnectService>().context = context;

    clipboardWatcher.addListener(this);
    windowManager.addListener(this);

    ClipboardUtils.toggleClipboardWatcherStatus();

    _netSyncStatusBloc.getDataPeriodically();

    _transferTabChild = TransferTabChild();
    _initTabController();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _animationController.repeat(reverse: true);
    _animation = Tween(begin: 1.0, end: 3.0).animate(_animationController);
    kCurrentPage = kWalletInitCompleted ? Tabs.dashboard : Tabs.lock;
    _initLockBlock();
    _handleIncomingLinks();
    _handleInitialUri();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<TextScalingNotifier>(
      builder: (context, textScalingNotifier, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaleFactor: textScalingNotifier.getTextScaleFactor(context),
        ),
        child: Scaffold(
          body: Container(
            margin: const EdgeInsets.all(
              20.0,
            ),
            child: Column(
              children: <Widget>[
                _getDesktopNavigationContainer(),
                SizedBox(
                  height:
                      NotificationUtils.shouldShowNotification() ? 15.0 : 20.0,
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
                      15.0,
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
    );
  }

  Widget _getDesktopNavigationContainer() {
    Color borderColor = NotificationUtils.shouldShowNotification()
        ? kLastNotification!.getColor()
        : Colors.transparent;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, widget) {
        return Row(
          children: [
            Expanded(
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.all(
                    Radius.circular(
                      15.0,
                    ),
                  ),
                  boxShadow: (borderColor != Colors.transparent)
                      ? [
                          BoxShadow(
                            color: borderColor,
                            blurRadius: _animation.value,
                            spreadRadius: _animation.value,
                          )
                        ]
                      : [
                          const BoxShadow(
                            color: Colors.transparent,
                          )
                        ],
                ),
                child: Material(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: const BorderRadius.all(
                    Radius.circular(
                      15.0,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10.0,
                    ),
                    child: Focus(
                      focusNode: _focusNode,
                      onKeyEvent: (focusNode, KeyEvent event) {
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
                          labelStyle: Theme.of(context)
                              .textTheme
                              .headlineSmall!
                              .copyWith(
                                fontSize: 15.0,
                              ),
                          labelColor:
                              Theme.of(context).textTheme.headlineSmall!.color,
                          onTap: (int index) {
                            if (_isTabSelected(Tabs.lock)) {
                              _onNavigateToLock();
                            }
                          },
                          labelPadding: const EdgeInsets.symmetric(
                            vertical: 5.0,
                          ),
                          indicator: UnderlineTabIndicator(
                            borderSide: BorderSide(
                              color: NotificationUtils.shouldShowNotification()
                                  ? Colors.transparent
                                  : _isIconTabSelected()
                                      ? Colors.transparent
                                      : AppColors.znnColor,
                              width: 2.0,
                            ),
                          ),
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

  void _onNavigateToLock() async {
    if (kWalletFile != null) kWalletFile!.close();
    kWalletFile = null;
    _navigateToLockTimer?.cancel();
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
          (e) => e == Tabs.p2pSwap
              ? const Tab(text: 'P2P Swap')
              : Tab(
                  text: FormatUtils.extractNameFromEnum<Tabs>(e).capitalize()),
        )
        .toList();
  }

  List<Tab> _getIconTabs() {
    return <Tab>[
      if (kWcProjectId.isNotEmpty)
        Tab(
          child: SvgPicture.asset(
            'assets/svg/walletconnect-logo.svg',
            width: 24.0,
            fit: BoxFit.fitWidth,
            colorFilter: _isTabSelected(Tabs.walletConnect)
                ? const ColorFilter.mode(AppColors.znnColor, BlendMode.srcIn)
                : ColorFilter.mode(
                    Theme.of(context).iconTheme.color!, BlendMode.srcIn),
          ),
        ),
      Tab(
        child: Icon(
          MaterialCommunityIcons.rocket,
          size: 24.0,
          color: _isTabSelected(Tabs.accelerator)
              ? AppColors.znnColor
              : Theme.of(context).iconTheme.color,
        ),
      ),
      Tab(
        child: Icon(
          Icons.info,
          size: 24.0,
          color: _isTabSelected(Tabs.help)
              ? AppColors.znnColor
              : Theme.of(context).iconTheme.color,
        ),
      ),
      Tab(
        child: Icon(
          Icons.notifications,
          size: 24.0,
          color: _isTabSelected(Tabs.notifications)
              ? AppColors.znnColor
              : Theme.of(context).iconTheme.color,
        ),
      ),
      Tab(
        child: Icon(
          Icons.settings,
          size: 24.0,
          color: _isTabSelected(Tabs.settings)
              ? AppColors.znnColor
              : Theme.of(context).iconTheme.color,
        ),
      ),
      Tab(
        child: _getPowGeneratingStatus(),
      ),
      Tab(
        child: _isTabSelected(Tabs.lock)
            ? Icon(
                Icons.lock,
                size: 24.0,
                color: _isTabSelected(Tabs.lock)
                    ? AppColors.znnColor
                    : Theme.of(context).iconTheme.color,
              )
            : Icon(
                MaterialCommunityIcons.lock_open_variant,
                size: 24.0,
                color: Theme.of(context).iconTheme.color,
              ),
      ),
    ];
  }

  Widget _getWebsocketConnectionStatusStreamBuilder() {
    return StreamBuilder<SyncInfo>(
      stream: _netSyncStatusBloc.stream,
      builder: (_, snapshot) {
        if (snapshot.hasError) {
          return _getSyncingStatusIcon(SyncState.unknown);
        } else if (snapshot.hasData) {
          return _getSyncingStatusIcon(snapshot.data!.state, snapshot.data);
        } else {
          return _getSyncingStatusIcon(SyncState.unknown);
        }
      },
    );
  }

  Widget _getSyncingStatusIcon(SyncState syncState, [SyncInfo? syncInfo]) {
    var message = 'Connected and synced';

    if (syncState != SyncState.notEnoughPeers &&
        syncState != SyncState.syncDone &&
        syncState != SyncState.syncing &&
        syncState != SyncState.unknown) {
      syncState = SyncState.unknown;
    }

    if (syncState == SyncState.unknown) {
      message = 'Not ready';
    } else if (syncState == SyncState.syncing) {
      if (syncInfo != null) {
        if (syncInfo.targetHeight > 0 &&
            syncInfo.currentHeight > 0 &&
            (syncInfo.targetHeight - syncInfo.currentHeight) < 3) {
          message = 'Connected and synced';
          syncState = SyncState.syncDone;
        } else {
          message =
              'Sync progress: momentum ${syncInfo.currentHeight} of ${syncInfo.targetHeight}';
        }
      } else {
        message = 'Syncing momentums';
      }
    } else if (syncState == SyncState.notEnoughPeers) {
      if (syncInfo != null) {
        if (syncInfo.targetHeight > 0 &&
            syncInfo.currentHeight > 0 &&
            (syncInfo.targetHeight - syncInfo.currentHeight) < 20) {
          message = 'Connecting to peers';
          syncState = SyncState.syncing;
        } else if (syncInfo.targetHeight == 0 || syncInfo.currentHeight == 0) {
          message = 'Connecting to peers';
          syncState = SyncState.syncing;
        } else {
          message =
              'Sync progress: momentum ${syncInfo.currentHeight} of ${syncInfo.targetHeight}';
          syncState = SyncState.syncing;
        }
      } else {
        message = 'Connecting to peers';
        syncState = SyncState.syncing;
      }
    } else {
      message = 'Connected and synced';
      syncState = SyncState.syncDone;
    }

    return Tooltip(
      message: message,
      child: Icon(
        Icons.radio_button_unchecked,
        size: 24.0,
        color: _getSyncIconColor(syncState),
      ),
    );
  }

  Widget _getCurrentPageContainer() {
    return TabBarView(
      physics: const NeverScrollableScrollPhysics(),
      controller: _tabController,
      children: [
        DashboardTabChild(changePage: _navigateTo),
        _transferTabChild!,
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
        P2pSwapTabChild(
          onStepperNotificationSeeMorePressed: () =>
              _navigateTo(Tabs.notifications),
        ),
        if (kWcProjectId.isNotEmpty) const WalletConnectTabChild(),
        AcceleratorTabChild(
          onStepperNotificationSeeMorePressed: () =>
              _navigateTo(Tabs.notifications),
        ),
        const HelpTabChild(),
        const NotificationsTabChild(),
        SettingsTabChild(
          _onChangeAutoLockTime,
          _onResyncWalletPressed,
          onStepperNotificationSeeMorePressed: () => _navigateTo(
            Tabs.notifications,
          ),
          onNodeChangedCallback: () => _navigateTo(
            Tabs.dashboard,
          ),
        ),
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
      _lockBloc.addEvent(LockEvent.navigateToPreviousTab);
    }
  }

  @override
  void dispose() {
    windowManager.removeListener(this);

    _animationController.dispose();
    _netSyncStatusBloc.dispose();
    _navigateToLockTimer?.cancel();
    _lockBlockStreamSubscription.cancel();
    _incomingLinkSubscription.cancel();
    _tabController?.dispose();
    super.dispose();
  }

  void _onChangeAutoLockTime() {
    sl.get<NotificationsBloc>().addNotification(
          WalletNotification(
            title: 'Auto-lock interval changed successfully',
            details: 'Auto-lock interval changed successfully to '
                '$kAutoLockWalletMinutes minutes.',
            timestamp: DateTime.now().millisecondsSinceEpoch,
            id: null,
            type: NotificationType.autoLockIntervalChanged,
          ),
        );
    _lockBloc.addEvent(LockEvent.resetTimer);
  }

  void _afterAppInitCallback() {
    _navigateToLockTimer = _createAutoLockTimer();
    if (kLastWalletConnectUriNotifier.value != null) {
      _tabController!.animateTo(_getTabChildIndex(Tabs.walletConnect));
    } else {
      _lockBloc.addEvent(LockEvent.navigateToDashboard);
    }
    _listenToAutoReceiveTxWorkerNotifications();
  }

  void _listenToAutoReceiveTxWorkerNotifications() {
    sl<AutoReceiveTxWorker>().stream.listen((event) {
      sl<NotificationsBloc>().addNotification(event);
    });
  }

  void _onResyncWalletPressed() {
    _navigateTo(Tabs.resyncWallet);
  }

  Widget _getPowGeneratingStatus() {
    return StreamBuilder<PowStatus>(
      stream: sl.get<PowGeneratingStatusBloc>().stream,
      builder: (_, snapshot) {
        if (snapshot.hasData && snapshot.data == PowStatus.generating) {
          return const Tooltip(
            message: 'Generating Plasma',
            child: SyriusLoadingWidget(
              size: 20.0,
              strokeWidth: 2.5,
            ),
          );
        }
        return _getWebsocketConnectionStatusStreamBuilder();
      },
    );
  }

  bool _isTabSelected(Tabs page) =>
      _tabController!.index == kTabs.indexOf(page);

  bool _isIconTabSelected() => kTabsWithIconTitles.contains(
        kTabs[_tabController!.index],
      );

  int _getTabChildIndex(Tabs page) => kTabs.indexOf(page);

  Color? _getSyncIconColor(SyncState syncState) {
    if (syncState == SyncState.syncDone) {
      return AppColors.znnColor;
    }
    if (syncState == SyncState.unknown) {
      return Theme.of(context).iconTheme.color;
    }
    if (syncState == SyncState.syncing) {
      return Colors.orange;
    }
    return AppColors.errorColor;
  }

  void _navigateTo(
    Tabs page, {
    bool redirectWithSendContainerLarge = false,
    bool redirectWithReceiveContainerLarge = false,
  }) {
    if (redirectWithSendContainerLarge) {
      _transferTabChild!.sendCard = DimensionCard.large;
      _transferTabChild!.receiveCard = DimensionCard.small;
    } else if (redirectWithReceiveContainerLarge) {
      _transferTabChild!.sendCard = DimensionCard.small;
      _transferTabChild!.receiveCard = DimensionCard.large;
    }
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
          int index = _tabController!.previousIndex;
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
    _lockBloc = Provider.of<LockBloc>(context, listen: false);
    _lockBlockStreamSubscription = _lockBloc.stream.listen((event) {
      switch (event) {
        case LockEvent.countDown:
          if (kCurrentPage != Tabs.lock) {
            _navigateToLockTimer = _createAutoLockTimer();
          }
          break;
        case LockEvent.navigateToDashboard:
          _tabController!.animateTo(_getTabChildIndex(Tabs.dashboard));
          break;
        case LockEvent.navigateToLock:
          if (Navigator.of(context).canPop()) {
            Navigator.popUntil(
              context,
              ModalRoute.withName(MainAppContainer.route),
            );
          }
          _onNavigateToLock();
          _tabController!.animateTo(
            _getTabChildIndex(Tabs.lock),
          );
          break;
        case LockEvent.resetTimer:
          if (_navigateToLockTimer != null && _navigateToLockTimer!.isActive) {
            _navigateToLockTimer?.cancel();
            _navigateToLockTimer = _createAutoLockTimer();
          }
          break;
        case LockEvent.navigateToPreviousTab:
          _tabController!.animateTo(_tabController!.previousIndex);
          break;
      }
    });
    if (widget.redirectedFromWalletSuccess) {
      _lockBloc.addEvent(LockEvent.countDown);
    }
  }

  Timer _createAutoLockTimer() {
    return Timer.periodic(Duration(minutes: kAutoLockWalletMinutes!), (timer) {
      if (!sl<HtlcSwapsHandler>().hasActiveIncomingSwaps) {
        _lockBloc.addEvent(LockEvent.navigateToLock);
      }
    });
  }

  void _handleIncomingLinks() async {
    if (!kIsWeb && !Platform.isLinux) {
      _incomingLinkSubscription =
          _appLinks.allUriLinkStream.listen((Uri? uri) async {
        if (!await windowManager.isFocused() ||
            !await windowManager.isVisible()) {
          windowManager.show();
        }

        if (uri != null) {
          String uriRaw = uri.toString();

          Logger('MainAppContainer')
              .log(Level.INFO, '_handleIncomingLinks $uriRaw');

          if (context.mounted) {
            if (uriRaw.contains('wc')) {
              if (Platform.isWindows) {
                uriRaw = uriRaw.replaceAll('/?', '?');
              }
              String wcUri = Uri.decodeFull(uriRaw.split('wc?uri=').last);
              if (WalletConnectUri.tryParse(wcUri) != null) {
                _updateWalletConnectUri(wcUri);
              }
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
              uri.queryParametersAll.forEach((key, value) async {
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
                token = await zenon!.embedded.token
                    .getByZts(TokenStandard.parse(queryZTS));
              }
            }

            final sendPaymentBloc = SendPaymentBloc();
            final stakingOptionsBloc = StakingOptionsBloc();
            final delegateButtonBloc = DelegateButtonBloc();
            final plasmaOptionsBloc = PlasmaOptionsBloc();

            if (context.mounted) {
              switch (uri.host) {
                case 'transfer':
                  sl<NotificationsBloc>().addNotification(
                    WalletNotification(
                      title: 'Transfer action detected',
                      timestamp: DateTime.now().millisecondsSinceEpoch,
                      details: 'Deep link: $uriRaw',
                      type: NotificationType.paymentReceived,
                    ),
                  );

                  if (kCurrentPage != Tabs.lock) {
                    _navigateTo(Tabs.transfer);

                    if (token != null) {
                      showDialogWithNoAndYesOptions(
                        context: context,
                        title: 'Transfer action',
                        isBarrierDismissible: true,
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                                'Are you sure you want transfer $queryAmount ${token.symbol} from $kSelectedAddress to $queryAddress?'),
                          ],
                        ),
                        onYesButtonPressed: () {
                          sendPaymentBloc.sendTransfer(
                            fromAddress: kSelectedAddress,
                            toAddress: queryAddress,
                            amount:
                                queryAmount.extractDecimals(token!.decimals),
                            data: null,
                            token: token,
                          );
                        },
                        onNoButtonPressed: () {},
                      );
                    }
                  }
                  break;

                case 'stake':
                  sl<NotificationsBloc>().addNotification(
                    WalletNotification(
                      title: 'Stake action detected',
                      timestamp: DateTime.now().millisecondsSinceEpoch,
                      details: 'Deep link: $uriRaw',
                      type: NotificationType.paymentReceived,
                    ),
                  );

                  if (kCurrentPage != Tabs.lock) {
                    _navigateTo(Tabs.staking);

                    showDialogWithNoAndYesOptions(
                      context: context,
                      title: 'Stake ${kZnnCoin.symbol} action',
                      isBarrierDismissible: true,
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                              'Are you sure you want stake $queryAmount ${kZnnCoin.symbol} for $queryDuration month(s)?'),
                        ],
                      ),
                      onYesButtonPressed: () {
                        stakingOptionsBloc.stakeForQsr(
                            Duration(seconds: queryDuration * stakeTimeUnitSec),
                            queryAmount.extractDecimals(kZnnCoin.decimals));
                      },
                      onNoButtonPressed: () {},
                    );
                  }
                  break;

                case 'delegate':
                  sl<NotificationsBloc>().addNotification(
                    WalletNotification(
                      title: 'Delegate action detected',
                      timestamp: DateTime.now().millisecondsSinceEpoch,
                      details: 'Deep link: $uriRaw',
                      type: NotificationType.paymentReceived,
                    ),
                  );

                  if (kCurrentPage != Tabs.lock) {
                    _navigateTo(Tabs.pillars);

                    showDialogWithNoAndYesOptions(
                      context: context,
                      title: 'Delegate ${kZnnCoin.symbol} action',
                      isBarrierDismissible: true,
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                              'Are you sure you want delegate the ${kZnnCoin.symbol} from $kSelectedAddress to Pillar $queryPillarName?'),
                        ],
                      ),
                      onYesButtonPressed: () {
                        delegateButtonBloc.delegateToPillar(queryPillarName);
                      },
                      onNoButtonPressed: () {},
                    );
                  }
                  break;

                case 'fuse':
                  sl<NotificationsBloc>().addNotification(
                    WalletNotification(
                      title: 'Fuse ${kQsrCoin.symbol} action detected',
                      timestamp: DateTime.now().millisecondsSinceEpoch,
                      details: 'Deep link: $uriRaw',
                      type: NotificationType.paymentReceived,
                    ),
                  );

                  if (kCurrentPage != Tabs.lock) {
                    _navigateTo(Tabs.plasma);

                    showDialogWithNoAndYesOptions(
                      context: context,
                      title: 'Fuse ${kQsrCoin.symbol} action',
                      isBarrierDismissible: true,
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                              'Are you sure you want fuse $queryAmount ${kQsrCoin.symbol} for address $queryAddress?'),
                        ],
                      ),
                      onYesButtonPressed: () {
                        plasmaOptionsBloc.generatePlasma(queryAddress,
                            queryAmount.extractDecimals(kZnnCoin.decimals));
                      },
                      onNoButtonPressed: () {},
                    );
                  }
                  break;

                case 'sentinel':
                  sl<NotificationsBloc>().addNotification(
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
                  break;

                case 'pillar':
                  sl<NotificationsBloc>().addNotification(
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
                  break;

                default:
                  sl<NotificationsBloc>().addNotification(
                    WalletNotification(
                      title: 'Incoming link detected',
                      timestamp: DateTime.now().millisecondsSinceEpoch,
                      details: 'Deep link: $uriRaw',
                      type: NotificationType.paymentReceived,
                    ),
                  );
                  break;
              }
            }
            return;
          }
        }
      }, onDone: () {
        Logger('MainAppContainer')
            .log(Level.INFO, '_handleIncomingLinks', 'done');
      }, onError: (Object err) {
        NotificationUtils.sendNotificationError(
            err, 'Handle incoming link failed');
        Logger('MainAppContainer')
            .log(Level.WARNING, '_handleIncomingLinks', err);
        if (!mounted) return;
      });
    }
  }

  Future<void> _handleInitialUri() async {
    if (!_initialUriIsHandled) {
      _initialUriIsHandled = true;
      try {
        final uri = await _appLinks.getInitialAppLink();
        if (uri != null) {
          Logger('MainAppContainer').log(Level.INFO, '_handleInitialUri $uri');
        }
        if (!mounted) return;
      } on PlatformException catch (e, stackTrace) {
        Logger('MainAppContainer').log(Level.WARNING,
            '_handleInitialUri PlatformException', e, stackTrace);
      } on FormatException catch (e, stackTrace) {
        Logger('MainAppContainer').log(
            Level.WARNING, '_handleInitialUri FormatException', e, stackTrace);
        if (!mounted) return;
      }
    }
  }

  @override
  void onClipboardChanged() async {
    ClipboardData? newClipboardData =
        await Clipboard.getData(Clipboard.kTextPlain);
    final text = newClipboardData?.text ?? '';
    if (text.isNotEmpty && WalletConnectUri.tryParse(text) != null) {
      // This check is needed because onClipboardChanged is called twice sometimes
      if (kLastWalletConnectUriNotifier.value != text) {
        _updateWalletConnectUri(text);
      }
    }
  }

  void _updateWalletConnectUri(String text) {
    kLastWalletConnectUriNotifier.value = text;
    if (!_isWalletLocked()) {
      if (kCurrentPage != Tabs.walletConnect) {
        sl<NotificationsBloc>().addNotification(
          WalletNotification(
            title:
                'WalletConnect link detected. Go to WalletConnect tab to connect.',
            timestamp: DateTime.now().millisecondsSinceEpoch,
            details: 'A WalletConnect link has been copied to clipboard. '
                'Go to the WalletConnect tab to connect to the dApp through ${kLastWalletConnectUriNotifier.value}',
            type: NotificationType.copiedToClipboard,
          ),
        );
        _navigateTo(Tabs.walletConnect);
      }
    }
  }
}
