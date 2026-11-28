import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:zenon_syrius_wallet_flutter/l10n/app_localizations.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart' as app;
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_theme.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:zenon_syrius_wallet_flutter/utils/notifiers/app_ui_preferences_notifier.dart';
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

class _MockStartP2pSwapBloc
    extends MockBloc<StartP2pSwapEvent, StartP2pSwapState>
    implements StartP2pSwapBloc {}

class _FakeAddress extends Fake implements Address {}

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

      when(() => mockZenon.wsClient).thenReturn(mockWsClient);
      when(() => mockZenon.ledger).thenReturn(mockLedgerApi);
      when(() => mockZenon.embedded).thenReturn(mockEmbeddedApi);
      when(() => mockEmbeddedApi.plasma).thenReturn(mockPlasmaApi);
      when(() => mockEmbeddedApi.pillar).thenReturn(mockPillarApi);
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
  });
}
