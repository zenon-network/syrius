import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:layout/layout.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/notifications_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/l10n/app_localizations.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/model/database/wallet_notification.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/services/shared_prefs_service.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

import '../../helpers/hydrated_bloc.dart';

class _MockRefreshProjectBloc
    extends MockBloc<RefreshProjectEvent, RefreshProjectState>
    implements RefreshProjectBloc {}

class _MockSharedPrefsService extends Mock implements SharedPrefsService {}

class _MockNotificationsBloc extends Mock implements NotificationsBloc {}

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
    late StreamController<WalletNotification?> notificationsController;
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
          StreamController<WalletNotification?>.broadcast();
      mockNotificationsBloc = _MockNotificationsBloc();
      when(
        () => mockNotificationsBloc.stream,
      ).thenAnswer((_) => notificationsController.stream);
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
      'shows Project Stats, Create phase, and empty Phase List for project '
      'owner',
      (WidgetTester tester) async {
        final Project project = _project(projectId, owner);
        kSelectedAddress = owner.toString();
        when(
          () => refreshProjectBloc.state,
        ).thenReturn(RefreshProjectPopulated(project: project));

        await pumpScreen(tester, project);

        expect(find.byType(ProjectStatsCard), findsOneWidget);
        expect(find.byType(CreatePhaseCard), findsOneWidget);
        expect(find.byType(PhaseListCard), findsOneWidget);
        expect(find.text('Project Stats'), findsWidgets);
        expect(find.text('Create phase'), findsWidgets);
        expect(find.text('Phase List'), findsWidgets);
        expect(find.text('The project has no phases'), findsOneWidget);
      },
    );

    testWidgets('hides Create phase card for non-owner viewer', (
      WidgetTester tester,
    ) async {
      final Project project = _project(projectId, owner);
      kSelectedAddress = visitor.toString();
      when(
        () => refreshProjectBloc.state,
      ).thenReturn(RefreshProjectPopulated(project: project));

      await pumpScreen(tester, project);

      expect(find.byType(ProjectStatsCard), findsOneWidget);
      expect(find.byType(CreatePhaseCard), findsNothing);
      expect(find.byType(PhaseListCard), findsOneWidget);
      expect(find.text('Project Stats'), findsWidgets);
      expect(find.text('Create phase'), findsNothing);
      expect(find.text('Phase List'), findsWidgets);
    });
  });
}
