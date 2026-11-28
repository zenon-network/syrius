import 'dart:async';
import 'dart:typed_data';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:zenon_syrius_wallet_flutter/l10n/app_localizations.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart' as app;
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/screens/screens.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_theme.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:zenon_syrius_wallet_flutter/utils/notifiers/app_ui_preferences_notifier.dart';
import 'package:zenon_syrius_wallet_flutter/utils/notifiers/default_address_notifier.dart';
import 'package:zenon_syrius_wallet_flutter/utils/pair.dart';
import 'package:zenon_syrius_wallet_flutter/utils/zts_utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

import '../helpers/hydrated_bloc.dart';

class _MockZenon extends Mock implements Zenon {}

class _MockWsClient extends Mock implements WsClient {}

class _MockLedgerApi extends Mock implements LedgerApi {}

class _MockEmbeddedApi extends Mock implements EmbeddedApi {}

class _MockPlasmaApi extends Mock implements PlasmaApi {}

class _MockPillarApi extends Mock implements PillarApi {}

class _MockSentinelApi extends Mock implements SentinelApi {}

class _MockTokenApi extends Mock implements TokenApi {}

class _MockStartP2pSwapBloc
    extends MockBloc<StartP2pSwapEvent, StartP2pSwapState>
    implements StartP2pSwapBloc {}

class _MockDeployPillarBloc
    extends MockBloc<DeployPillarEvent, DeployPillarState>
    implements DeployPillarBloc {}

class _MockIssueTokenBloc extends MockBloc<IssueTokenEvent, IssueTokenState>
    implements IssueTokenBloc {}

class _MockSendTransactionBloc
    extends MockBloc<SendTransactionEvent, SendTransactionState>
    implements SendTransactionBloc {}

class _MockPendingTransactionsBloc
    extends MockBloc<InfiniteListEvent, InfiniteListState<AccountBlock>>
    implements PendingTransactionsBloc {}

class _MockNodeSyncStatusCubit extends MockCubit<NodeSyncStatusState>
    implements NodeSyncStatusCubit {}

class _MockNotificationsBloc extends Mock implements NotificationsBloc {}

class _FakeAddress extends Fake implements Address {}

class _FakeAccountBlockTemplate extends Fake implements AccountBlockTemplate {}

class _DelayedFavoriteTokensRepository implements FavoriteTokensRepository {
  _DelayedFavoriteTokensRepository(this.addCompleter);

  final Completer<void> addCompleter;

  @override
  bool contains(TokenStandard tokenStandard) => false;

  @override
  Future<void> add(TokenStandard tokenStandard) => addCompleter.future;

  @override
  Future<void> remove(TokenStandard tokenStandard) async {}
}

Token _buildTestToken({
  required String name,
  required String symbol,
  required String owner,
  required int seedByte,
}) => Token(
  name,
  symbol,
  'zenon.network',
  BigInt.from(1000),
  0,
  Address.parse(owner),
  TokenStandard.fromBytes(List<int>.filled(TokenStandard.coreSize, seedByte)),
  BigInt.from(10000),
  true,
  true,
  true,
);

PillarInfo _buildTestPillar({
  required String name,
  required String owner,
  required String producer,
  int rank = 1,
}) => PillarInfo.fromJson(<String, dynamic>{
  'name': name,
  'rank': rank,
  'type': PillarInfo.regularPillarType,
  'ownerAddress': owner,
  'producerAddress': producer,
  'withdrawAddress': owner,
  'giveMomentumRewardPercentage': 0,
  'giveDelegateRewardPercentage': 50,
  'isRevocable': false,
  'revokeCooldown': 3600,
  'revokeTimestamp': 0,
  'currentStats': const <String, dynamic>{
    'producedMomentums': 10,
    'expectedMomentums': 10,
  },
  'weight': '1500000000000',
});

Widget _wrapThemed(Widget child, {ThemeData? theme}) {
  return MaterialApp(
    theme: theme ?? AppTheme.darkTheme,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: child),
  );
}

void main() {
  initHydratedStorage();

  group('AppUiPreferencesNotifier', () {
    test('exposes sensible defaults and notifies on updates', () {
      final AppUiPreferencesNotifier notifier = AppUiPreferencesNotifier();
      int notifications = 0;
      notifier.addListener(() => notifications += 1);

      expect(notifier.hideBalances, isFalse);
      expect(notifier.sidebarExpanded, isFalse);
      expect(notifier.showFiatValues, isFalse);
      expect(notifier.webAppsEnabled, isFalse);
      expect(notifier.pillarMode, FeatureDisplayMode.auto);
      expect(notifier.sentinelMode, FeatureDisplayMode.auto);
      expect(notifier.sporksMode, FeatureDisplayMode.off);
      expect(notifier.contacts, isEmpty);

      notifier.toggleHideBalances();
      expect(notifier.hideBalances, isTrue);
      notifier.toggleSidebarExpanded();
      expect(notifier.sidebarExpanded, isTrue);
      notifier.showFiatValues = true;
      expect(notifier.showFiatValues, isTrue);
      notifier.webAppsEnabled = true;
      expect(notifier.webAppsEnabled, isTrue);
      notifier.setSelectedExplorer('https://zenonhub.io/explorer/');
      expect(notifier.selectedExplorer, 'https://zenonhub.io/explorer/');
      notifier.setPillarMode(FeatureDisplayMode.on);
      expect(notifier.pillarMode, FeatureDisplayMode.on);
      notifier.setSentinelMode(FeatureDisplayMode.off);
      expect(notifier.sentinelMode, FeatureDisplayMode.off);
      notifier.setSporksMode(FeatureDisplayMode.auto);
      expect(notifier.sporksMode, FeatureDisplayMode.auto);

      notifier.saveContact('z1qr4pm3x9ue2a6kz0t2g8s3x5c7q1wl4r9d2a', 'Alice');
      expect(
        notifier.contactLabelFor('z1qr4pm3x9ue2a6kz0t2g8s3x5c7q1wl4r9d2a'),
        'Alice',
      );
      notifier.removeContact('z1qr4pm3x9ue2a6kz0t2g8s3x5c7q1wl4r9d2a');
      expect(notifier.contacts, isEmpty);
      expect(notifications, greaterThanOrEqualTo(10));
    });
  });

  group('ShellNavigationController', () {
    test('updates transfer requests with monotonic nonce and settings '
        'sections', () {
      final ShellNavigationController controller = ShellNavigationController();
      addTearDown(controller.dispose);

      controller.requestTransfer(
        mode: TransferMode.zap,
        recipientAddress: 'z1qr4pm3x9ue2a6kz0t2g8s3x5c7q1wl4r9d2a',
      );
      expect(controller.transferRequest.value.mode, TransferMode.zap);
      expect(
        controller.transferRequest.value.recipientAddress,
        'z1qr4pm3x9ue2a6kz0t2g8s3x5c7q1wl4r9d2a',
      );
      expect(controller.transferRequest.value.nonce, 1);

      controller.requestTransfer(mode: TransferMode.zap);
      expect(controller.transferRequest.value.nonce, 2);

      int sectionChanges = 0;
      controller.settingsSection.addListener(() => sectionChanges += 1);
      controller
        ..requestSettingsSection(SettingsSection.about)
        ..requestSettingsSection(SettingsSection.about);
      expect(controller.settingsSection.value, SettingsSection.about);
      expect(sectionChanges, 1);
    });
  });

  group('SyriusThemeTokens', () {
    test('provides dark and light extensions with copyWith and lerp', () {
      final SyriusThemeTokens? dark = AppTheme.darkTheme
          .extension<SyriusThemeTokens>();
      final SyriusThemeTokens? light = AppTheme.lightTheme
          .extension<SyriusThemeTokens>();
      expect(dark, isNotNull);
      expect(light, isNotNull);
      expect(dark!.shellBackground, isNot(light!.shellBackground));

      final SyriusThemeTokens overridden = dark.copyWith(znnGreen: Colors.teal);
      expect(overridden.znnGreen, Colors.teal);

      final SyriusThemeTokens mid = dark.lerp(light, 0.5);
      expect(mid.surface, isNot(dark.surface));
      expect(mid.surface, isNot(light.surface));
    });
  });

  group('Redesign UI kit widgets', () {
    testWidgets('SyriusNavigationRail toggles expansion and selects tabs', (
      WidgetTester tester,
    ) async {
      Tabs? selected;
      bool toggled = false;
      bool notificationsOpened = false;
      bool locked = false;

      await tester.pumpWidget(
        _wrapThemed(
          SizedBox(
            height: 760,
            child: SyriusNavigationRail(
              activeTab: Tabs.dashboard,
              isExpanded: true,
              hasUnreadNotifications: true,
              isNotificationsOpen: false,
              onToggleExpanded: () => toggled = true,
              onTabSelected: (Tabs tab) => selected = tab,
              onNotificationsPressed: () => notificationsOpened = true,
              onLockPressed: () => locked = true,
            ),
          ),
        ),
      );

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Transfer'), findsOneWidget);
      expect(find.text('Staking'), findsOneWidget);
      expect(find.text('Nodes'), findsOneWidget);
      expect(find.text('Plasma'), findsOneWidget);
      expect(find.text('Tokens'), findsOneWidget);

      await tester.tap(find.text('Transfer'));
      expect(selected, Tabs.transfer);

      await tester.tap(find.text('Notifications'));
      expect(notificationsOpened, isTrue);

      await tester.tap(find.text('Lock'));
      expect(locked, isTrue);

      await tester.tap(find.byIcon(Icons.chevron_left));
      expect(toggled, isTrue);
    });

    testWidgets('SyriusSegmentedControl and SyriusHorizontalStepper render '
        'in light and dark themes without overflow', (
      WidgetTester tester,
    ) async {
      String picked = 'a';
      await tester.pumpWidget(
        _wrapThemed(
          StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                children: <Widget>[
                  SyriusSegmentedControl<String>(
                    selected: picked,
                    onChanged: (String v) => setState(() => picked = v),
                    options: const <SyriusSegmentOption<String>>[
                      SyriusSegmentOption<String>(value: 'a', label: 'Alpha'),
                      SyriusSegmentOption<String>(value: 'b', label: 'Beta'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const SizedBox(
                    width: 420,
                    child: SyriusHorizontalStepper(
                      steps: <String>['Seed', 'Confirm', 'Password', 'Ready'],
                      currentStep: 2,
                    ),
                  ),
                ],
              );
            },
          ),
          theme: AppTheme.lightTheme,
        ),
      );

      await tester.tap(find.text('Beta'));
      await tester.pump();
      expect(picked, 'b');
    });

    testWidgets(
      'SyriusModalShell renders inside showCustomDialog (unbounded height) '
      'without layout assertions',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          _wrapThemed(
            Builder(
              builder: (BuildContext context) {
                return ElevatedButton(
                  onPressed: () {
                    unawaited(
                      showCustomDialog<void>(
                        context: context,
                        content: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 460),
                          child: const SyriusModalShell(
                            title: 'Start swap',
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                Text('Swap form body'),
                                SizedBox(height: 24),
                                Text('Footer content'),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  child: const Text('Open modal'),
                );
              },
            ),
          ),
        );

        await tester.tap(find.text('Open modal'));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Start swap'), findsOneWidget);
        expect(find.text('Swap form body'), findsOneWidget);
      },
    );

    testWidgets(
      'SyriusPaginatedListView auto-requests more when viewport is unfilled '
      'and deduplicates requests until itemCount updates',
      (WidgetTester tester) async {
        int loadMoreCalls = 0;

        await tester.pumpWidget(
          _wrapThemed(
            SizedBox(
              height: 400,
              child: SyriusPaginatedListView(
                itemCount: 2,
                hasReachedMax: false,
                onLoadMore: () => loadMoreCalls += 1,
                itemBuilder: (_, int i) =>
                    SizedBox(height: 40, child: Text('Row $i')),
              ),
            ),
          ),
        );
        await tester.pump();

        expect(loadMoreCalls, 1);
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        // Updating itemCount allows another fetch when still not max.
        await tester.pumpWidget(
          _wrapThemed(
            SizedBox(
              height: 400,
              child: SyriusPaginatedListView(
                itemCount: 4,
                hasReachedMax: true,
                onLoadMore: () => loadMoreCalls += 1,
                itemBuilder: (_, int i) =>
                    SizedBox(height: 40, child: Text('Row $i')),
              ),
            ),
          ),
        );
        await tester.pump();

        expect(loadMoreCalls, 1);
        expect(find.byType(CircularProgressIndicator), findsNothing);
      },
    );

    testWidgets(
      'SyriusPaginatedListView releases request guard after failed or '
      'filtered-empty load-more completions',
      (WidgetTester tester) async {
        final ValueNotifier<bool> isLoadingMore = ValueNotifier<bool>(false);
        addTearDown(isLoadingMore.dispose);
        int loadMoreCalls = 0;
        List<int> snapshot = <int>[0, 1, 2];

        Widget buildTree({required List<int> dataIdentity}) => _wrapThemed(
          SizedBox(
            height: 200,
            child: SyriusPaginatedListView(
              itemCount: 10,
              hasReachedMax: false,
              isLoadingMore: isLoadingMore,
              dataIdentity: dataIdentity,
              onLoadMore: () {
                loadMoreCalls += 1;
                isLoadingMore.value = true;
              },
              itemBuilder: (_, int i) =>
                  SizedBox(height: 40, child: Text('Row $i')),
            ),
          ),
        );

        await tester.pumpWidget(buildTree(dataIdentity: snapshot));
        await tester.pump();
        expect(loadMoreCalls, 0);

        // Scroll to bottom -> triggers load-more #1.
        await tester.drag(find.byType(ListView), const Offset(0, -500));
        await tester.pump();
        expect(loadMoreCalls, 1);

        // Simulate failure / discarded request: isLoadingMore returns false
        // without changing itemCount, hasReachedMax, or dataIdentity.
        isLoadingMore.value = false;
        await tester.pump();

        // Scrolling again must retry cleanly (flag was released).
        await tester.drag(find.byType(ListView), const Offset(0, 80));
        await tester.pump();
        await tester.drag(find.byType(ListView), const Offset(0, -120));
        await tester.pump();
        expect(loadMoreCalls, 2);

        // Simulate filtered-empty page: dataIdentity changes while itemCount
        // stays unchanged, then isLoadingMore settles.
        snapshot = <int>[0, 1, 2, 3, 4];
        await tester.pumpWidget(buildTree(dataIdentity: snapshot));
        isLoadingMore.value = false;
        await tester.pump();

        await tester.drag(find.byType(ListView), const Offset(0, 80));
        await tester.pump();
        await tester.drag(find.byType(ListView), const Offset(0, -120));
        await tester.pump();
        expect(loadMoreCalls, 3);
      },
    );
  });

  group('Redesigned BDD modals and steppers', () {
    const String selfAddress = 'z1qq6eg8n43g032hanpsfp02qcdmv7zfj3y2lt5d';
    const String counterpartyAddress =
        'z1qqjnwjjpnue8xmmpanz6csze6tcmtzzdtfsww7';
    const String producerAddress = 'z1qzal6c5s9rjnnxd2z7dvdhjxpmmj4fmw56a0m3';

    late _MockZenon mockZenon;
    late _MockWsClient mockWsClient;
    late _MockLedgerApi mockLedgerApi;
    late _MockEmbeddedApi mockEmbeddedApi;
    late _MockPlasmaApi mockPlasmaApi;
    late _MockPillarApi mockPillarApi;
    late _MockSentinelApi mockSentinelApi;
    late _MockTokenApi mockTokenApi;

    late Zenon? previousZenon;
    late String? previousSelectedAddress;
    late List<String?> previousAddressList;
    late Map<String, String> previousAddressLabels;
    late bool hadMultipleBalanceBloc;
    late MultipleBalanceBloc? previousMultipleBalanceBloc;

    Future<MultipleBalanceBloc> createTestBalanceBloc() async {
      if (app.sl.isRegistered<MultipleBalanceBloc>()) {
        await app.sl.unregister<MultipleBalanceBloc>();
      }
      final MultipleBalanceBloc bloc = MultipleBalanceBloc(zenon: mockZenon);
      app.sl.registerSingleton<MultipleBalanceBloc>(bloc);
      addTearDown(() async {
        await bloc.close();
        if (app.sl.isRegistered<MultipleBalanceBloc>()) {
          await app.sl.unregister<MultipleBalanceBloc>();
        }
      });
      return bloc;
    }

    setUpAll(() {
      registerFallbackValue(_FakeAddress());
      registerFallbackValue(
        SendTransactionInitiate(
          fromAddress: selfAddress,
          toAddress: counterpartyAddress,
          amount: BigInt.one,
          token: kZnnCoin,
        ),
      );
      registerFallbackValue(
        DeployPillarRequested(
          pillarName: 'PillarA',
          rewardAddress: emptyAddress,
          blockProducingAddress: emptyAddress,
          giveBlockRewardPercentage: 0,
          giveDelegateRewardPercentage: 0,
        ),
      );
      registerFallbackValue(
        StartP2pSwapRequested(
          selfAddress: emptyAddress,
          counterpartyAddress: emptyAddress,
          fromToken: kZnnCoin,
          fromAmount: BigInt.one,
        ),
      );
    });

    setUp(() async {
      mockZenon = _MockZenon();
      mockWsClient = _MockWsClient();
      mockLedgerApi = _MockLedgerApi();
      mockEmbeddedApi = _MockEmbeddedApi();
      mockPlasmaApi = _MockPlasmaApi();
      mockPillarApi = _MockPillarApi();
      mockSentinelApi = _MockSentinelApi();
      mockTokenApi = _MockTokenApi();

      when(() => mockZenon.wsClient).thenReturn(mockWsClient);
      when(() => mockZenon.ledger).thenReturn(mockLedgerApi);
      when(() => mockZenon.embedded).thenReturn(mockEmbeddedApi);
      when(() => mockEmbeddedApi.plasma).thenReturn(mockPlasmaApi);
      when(() => mockEmbeddedApi.pillar).thenReturn(mockPillarApi);
      when(() => mockEmbeddedApi.sentinel).thenReturn(mockSentinelApi);
      when(() => mockEmbeddedApi.token).thenReturn(mockTokenApi);
      when(
        () => mockWsClient.restartedStream,
      ).thenAnswer((_) => const Stream<bool>.empty());

      final AccountInfo fundedAccount = AccountInfo(
        address: selfAddress,
        blockCount: 5,
        balanceInfoList: <BalanceInfoListItem>[
          BalanceInfoListItem(
            token: kZnnCoin,
            balance: BigInt.from(20000) * BigInt.from(10).pow(coinDecimals),
          ),
          BalanceInfoListItem(
            token: kQsrCoin,
            balance: BigInt.from(200000) * BigInt.from(10).pow(coinDecimals),
          ),
        ],
      );
      when(
        () => mockLedgerApi.getAccountInfoByAddress(any()),
      ).thenAnswer((_) async => fundedAccount);
      when(() => mockPlasmaApi.get(any())).thenAnswer(
        (_) async => PlasmaInfo(
          currentPlasma: 1000000,
          maxPlasma: 1000000,
          qsrAmount: BigInt.from(500) * BigInt.from(10).pow(coinDecimals),
        ),
      );
      when(() => mockPillarApi.getQsrRegistrationCost()).thenAnswer(
        (_) async => BigInt.from(150000) * BigInt.from(10).pow(coinDecimals),
      );
      when(() => mockPillarApi.getDepositedQsr(any())).thenAnswer(
        (_) async => BigInt.from(50000) * BigInt.from(10).pow(coinDecimals),
      );

      previousZenon = app.zenon;
      previousSelectedAddress = kSelectedAddress;
      previousAddressList = List<String?>.from(kDefaultAddressList);
      previousAddressLabels = Map<String, String>.from(kAddressLabelMap);

      app.zenon = mockZenon;
      kSelectedAddress = selfAddress;
      kDefaultAddressList = <String?>[selfAddress];
      kAddressLabelMap = <String, String>{selfAddress: 'Primary Devnet Wallet'};

      hadMultipleBalanceBloc = app.sl.isRegistered<MultipleBalanceBloc>();
      previousMultipleBalanceBloc = hadMultipleBalanceBloc
          ? app.sl<MultipleBalanceBloc>()
          : null;
      if (hadMultipleBalanceBloc) {
        await app.sl.unregister<MultipleBalanceBloc>();
      }
    });

    tearDown(() async {
      if (app.sl.isRegistered<MultipleBalanceBloc>()) {
        await app.sl.unregister<MultipleBalanceBloc>();
      }
      if (hadMultipleBalanceBloc && previousMultipleBalanceBloc != null) {
        app.sl.registerSingleton<MultipleBalanceBloc>(
          previousMultipleBalanceBloc!,
        );
      }
      app.zenon = previousZenon;
      kSelectedAddress = previousSelectedAddress;
      kDefaultAddressList = previousAddressList;
      kAddressLabelMap = previousAddressLabels;
    });

    testWidgets(
      'StartP2pSwapModal renders inside showCustomDialog without overflow and '
      'submits a valid swap request',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1400, 1000);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final MultipleBalanceBloc multipleBalanceBloc =
            await createTestBalanceBloc();
        final _MockStartP2pSwapBloc startSwapBloc = _MockStartP2pSwapBloc();
        when(() => startSwapBloc.state).thenReturn(const StartP2pSwapInitial());
        whenListen<StartP2pSwapState>(
          startSwapBloc,
          const Stream<StartP2pSwapState>.empty(),
          initialState: const StartP2pSwapInitial(),
        );

        await tester.pumpWidget(
          MultiBlocProvider(
            providers: <SingleChildWidget>[
              BlocProvider<MultipleBalanceBloc>.value(
                value: multipleBalanceBloc,
              ),
              BlocProvider<StartP2pSwapBloc>.value(value: startSwapBloc),
            ],
            child: MaterialApp(
              theme: AppTheme.darkTheme,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: Builder(
                  builder: (BuildContext context) {
                    return ElevatedButton(
                      onPressed: () {
                        unawaited(
                          showCustomDialog<void>(
                            context: context,
                            content: const StartP2pSwapModal(),
                          ),
                        );
                      },
                      child: const Text('Open Start Swap'),
                    );
                  },
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open Start Swap'));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.textContaining('<highlight>'), findsNothing);

        await tester.enterText(
          find.byKey(const Key('start_p2p_swap_counterparty_address_field')),
          counterpartyAddress,
        );
        await tester.enterText(
          find.byKey(const Key('start_p2p_swap_amount_field')),
          '5',
        );
        await tester.pumpAndSettle();

        final Finder submitButton = find.byKey(
          const Key('start_p2p_swap_submit_button'),
        );
        await tester.ensureVisible(submitButton);
        await tester.tap(submitButton);
        await tester.pump();

        expect(tester.takeException(), isNull);
        verify(
          () => startSwapBloc.add(any(that: isA<StartP2pSwapRequested>())),
        ).called(1);
      },
    );

    testWidgets(
      'CreateTokenStepperPage steps through all forms and reactive checkboxes '
      'at 800x600 without overflow',
      (WidgetTester tester) async {
        final MultipleBalanceBloc multipleBalanceBloc =
            await createTestBalanceBloc();
        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: BlocProvider<MultipleBalanceBloc>.value(
                value: multipleBalanceBloc,
                child: BlocProvider<AllTokensBloc>(
                  create: (_) => AllTokensBloc(zenon: mockZenon),
                  child: const CreateTokenStepperPage(),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        await tester.tap(find.byKey(const Key('token_plasma_next_button')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        await tester.tap(find.byKey(const Key('token_znn_next_button')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        await tester.enterText(
          find.byKey(const Key('token_name_field')),
          'DevnetToken',
        );
        await tester.enterText(
          find.byKey(const Key('token_symbol_field')),
          'DEVT',
        );
        await tester.enterText(
          find.byKey(const Key('token_domain_field')),
          'zenon.network',
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('token_details_next_button')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        // Verify reactive checkboxes rebuild via ValueListenableBuilder.
        final Finder mintableCheckbox = find.byKey(
          const Key('token_mintable_checkbox'),
        );
        final Finder burnableCheckbox = find.byKey(
          const Key('token_burnable_checkbox'),
        );
        final bool initialMintable = tester
            .widget<Checkbox>(mintableCheckbox)
            .value!;
        await tester.tap(mintableCheckbox);
        await tester.pumpAndSettle();
        expect(
          tester.widget<Checkbox>(mintableCheckbox).value,
          !initialMintable,
        );
        // Ensure mintable is true so max supply field is shown next.
        if (!tester.widget<Checkbox>(mintableCheckbox).value!) {
          await tester.tap(mintableCheckbox);
          await tester.pumpAndSettle();
        }
        final bool initialBurnable = tester
            .widget<Checkbox>(burnableCheckbox)
            .value!;
        await tester.tap(burnableCheckbox);
        await tester.pumpAndSettle();
        expect(
          tester.widget<Checkbox>(burnableCheckbox).value,
          !initialBurnable,
        );

        await tester.tap(find.byKey(const Key('token_options_next_button')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        final Slider decimalsSlider = tester.widget<Slider>(
          find.byKey(const Key('token_decimals_slider')),
        );
        decimalsSlider.onChanged!(8);
        await tester.pumpAndSettle();
        expect(find.textContaining('8'), findsWidgets);

        await tester.enterText(
          find.byKey(const Key('token_max_supply_field')),
          '1000',
        );
        await tester.enterText(
          find.byKey(const Key('token_total_supply_field')),
          '500',
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('token_metrics_next_button')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        // Go back from Issue -> decimals slider must preserve draft value (8).
        await tester.tap(find.text('Go back'));
        await tester.pumpAndSettle();
        final Slider restoredSlider = tester.widget<Slider>(
          find.byKey(const Key('token_decimals_slider')),
        );
        expect(restoredSlider.value, 8.0);
        await tester.tap(find.byKey(const Key('token_metrics_next_button')));
        await tester.pumpAndSettle();

        final Finder utilityCheckbox = find.byKey(
          const Key('token_utility_checkbox'),
        );
        final bool initialUtility = tester
            .widget<Checkbox>(utilityCheckbox)
            .value!;
        await tester.tap(utilityCheckbox);
        await tester.pumpAndSettle();
        expect(tester.widget<Checkbox>(utilityCheckbox).value, !initialUtility);

        final Finder createButtonContainer = find.byKey(
          const Key('token_create_button'),
        );
        expect(
          find.descendant(
            of: createButtonContainer,
            matching: find.byType(LoadingButton),
          ),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'CreatePillarStepperPage steps through plasma, partial & full QSR '
      'deposit, ZNN, and deploy at 800x600 without overflow',
      (WidgetTester tester) async {
        final MultipleBalanceBloc multipleBalanceBloc =
            await createTestBalanceBloc();
        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: BlocProvider<MultipleBalanceBloc>.value(
                value: multipleBalanceBloc,
                child: const CreatePillarStepperPage(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        // Step 1 -> Step 2 (partial QSR deposit shows both form and pie card).
        await tester.tap(find.byKey(const Key('pillar_plasma_next_button')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(
          find.byKey(const Key('pillar_qsr_amount_field')),
          findsOneWidget,
        );
        expect(
          find.byKey(const Key('pillar_qsr_deposit_button')),
          findsOneWidget,
        );

        // Simulate full QSR deposit covered and refresh QSR info bloc.
        when(() => mockPillarApi.getDepositedQsr(any())).thenAnswer(
          (_) async => BigInt.from(150000) * BigInt.from(10).pow(coinDecimals),
        );
        tester
            .element(find.byKey(const Key('pillar_qsr_deposit_button')))
            .read<CreatePillarQsrInfoBloc>()
            .add(FetchRequestData(address: Address.parse(selfAddress)));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        // Step 2 -> Step 3 -> Step 4.
        await tester.tap(find.byKey(const Key('pillar_qsr_next_button')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        await tester.tap(find.byKey(const Key('pillar_znn_next_button')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        await tester.enterText(
          find.byKey(const Key('pillar_name_field')),
          'testPillar',
        );
        await tester.enterText(
          find.byKey(const Key('pillar_reward_address_field')),
          selfAddress,
        );
        await tester.enterText(
          find.byKey(const Key('pillar_producer_address_field')),
          producerAddress,
        );
        await tester.pumpAndSettle();

        final Finder registerButton = find.byKey(
          const Key('pillar_register_button'),
        );
        await tester.ensureVisible(registerButton);
        await tester.pumpAndSettle();
        expect(registerButton, findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'CreatePillarStepperPage renders desktop split-pane rail at 1280x900 '
      'without overflow',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1280, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final MultipleBalanceBloc multipleBalanceBloc =
            await createTestBalanceBloc();
        final AppUiPreferencesNotifier uiPrefs = AppUiPreferencesNotifier()
          ..toggleHideBalances();
        addTearDown(uiPrefs.dispose);

        await tester.pumpWidget(
          ChangeNotifierProvider<AppUiPreferencesNotifier>.value(
            value: uiPrefs,
            child: MaterialApp(
              theme: AppTheme.darkTheme,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: BlocProvider<MultipleBalanceBloc>.value(
                  value: multipleBalanceBloc,
                  child: const CreatePillarStepperPage(),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(SyriusVerticalStepRail), findsOneWidget);
        expect(find.text('•••••• ZNN'), findsOneWidget);

        await tester.tap(find.byKey(const Key('pillar_plasma_next_button')));
        await tester.pumpAndSettle();
        expect(find.textContaining('150000 QSR'), findsWidgets);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'CreateTokenStepperPage renders desktop split-pane rail at 1280x900 '
      'and masks ZNN balance when Hide Balances is enabled',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1280, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final MultipleBalanceBloc multipleBalanceBloc =
            await createTestBalanceBloc();
        final AppUiPreferencesNotifier uiPrefs = AppUiPreferencesNotifier()
          ..toggleHideBalances();
        addTearDown(uiPrefs.dispose);

        await tester.pumpWidget(
          ChangeNotifierProvider<AppUiPreferencesNotifier>.value(
            value: uiPrefs,
            child: MaterialApp(
              theme: AppTheme.darkTheme,
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: BlocProvider<MultipleBalanceBloc>.value(
                  value: multipleBalanceBloc,
                  child: BlocProvider<AllTokensBloc>(
                    create: (_) => AllTokensBloc(zenon: mockZenon),
                    child: const CreateTokenStepperPage(),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(SyriusVerticalStepRail), findsOneWidget);
        expect(find.text('•••••• ZNN'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'CreateTokenStepperPage steps through all 6 forms at 1280x720 desktop '
      'viewport without overflow or exception',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1280, 720);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final MultipleBalanceBloc multipleBalanceBloc =
            await createTestBalanceBloc();
        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: BlocProvider<MultipleBalanceBloc>.value(
                value: multipleBalanceBloc,
                child: BlocProvider<AllTokensBloc>(
                  create: (_) => AllTokensBloc(zenon: mockZenon),
                  child: const CreateTokenStepperPage(),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.byType(SyriusVerticalStepRail), findsOneWidget);

        await tester.tap(find.byKey(const Key('token_plasma_next_button')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        await tester.tap(find.byKey(const Key('token_znn_next_button')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        await tester.enterText(
          find.byKey(const Key('token_name_field')),
          'newToken',
        );
        await tester.enterText(
          find.byKey(const Key('token_symbol_field')),
          'TKK',
        );
        await tester.enterText(
          find.byKey(const Key('token_domain_field')),
          'testing.com',
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('token_details_next_button')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        for (final Key key in const <Key>[
          Key('token_mintable_checkbox'),
          Key('token_burnable_checkbox'),
        ]) {
          final Finder finder = find.byKey(key);
          if (tester.widget<Checkbox>(finder).value != true) {
            await tester.tap(finder);
            await tester.pumpAndSettle();
          }
          expect(tester.widget<Checkbox>(finder).value, isTrue);
        }
        await tester.tap(find.byKey(const Key('token_options_next_button')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        final Slider decimalsSlider = tester.widget<Slider>(
          find.byKey(const Key('token_decimals_slider')),
        );
        decimalsSlider.onChanged!(3);
        await tester.pumpAndSettle();
        await tester.enterText(
          find.byKey(const Key('token_max_supply_field')),
          '100',
        );
        await tester.enterText(
          find.byKey(const Key('token_total_supply_field')),
          '90',
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const Key('token_metrics_next_button')));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);

        final Finder utilityFinder = find.byKey(
          const Key('token_utility_checkbox'),
        );
        if (tester.widget<Checkbox>(utilityFinder).value != false) {
          await tester.tap(utilityFinder);
          await tester.pumpAndSettle();
        }
        expect(tester.widget<Checkbox>(utilityFinder).value, isFalse);

        final Finder createButtonContainer = find.byKey(
          const Key('token_create_button'),
        );
        await tester.ensureVisible(createButtonContainer);
        await tester.pumpAndSettle();
        final Finder createButton = find.descendant(
          of: createButtonContainer,
          matching: find.byType(LoadingButton),
        );
        expect(createButton, findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'DeployPillarStep passes the submitted Pillar name on completion even '
      'if the text field is edited while deployment is in flight',
      (WidgetTester tester) async {
        final _MockDeployPillarBloc deployBloc = _MockDeployPillarBloc();
        final StreamController<DeployPillarState> stateController =
            StreamController<DeployPillarState>.broadcast();
        addTearDown(stateController.close);

        when(() => deployBloc.state).thenReturn(const DeployPillarInitial());
        whenListen<DeployPillarState>(
          deployBloc,
          stateController.stream,
          initialState: const DeployPillarInitial(),
        );

        String? completedName;
        bool deployDoneCalled = false;

        await tester.pumpWidget(
          _wrapThemed(
            SingleChildScrollView(
              child: BlocProvider<DeployPillarBloc>.value(
                value: deployBloc,
                child: DeployPillarStep(
                  onDeployDone: () => deployDoneCalled = true,
                  onDeployDoneWithName: (String name) => completedName = name,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('pillar_name_field')),
          'PillarA',
        );
        await tester.enterText(
          find.byKey(const Key('pillar_reward_address_field')),
          selfAddress,
        );
        await tester.enterText(
          find.byKey(const Key('pillar_producer_address_field')),
          counterpartyAddress,
        );
        await tester.pumpAndSettle();

        final Finder registerButton = find.byKey(
          const Key('pillar_register_button'),
        );
        await tester.ensureVisible(registerButton);
        await tester.pumpAndSettle();
        await tester.tap(registerButton);
        await tester.pump();
        verify(
          () => deployBloc.add(
            any(
              that: isA<DeployPillarRequested>().having(
                (DeployPillarRequested e) => e.pillarName,
                'pillarName',
                'PillarA',
              ),
            ),
          ),
        ).called(1);
        stateController.add(const DeployPillarLoading());
        await tester.pump();

        // User edits the name field while deployment is still in flight.
        await tester.enterText(
          find.byKey(const Key('pillar_name_field')),
          'PillarB',
        );
        await tester.pump();

        stateController.add(
          DeployPillarDone(accountBlock: _FakeAccountBlockTemplate()),
        );
        await tester.pumpAndSettle();

        expect(deployDoneCalled, isTrue);
        expect(completedName, 'PillarA');
      },
    );

    testWidgets(
      'IssueTokenStep keeps Go Back, Create, and utility checkbox disabled '
      'while favorites persistence is still pending after IssueTokenDone',
      (WidgetTester tester) async {
        final _MockIssueTokenBloc issueBloc = _MockIssueTokenBloc();
        final StreamController<IssueTokenState> stateController =
            StreamController<IssueTokenState>.broadcast();
        addTearDown(stateController.close);

        when(() => issueBloc.state).thenReturn(const IssueTokenInitial());
        whenListen<IssueTokenState>(
          issueBloc,
          stateController.stream,
          initialState: const IssueTokenInitial(),
        );

        final Completer<void> addCompleter = Completer<void>();
        final _DelayedFavoriteTokensRepository favoritesRepo =
            _DelayedFavoriteTokensRepository(addCompleter);
        final ValueNotifier<NewTokenData> tokenData =
            ValueNotifier<NewTokenData>(
              NewTokenData.initial(
                address: selfAddress,
              ).copyWith(tokenName: 'DevToken', tokenSymbol: 'DEV'),
            );
        addTearDown(tokenData.dispose);

        bool backPressed = false;
        bool issuePressed = false;
        bool issueDone = false;

        await tester.pumpWidget(
          _wrapThemed(
            RepositoryProvider<FavoriteTokensRepository>.value(
              value: favoritesRepo,
              child: BlocProvider<IssueTokenBloc>.value(
                value: issueBloc,
                child: IssueTokenStep(
                  onBackPressed: () => backPressed = true,
                  onIssueDone: () => issueDone = true,
                  onIssuePressed: () => issuePressed = true,
                  tokenData: tokenData,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final Finder utilityCheckbox = find.byKey(
          const Key('token_utility_checkbox'),
        );
        final Finder createButton = find.descendant(
          of: find.byKey(const Key('token_create_button')),
          matching: find.byType(LoadingButton),
        );

        expect(find.text('Go back'), findsOneWidget);
        expect(tester.widget<Checkbox>(utilityCheckbox).onChanged, isNotNull);
        expect(tester.widget<LoadingButton>(createButton).onPressed, isNotNull);

        stateController.add(const IssueTokenLoading());
        await tester.pump();
        await tester.pump();
        expect(find.text('Go back'), findsNothing);
        expect(tester.widget<Checkbox>(utilityCheckbox).onChanged, isNull);
        expect(tester.widget<LoadingButton>(createButton).onPressed, isNull);

        stateController.add(
          IssueTokenDone(
            accountBlock: _FakeAccountBlockTemplate(),
            newTokenStandard: kZnnCoin.tokenStandard,
          ),
        );
        await tester.pump();
        await tester.pump();

        // Favorites write is still pending: controls must remain locked.
        expect(find.text('Go back'), findsNothing);
        expect(tester.widget<Checkbox>(utilityCheckbox).onChanged, isNull);
        expect(tester.widget<LoadingButton>(createButton).onPressed, isNull);
        expect(issueDone, isFalse);
        expect(backPressed, isFalse);
        expect(issuePressed, isFalse);

        addCompleter.complete();
        await tester.pumpAndSettle();

        expect(issueDone, isTrue);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'TokensTabChild keeps loaded rows visible after a load-more failure and '
      'loads the next page when inline Retry is tapped',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1280, 620);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await Hive.openBox<dynamic>(kFavoriteTokensBox, bytes: Uint8List(0));
        addTearDown(() async {
          if (Hive.isBoxOpen(kFavoriteTokensBox)) {
            await Hive.box<dynamic>(kFavoriteTokensBox).close();
          }
        });

        final List<Token> page0Tokens = List<Token>.generate(
          kPageSize,
          (int index) => _buildTestToken(
            name: 'Token$index',
            symbol: 'TK$index',
            owner: counterpartyAddress,
            seedByte: index + 1,
          ),
        );
        final List<Token> page1Tokens = <Token>[
          _buildTestToken(
            name: 'Token10',
            symbol: 'TK10',
            owner: counterpartyAddress,
            seedByte: 11,
          ),
          _buildTestToken(
            name: 'Token11',
            symbol: 'TK11',
            owner: counterpartyAddress,
            seedByte: 12,
          ),
        ];

        int page1Calls = 0;
        when(
          () => mockTokenApi.getAll(
            pageIndex: any(named: 'pageIndex'),
            pageSize: any(named: 'pageSize'),
          ),
        ).thenAnswer((Invocation invocation) async {
          final int pageIndex = invocation.namedArguments[#pageIndex]! as int;
          if (pageIndex == 0) {
            return TokenList(count: 12, list: page0Tokens);
          }
          page1Calls += 1;
          if (page1Calls == 1) {
            throw Exception('transient page 1 failure');
          }
          return TokenList(count: 12, list: page1Tokens);
        });

        final MultipleBalanceBloc multipleBalanceBloc =
            await createTestBalanceBloc();
        final AppUiPreferencesNotifier uiPrefs = AppUiPreferencesNotifier();
        final SelectedAddressNotifier addressNotifier =
            SelectedAddressNotifier();
        addTearDown(uiPrefs.dispose);
        addTearDown(addressNotifier.dispose);

        await tester.pumpWidget(
          MultiProvider(
            providers: <SingleChildWidget>[
              ChangeNotifierProvider<AppUiPreferencesNotifier>.value(
                value: uiPrefs,
              ),
              ChangeNotifierProvider<SelectedAddressNotifier>.value(
                value: addressNotifier,
              ),
              BlocProvider<MultipleBalanceBloc>.value(
                value: multipleBalanceBloc,
              ),
            ],
            child: _wrapThemed(
              TokensTabChild(onStepperNotificationSeeMorePressed: () {}),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Switch from Held to All so the 10 page-0 network tokens are listed.
        await tester.tap(find.text('All'));
        await tester.pumpAndSettle();

        expect(find.text('Token0'), findsOneWidget);
        expect(find.byType(SyriusErrorWidget), findsNothing);

        // Scroll to the bottom to trigger page 1 (which fails once).
        await tester.drag(find.byType(ListView), const Offset(0, -1200));
        await tester.pumpAndSettle();

        expect(page1Calls, 1);
        expect(find.byType(SyriusErrorWidget), findsNothing);
        expect(find.text('Token9'), findsOneWidget);
        expect(find.text('Retry'), findsOneWidget);

        // Tapping inline Retry fetches page 1 and appends the new rows.
        await tester.tap(find.text('Retry'));
        await tester.pumpAndSettle();

        expect(page1Calls, 2);
        await tester.drag(find.byType(ListView), const Offset(0, -400));
        await tester.pumpAndSettle();
        expect(find.text('Token10'), findsOneWidget);
        expect(find.text('Token11'), findsOneWidget);
        expect(find.text('Retry'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'NodesWorkspaceView shows a waiting/retry panel when a newly registered '
      'Pillar is not yet returned by PillarsByOwnerBloc, then opens it on '
      'retry',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1280, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final String validProducerAddress = Address.fromPublicKey(
          List<int>.filled(32, 3),
        ).toString();
        final PillarInfo existingPillar = _buildTestPillar(
          name: 'ExistingPillar',
          owner: selfAddress,
          producer: validProducerAddress,
        );
        final PillarInfo newPillar = _buildTestPillar(
          name: 'NewPillar',
          owner: selfAddress,
          producer: counterpartyAddress,
          rank: 2,
        );

        List<PillarInfo> ownedPillars = <PillarInfo>[existingPillar];
        List<PillarInfo> allPillars = <PillarInfo>[existingPillar];

        when(() => mockPillarApi.getByOwner(any())).thenAnswer(
          (_) async => List<PillarInfo>.from(ownedPillars),
        );
        when(
          () => mockPillarApi.getAll(
            pageIndex: any(named: 'pageIndex'),
            pageSize: any(named: 'pageSize'),
          ),
        ).thenAnswer(
          (_) async => PillarInfoList.fromJson(<String, dynamic>{
            'count': allPillars.length,
            'list': allPillars.map((PillarInfo p) => p.toJson()).toList(),
          }),
        );
        when(() => mockPillarApi.getDelegatedPillar(any())).thenAnswer(
          (_) async => null,
        );
        when(() => mockPillarApi.getUncollectedReward(any())).thenAnswer(
          (_) async => UncollectedReward.fromJson(const <String, dynamic>{
            'address': selfAddress,
            'znnAmount': '0',
            'qsrAmount': '0',
          }),
        );
        when(
          () => mockSentinelApi.getAllActive(
            pageIndex: any(named: 'pageIndex'),
            pageSize: any(named: 'pageSize'),
          ),
        ).thenAnswer(
          (_) async => SentinelInfoList(
            count: 0,
            list: const <SentinelInfo>[],
          ),
        );
        when(() => mockSentinelApi.getByOwner(any())).thenAnswer(
          (_) async => null,
        );
        when(() => mockSentinelApi.getUncollectedReward(any())).thenAnswer(
          (_) async => UncollectedReward.fromJson(const <String, dynamic>{
            'address': selfAddress,
            'znnAmount': '0',
            'qsrAmount': '0',
          }),
        );

        final MultipleBalanceBloc multipleBalanceBloc =
            await createTestBalanceBloc();
        final PillarsByOwnerBloc pillarsByOwnerBloc = PillarsByOwnerBloc(
          zenon: mockZenon,
        )..add(FetchRequestData(address: Address.parse(selfAddress)));
        final DelegationStatsBloc delegationStatsBloc = DelegationStatsBloc(
          zenon: mockZenon,
        )..add(FetchRequestData(address: Address.parse(selfAddress)));
        final AppUiPreferencesNotifier uiPrefs = AppUiPreferencesNotifier();
        addTearDown(pillarsByOwnerBloc.close);
        addTearDown(delegationStatsBloc.close);
        addTearDown(uiPrefs.dispose);

        await tester.pumpWidget(
          MultiProvider(
            providers: <SingleChildWidget>[
              ChangeNotifierProvider<AppUiPreferencesNotifier>.value(
                value: uiPrefs,
              ),
              BlocProvider<MultipleBalanceBloc>.value(
                value: multipleBalanceBloc,
              ),
              BlocProvider<PillarsByOwnerBloc>.value(value: pillarsByOwnerBloc),
              BlocProvider<DelegationStatsBloc>.value(
                value: delegationStatsBloc,
              ),
            ],
            child: _wrapThemed(
              NodesWorkspaceView(
                initialTab: NodesSubTab.pillars,
                onStepperNotificationSeeMorePressed: () {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Launch Spawn Pillar stepper and simulate returning via View Pillar.
        await tester.tap(find.byIcon(Icons.more_horiz));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Spawn a pillar'));
        await tester.pumpAndSettle();

        expect(find.byType(StepperScreen), findsOneWidget);
        Navigator.of(
          tester.element(find.byType(StepperScreen)),
        ).pop('NewPillar');
        await tester.pumpAndSettle();

        // While PillarsByOwnerBloc only has ExistingPillar, the panel must
        // show the waiting/retry state for NewPillar instead of falling back.
        expect(find.text('NewPillar'), findsOneWidget);
        expect(find.text('Waiting'), findsOneWidget);
        expect(find.text('Producing'), findsNothing);
        expect(find.text('Retry'), findsOneWidget);

        // Once the RPC returns NewPillar, tapping Retry populates its panel.
        ownedPillars = <PillarInfo>[existingPillar, newPillar];
        allPillars = <PillarInfo>[existingPillar, newPillar];

        await tester.tap(find.text('Retry'));
        await tester.pumpAndSettle();

        expect(find.text('Waiting'), findsNothing);
        expect(find.text('Producing'), findsOneWidget);
        expect(find.text('NewPillar'), findsWidgets);
        expect(find.text('15,000 ZNN'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'TransferTabChild blocks sending without throwing when the node falls '
      'behind while the Send confirmation dialog is open',
      (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1280, 900);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final bool hadNotificationsBloc = app.sl.isRegistered<
          NotificationsBloc
        >();
        final NotificationsBloc? previousNotificationsBloc =
            hadNotificationsBloc ? app.sl<NotificationsBloc>() : null;
        if (hadNotificationsBloc) {
          await app.sl.unregister<NotificationsBloc>();
        }
        final _MockNotificationsBloc mockNotificationsBloc =
            _MockNotificationsBloc();
        when(
          () => mockNotificationsBloc.addErrorNotification(any(), any()),
        ).thenAnswer((_) async {});
        app.sl.registerSingleton<NotificationsBloc>(mockNotificationsBloc);
        addTearDown(() async {
          if (app.sl.isRegistered<NotificationsBloc>()) {
            await app.sl.unregister<NotificationsBloc>();
          }
          if (hadNotificationsBloc && previousNotificationsBloc != null) {
            app.sl.registerSingleton<NotificationsBloc>(
              previousNotificationsBloc,
            );
          }
        });

        final MultipleBalanceBloc multipleBalanceBloc =
            await createTestBalanceBloc();
        multipleBalanceBloc.add(
          const MultipleBalanceFetch(addresses: <String>[selfAddress]),
        );

        final _MockSendTransactionBloc sendBloc = _MockSendTransactionBloc();
        when(() => sendBloc.state).thenReturn(const SendTransactionState());
        whenListen<SendTransactionState>(
          sendBloc,
          const Stream<SendTransactionState>.empty(),
          initialState: const SendTransactionState(),
        );

        final _MockPendingTransactionsBloc pendingBloc =
            _MockPendingTransactionsBloc();
        const InfiniteListState<AccountBlock> emptyPendingState =
            InfiniteListState<AccountBlock>(
              status: InfiniteListStatus.success,
              data: <AccountBlock>[],
              hasReachedMax: true,
            );
        when(() => pendingBloc.state).thenReturn(emptyPendingState);
        whenListen<InfiniteListState<AccountBlock>>(
          pendingBloc,
          const Stream<InfiniteListState<AccountBlock>>.empty(),
          initialState: emptyPendingState,
        );

        final NodeSyncStatusState syncedState = NodeSyncStatusState(
          status: TimerStatus.success,
          data: Pair<SyncState, SyncInfo>(
            SyncState.syncDone,
            SyncInfo.fromJson(const <String, dynamic>{
              'state': 2,
              'currentHeight': 100,
              'targetHeight': 100,
            }),
          ),
        );
        final NodeSyncStatusState behindState = NodeSyncStatusState(
          status: TimerStatus.success,
          data: Pair<SyncState, SyncInfo>(
            SyncState.syncing,
            SyncInfo.fromJson(const <String, dynamic>{
              'state': 1,
              'currentHeight': 100,
              'targetHeight': 110,
            }),
          ),
        );
        final _MockNodeSyncStatusCubit syncCubit = _MockNodeSyncStatusCubit();
        final StreamController<NodeSyncStatusState> syncController =
            StreamController<NodeSyncStatusState>.broadcast();
        addTearDown(syncController.close);
        when(() => syncCubit.state).thenReturn(syncedState);
        whenListen<NodeSyncStatusState>(
          syncCubit,
          syncController.stream,
          initialState: syncedState,
        );

        final AppUiPreferencesNotifier uiPrefs = AppUiPreferencesNotifier();
        addTearDown(uiPrefs.dispose);

        await tester.pumpWidget(
          MultiProvider(
            providers: <SingleChildWidget>[
              ChangeNotifierProvider<AppUiPreferencesNotifier>.value(
                value: uiPrefs,
              ),
              BlocProvider<MultipleBalanceBloc>.value(
                value: multipleBalanceBloc,
              ),
              BlocProvider<SendTransactionBloc>.value(value: sendBloc),
              BlocProvider<PendingTransactionsBloc>.value(value: pendingBloc),
              BlocProvider<NodeSyncStatusCubit>.value(value: syncCubit),
            ],
            child: _wrapThemed(const TransferTabChild()),
          ),
        );
        await tester.pumpAndSettle();

        await tester.enterText(
          find.byKey(const Key('send_recipient_field')),
          counterpartyAddress,
        );
        await tester.enterText(
          find.byKey(const Key('send_amount_field')),
          '5',
        );
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const Key('send_submit_button')));
        await tester.pumpAndSettle();
        expect(find.text('Send 5 ZNN?'), findsOneWidget);

        // Node falls behind while the confirmation dialog is still open.
        syncController.add(behindState);
        await tester.pump();
        expect(syncCubit.state.data?.second.targetHeight, 110);

        final Finder confirmSendButton = find.descendant(
          of: find.byType(SyriusModalShell),
          matching: find.text('Send'),
        );
        await tester.tap(confirmSendButton);
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        verifyNever(() => sendBloc.add(any()));
        verify(
          () => mockNotificationsBloc.addErrorNotification(any(), any()),
        ).called(1);
      },
    );
  });
}
