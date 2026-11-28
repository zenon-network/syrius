import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layout/layout.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/l10n/app_localizations.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/services/shared_prefs_service.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

import '../../helpers/hydrated_bloc.dart';

class _MockRefreshProjectBloc
    extends MockBloc<RefreshProjectEvent, RefreshProjectState>
    implements RefreshProjectBloc {}

class _MockSharedPrefsService extends Mock implements SharedPrefsService {}

class _MockNotificationsBloc
    extends MockBloc<NotificationsEvent, NotificationsState>
    implements NotificationsBloc {}

class _MockZenon extends Mock implements Zenon {}

class _MockEmbeddedApi extends Mock implements EmbeddedApi {}

class _MockAcceleratorApi extends Mock implements AcceleratorApi {}

Address _address(int seed) => Address.fromPublicKey(List<int>.filled(32, seed));

Hash _hash(int seed) => Hash.digest(List<int>.filled(32, seed));

Project _project(Hash id, Address owner) => Project(
  id: id,
  name: 'Hyperion',
  owner: owner,
  description: 'Next-gen wallet upgrades',
  url: 'https://zenon.network',
  znnFundsNeeded: BigInt.from(100 * oneZnn),
  qsrFundsNeeded: BigInt.from(1000 * oneQsr),
  creationTimestamp: 1700000000,
  lastUpdateTimestamp: 1700000000,
  status: AcceleratorProjectStatus.active.index,
  phaseIds: <Hash>[],
  voteBreakdown: VoteBreakdown.fromJson(<String, dynamic>{
    'id': id.toString(),
    'yes': 10,
    'no': 0,
    'total': 10,
  }),
  phases: <Phase>[],
);

void main() {
  initHydratedStorage();

  final Address owner = _address(1);
  final Address visitor = _address(2);
  final Hash projectId = _hash(7);

  group('ProjectDetailsScreen', () {
    late _MockRefreshProjectBloc refreshProjectBloc;
    late _MockSharedPrefsService mockSharedPrefs;
    late _MockNotificationsBloc mockNotificationsBloc;
    late StreamController<NotificationsState> notificationsController;
    late SharedPrefsService? previousSharedPrefs;
    late String? previousSelectedAddress;
    late bool registeredNotifications;

    setUp(() async {
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

      notificationsController =
          StreamController<NotificationsState>.broadcast();
      mockNotificationsBloc = _MockNotificationsBloc();
      whenListen<NotificationsState>(
        mockNotificationsBloc,
        notificationsController.stream,
        initialState: const NotificationsState(),
      );
      if (sl.isRegistered<NotificationsBloc>()) {
        await sl.unregister<NotificationsBloc>();
      }
      sl.registerSingleton<NotificationsBloc>(mockNotificationsBloc);
      registeredNotifications = true;

      refreshProjectBloc = _MockRefreshProjectBloc();
    });

    tearDown(() async {
      sharedPrefsService = previousSharedPrefs;
      kSelectedAddress = previousSelectedAddress;
      if (registeredNotifications && sl.isRegistered<NotificationsBloc>()) {
        sl.unregister<NotificationsBloc>();
      }
      await notificationsController.close();
      await refreshProjectBloc.close();
    });

    Future<void> pumpScreen(WidgetTester tester, Project project) async {
      tester.view.physicalSize = const Size(1400, 1000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        Layout(
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: ProjectDetailsScreen(
              project: project,
              pillarInfo: null,
              activePillarCount: 30,
              onStepperNotificationSeeMorePressed: () {},
              refreshProjectBloc: refreshProjectBloc,
            ),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets(
      'shows project metadata, Create phase, and empty phases list for project '
      'owner',
      (WidgetTester tester) async {
        final Project project = _project(projectId, owner);
        kSelectedAddress = owner.toString();
        when(
          () => refreshProjectBloc.state,
        ).thenReturn(RefreshProjectPopulated(project: project));

        await pumpScreen(tester, project);

        expect(find.text('Hyperion'), findsOneWidget);
        expect(find.text('BUDGET'), findsOneWidget);
        expect(find.text('Create phase'), findsOneWidget);
        expect(find.text('Phases'), findsOneWidget);
        expect(find.text('The project has no phases'), findsOneWidget);
      },
    );

    testWidgets('hides Create phase action for non-owner viewer', (
      WidgetTester tester,
    ) async {
      final Project project = _project(projectId, owner);
      kSelectedAddress = visitor.toString();
      when(
        () => refreshProjectBloc.state,
      ).thenReturn(RefreshProjectPopulated(project: project));

      await pumpScreen(tester, project);

      expect(find.text('Hyperion'), findsOneWidget);
      expect(find.text('Create phase'), findsNothing);
      expect(find.text('Phases'), findsOneWidget);
    });

    testWidgets(
      'keeps phases mounted and shows RefreshButton loading during '
      'subsequent RefreshProjectLoading',
      (WidgetTester tester) async {
        final Project project = _project(projectId, owner);
        final StreamController<RefreshProjectState> states =
            StreamController<RefreshProjectState>.broadcast();
        addTearDown(states.close);

        kSelectedAddress = visitor.toString();
        whenListen<RefreshProjectState>(
          refreshProjectBloc,
          states.stream,
          initialState: RefreshProjectPopulated(project: project),
        );

        await pumpScreen(tester, project);

        expect(find.text('Phases'), findsOneWidget);
        expect(
          find.descendant(
            of: find.byType(RefreshButton),
            matching: find.byIcon(Icons.refresh),
          ),
          findsOneWidget,
        );

        states.add(const RefreshProjectLoading());
        await tester.pump();
        await tester.pump();

        expect(find.text('Phases'), findsOneWidget);
        expect(
          find.descendant(
            of: find.byType(RefreshButton),
            matching: find.byType(SyriusLoadingWidget),
          ),
          findsOneWidget,
        );

        states.add(RefreshProjectPopulated(project: project));
        await tester.pump();
        await tester.pump();

        expect(
          find.descendant(
            of: find.byType(RefreshButton),
            matching: find.byIcon(Icons.refresh),
          ),
          findsOneWidget,
        );

        // A failure clears the retained project so a later loading state shows
        // the full-screen loader instead of stale content.
        states.add(RefreshProjectFailure(exception: FailureException()));
        await tester.pump();
        await tester.pump();
        expect(find.text('Phases'), findsNothing);
        expect(find.byType(SyriusErrorWidget), findsOneWidget);

        states.add(const RefreshProjectLoading());
        await tester.pump();
        await tester.pump();
        expect(find.text('Phases'), findsNothing);
        expect(find.byType(SyriusLoadingWidget), findsOneWidget);
      },
    );

    testWidgets(
      're-requests retained phase vote breakdowns when header refresh '
      'completes',
      (WidgetTester tester) async {
        final Hash phaseId = _hash(9);
        final Phase phase = Phase(
          id: phaseId,
          projectId: projectId,
          name: 'Phase 1',
          description: 'Initial milestone',
          url: 'https://zenon.network',
          znnFundsNeeded: BigInt.from(50 * oneZnn),
          qsrFundsNeeded: BigInt.from(500 * oneQsr),
          creationTimestamp: 1700000100,
          acceptedTimestamp: 0,
          status: AcceleratorProjectStatus.voting.index,
          voteBreakdown: VoteBreakdown.fromJson(<String, dynamic>{
            'id': phaseId.toString(),
            'yes': 1,
            'no': 0,
            'total': 1,
          }),
        );
        final Project projectWithPhase = Project(
          id: projectId,
          name: 'Hyperion',
          owner: owner,
          description: 'Next-gen wallet upgrades',
          url: 'https://zenon.network',
          znnFundsNeeded: BigInt.from(100 * oneZnn),
          qsrFundsNeeded: BigInt.from(1000 * oneQsr),
          creationTimestamp: 1700000000,
          lastUpdateTimestamp: 1700000000,
          status: AcceleratorProjectStatus.active.index,
          phaseIds: <Hash>[phaseId],
          voteBreakdown: VoteBreakdown.fromJson(<String, dynamic>{
            'id': projectId.toString(),
            'yes': 10,
            'no': 0,
            'total': 10,
          }),
          phases: <Phase>[phase],
        );

        final _MockZenon mockZenon = _MockZenon();
        final _MockEmbeddedApi mockEmbedded = _MockEmbeddedApi();
        final _MockAcceleratorApi mockAccelerator = _MockAcceleratorApi();
        when(() => mockZenon.embedded).thenReturn(mockEmbedded);
        when(() => mockEmbedded.accelerator).thenReturn(mockAccelerator);
        when(() => mockAccelerator.getVoteBreakdown(phaseId)).thenAnswer(
          (_) async => VoteBreakdown.fromJson(<String, dynamic>{
            'id': phaseId.toString(),
            'yes': 2,
            'no': 0,
            'total': 2,
          }),
        );

        final Zenon? previousZenon = zenon;
        zenon = mockZenon;
        addTearDown(() {
          zenon = previousZenon;
        });

        final StreamController<RefreshProjectState> states =
            StreamController<RefreshProjectState>.broadcast();
        addTearDown(states.close);

        kSelectedAddress = visitor.toString();
        whenListen<RefreshProjectState>(
          refreshProjectBloc,
          states.stream,
          initialState: RefreshProjectPopulated(project: projectWithPhase),
        );

        await pumpScreen(tester, projectWithPhase);
        await tester.pump();
        verify(() => mockAccelerator.getVoteBreakdown(phaseId)).called(1);

        // Header refresh keeps phase mounted and re-requests its breakdown
        // once RefreshProjectPopulated completes.
        states.add(const RefreshProjectLoading());
        await tester.pump();
        await tester.pump();
        expect(find.text('1 · Phase 1'), findsOneWidget);

        states.add(RefreshProjectPopulated(project: projectWithPhase));
        await tester.pump();
        await tester.pump();
        verify(() => mockAccelerator.getVoteBreakdown(phaseId)).called(1);
      },
    );
  });
}
