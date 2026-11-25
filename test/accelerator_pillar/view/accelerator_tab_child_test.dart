import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layout/layout.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:zenon_syrius_wallet_flutter/l10n/app_localizations.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/exceptions/exceptions.dart';
import 'package:zenon_syrius_wallet_flutter/services/shared_prefs_service.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:zenon_syrius_wallet_flutter/utils/notifiers/default_address_notifier.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/error_widget.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/loading_widget.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/tab_children_widgets/accelerator_tab_child.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

import '../../helpers/hydrated_bloc.dart';

class _TestSelectedAddressNotifier extends SelectedAddressNotifier {
  void select(String address) {
    kSelectedAddress = address;
    notifyListeners();
  }
}

class _MockAcceleratorPillarBloc
    extends MockBloc<AcceleratorPillarEvent, AcceleratorPillarState>
    implements AcceleratorPillarBloc {}

class _MockAcceleratorBalanceBloc
    extends MockBloc<AcceleratorBalanceEvent, AcceleratorBalanceState>
    implements AcceleratorBalanceBloc {}

class _MockProjectListBloc extends MockBloc<ProjectListEvent, ProjectListState>
    implements ProjectListBloc {}

class _MockSharedPrefsService extends Mock implements SharedPrefsService {}

Address _address(int seed) => Address.fromPublicKey(List<int>.filled(32, seed));

PillarInfo _pillar(String name, Address owner, Address producer) =>
    PillarInfo.fromJson(<String, dynamic>{
      'name': name,
      'rank': 1,
      'type': PillarInfo.regularPillarType,
      'ownerAddress': owner.toString(),
      'producerAddress': producer.toString(),
      'withdrawAddress': owner.toString(),
      'giveMomentumRewardPercentage': 0,
      'giveDelegateRewardPercentage': 100,
      'isRevocable': false,
      'revokeCooldown': 0,
      'revokeTimestamp': 0,
      'currentStats': const <String, dynamic>{
        'producedMomentums': 0,
        'expectedMomentums': 0,
      },
      'weight': '0',
    });

Widget _bodyHarness(AcceleratorPillarState state) {
  return MaterialApp(
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: buildAcceleratorTabBody(
        state,
        (PillarInfo? pillarInfo, int? activePillarCount) =>
            Text('layout:${pillarInfo?.name ?? 'none'}:$activePillarCount'),
      ),
    ),
  );
}

void main() {
  initHydratedStorage();

  final Address owner = _address(1);
  final Address producer = _address(2);
  final Address stranger = _address(3);

  setUpAll(() {
    registerFallbackValue(AcceleratorPillarRequested(address: emptyAddress));
    registerFallbackValue(const AcceleratorBalanceRequested());
    registerFallbackValue(const ProjectListRequested());
  });

  group('buildAcceleratorTabBody', () {
    testWidgets(
      'a finished lookup with no pillar shows the layout, not the spinner',
      (WidgetTester tester) async {
        // Regression from PR #156: a completed lookup with null pillarInfo
        // must render the Accelerator tab layout for ordinary accounts.
        await tester.pumpWidget(
          _bodyHarness(
            AcceleratorPillarPopulated(
              address: stranger,
              pillarInfo: null,
              activePillarCount: 50,
            ),
          ),
        );

        expect(find.byType(SyriusLoadingWidget), findsNothing);
        expect(find.text('layout:none:50'), findsOneWidget);
      },
    );

    testWidgets('a finished lookup with a pillar passes it to the layout', (
      WidgetTester tester,
    ) async {
      final PillarInfo pillar = _pillar('test-pillar', owner, producer);
      await tester.pumpWidget(
        _bodyHarness(
          AcceleratorPillarPopulated(
            address: producer,
            pillarInfo: pillar,
            activePillarCount: 50,
          ),
        ),
      );

      expect(find.text('layout:test-pillar:50'), findsOneWidget);
    });

    testWidgets('a lookup still in flight shows the loading widget', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _bodyHarness(AcceleratorPillarLoading(address: stranger)),
      );

      expect(find.byType(SyriusLoadingWidget), findsOneWidget);
    });

    testWidgets('a failed lookup shows the error widget', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        _bodyHarness(
          AcceleratorPillarFailure(exception: SyriusException('node offline')),
        ),
      );

      expect(find.byType(SyriusErrorWidget), findsOneWidget);
      expect(find.textContaining('node offline'), findsOneWidget);
    });
  });

  group('AcceleratorTabChild', () {
    late _MockAcceleratorPillarBloc pillarBloc;
    late _MockAcceleratorBalanceBloc balanceBloc;
    late _MockProjectListBloc projectListBloc;
    late _MockSharedPrefsService mockSharedPrefs;
    late _TestSelectedAddressNotifier addressNotifier;
    late SharedPrefsService? previousSharedPrefs;
    late String? previousSelectedAddress;

    setUp(() {
      previousSharedPrefs = sharedPrefsService;
      previousSelectedAddress = kSelectedAddress;

      mockSharedPrefs = _MockSharedPrefsService();
      when(
        () => mockSharedPrefs.get(
          any(),
          defaultValue: any(named: 'defaultValue'),
        ),
      ).thenReturn(false);
      sharedPrefsService = mockSharedPrefs;
      kSelectedAddress = stranger.toString();

      pillarBloc = _MockAcceleratorPillarBloc();
      balanceBloc = _MockAcceleratorBalanceBloc();
      projectListBloc = _MockProjectListBloc();
      addressNotifier = _TestSelectedAddressNotifier();

      when(() => balanceBloc.state).thenReturn(
        AcceleratorBalanceFailure(exception: AcceleratorFundEmptyException()),
      );
      when(
        () => projectListBloc.state,
      ).thenReturn(const ProjectListState(status: ProjectListStatus.populated));
    });

    tearDown(() async {
      sharedPrefsService = previousSharedPrefs;
      kSelectedAddress = previousSelectedAddress;
      addressNotifier.dispose();
      await pillarBloc.close();
      await balanceBloc.close();
      await projectListBloc.close();
    });

    Future<void> pumpTab(WidgetTester tester) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        ChangeNotifierProvider<SelectedAddressNotifier>.value(
          value: addressNotifier,
          child: Layout(
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: AcceleratorTabChild(
                  onStepperNotificationSeeMorePressed: () {},
                  pillarBloc: pillarBloc,
                  balanceBloc: balanceBloc,
                  projectListBloc: projectListBloc,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets(
      'renders all cards and hides voting filter chips for non-pillar account',
      (WidgetTester tester) async {
        when(() => pillarBloc.state).thenReturn(
          AcceleratorPillarPopulated(
            address: stranger,
            pillarInfo: null,
            activePillarCount: 30,
          ),
        );

        await pumpTab(tester);

        expect(find.byType(AcceleratorDonationsCard), findsOneWidget);
        expect(find.byType(AcceleratorStatsCard), findsOneWidget);
        expect(find.byType(CreateProjectCard), findsOneWidget);
        expect(find.byType(AcceleratorProjectsCard), findsOneWidget);
        expect(find.text('Accelerator Donations'), findsWidgets);
        expect(find.text('Accelerator Stats'), findsWidgets);
        expect(find.text('Create project'), findsWidgets);
        expect(find.text('Project List'), findsWidgets);
        expect(find.text('My projects'), findsOneWidget);
        expect(find.text('Only accepted'), findsOneWidget);
        expect(find.text('Needs voting'), findsNothing);
        expect(find.text('Already voted'), findsNothing);
      },
    );

    testWidgets('shows voting filter chips for producer pillar account', (
      WidgetTester tester,
    ) async {
      final PillarInfo pillar = _pillar('prod-pillar', owner, producer);
      kSelectedAddress = producer.toString();
      when(() => pillarBloc.state).thenReturn(
        AcceleratorPillarPopulated(
          address: producer,
          pillarInfo: pillar,
          activePillarCount: 30,
        ),
      );

      await pumpTab(tester);

      expect(find.text('Needs voting'), findsOneWidget);
      expect(find.text('Already voted'), findsOneWidget);
    });

    testWidgets(
      'dispatches AcceleratorPillarRequested when selected address changes',
      (WidgetTester tester) async {
        when(() => pillarBloc.state).thenReturn(
          AcceleratorPillarPopulated(
            address: stranger,
            pillarInfo: null,
            activePillarCount: 30,
          ),
        );

        await pumpTab(tester);

        addressNotifier.select(producer.toString());
        await tester.pump();

        verify(
          () => pillarBloc.add(AcceleratorPillarRequested(address: producer)),
        ).called(1);
      },
    );
  });
}
