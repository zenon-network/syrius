import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:provider/provider.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/utils/extensions.dart';
import 'package:zenon_syrius_wallet_flutter/utils/format_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:zenon_syrius_wallet_flutter/utils/notification_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/notifiers/text_scaling_notifier.dart';
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
  bridge,
  accelerator,
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
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation _animation;

  final NodeSyncStatusBloc _netSyncStatusBloc = NodeSyncStatusBloc();

  late StreamSubscription _lockBlockStreamSubscription;

  Timer? _navigateToLockTimer;

  late LockBloc _lockBloc;

  TabController? _tabController;

  TransferTabChild? _transferTabChild;

  final FocusNode _focusNode = FocusNode(
    skipTraversal: true,
    canRequestFocus: false,
  );

  @override
  void initState() {
    _netSyncStatusBloc.getDataPeriodically();
    _transferTabChild = TransferTabChild(
      navigateToBridgeTab: () {
        _navigateTo(Tabs.bridge);
      },
    );
    _initTabController();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _animationController.repeat(reverse: true);
    _animation = Tween(begin: 1.0, end: 3.0).animate(_animationController);
    kCurrentPage = kWalletInitCompleted ? Tabs.dashboard : Tabs.lock;
    _initLockBlock();
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

  void _onNavigateToLock() {
    kKeyStore = null;
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
      Tab(
        child: Icon(
          MaterialCommunityIcons.bridge,
          size: 24.0,
          color: _isTabSelected(Tabs.bridge)
              ? AppColors.znnColor
              : Theme.of(context).iconTheme.color,
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
        const BridgeTabChild(),
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
    _navigateToLockTimer = Timer.periodic(
      Duration(minutes: kAutoLockWalletMinutes!),
      (timer) => _lockBloc.addEvent(LockEvent.navigateToLock),
    );
    _lockBloc.addEvent(LockEvent.navigateToPreviousTab);
  }

  @override
  void dispose() {
    _animationController.dispose();
    _netSyncStatusBloc.dispose();
    _navigateToLockTimer?.cancel();
    _lockBlockStreamSubscription.cancel();
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
    _navigateToLockTimer = Timer.periodic(
      Duration(
        minutes: kAutoLockWalletMinutes!,
      ),
      (timer) => _lockBloc.addEvent(LockEvent.navigateToLock),
    );
    _lockBloc.addEvent(LockEvent.navigateToDashboard);
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
    kCurrentPage = page;
    _tabController!.animateTo(kTabs.indexOf(page));
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
            _navigateToLockTimer = Timer.periodic(
              Duration(minutes: kAutoLockWalletMinutes!),
              (timer) => _lockBloc.addEvent(LockEvent.navigateToLock),
            );
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
            _navigateToLockTimer = Timer.periodic(
              Duration(minutes: kAutoLockWalletMinutes!),
              (timer) => _lockBloc.addEvent(LockEvent.navigateToLock),
            );
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
}
