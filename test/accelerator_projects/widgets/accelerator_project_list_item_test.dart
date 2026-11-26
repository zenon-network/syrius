import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/l10n/app_localizations.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/accelerator_projects/accelerator_projects.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class _MockVoteBreakdownBloc
    extends MockBloc<ProjectVoteBreakdownEvent, ProjectVoteBreakdownState>
    implements ProjectVoteBreakdownBloc {}

class _MockVoteProjectBloc extends MockBloc<VoteProjectEvent, VoteProjectState>
    implements VoteProjectBloc {}

Address _address(int seed) => Address.fromPublicKey(List<int>.filled(32, seed));

Hash _hash(int seed) => Hash.digest(List<int>.filled(32, seed));

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

Project _votingProject(Hash id, Address owner) => Project(
  id: id,
  name: 'Accelerator Upgrade',
  owner: owner,
  description: 'Enable producer voting',
  url: 'https://zenon.network',
  znnFundsNeeded: BigInt.from(100 * oneZnn),
  qsrFundsNeeded: BigInt.from(1000 * oneQsr),
  creationTimestamp: DateTime.now().millisecondsSinceEpoch ~/ 1000,
  lastUpdateTimestamp: DateTime.now().millisecondsSinceEpoch ~/ 1000,
  status: AcceleratorProjectStatus.voting.index,
  phaseIds: <Hash>[],
  voteBreakdown: VoteBreakdown.fromJson(<String, dynamic>{
    'id': id.toString(),
    'yes': 0,
    'no': 0,
    'total': 1,
  }),
  phases: <Phase>[],
);

void main() {
  final Address owner = _address(1);
  final Address producer = _address(2);
  final Hash projectId = _hash(5);

  setUpAll(() {
    registerFallbackValue(
      VoteProjectRequested(
        address: emptyAddress,
        id: projectId,
        vote: AcceleratorProjectVote.yes,
      ),
    );
    registerFallbackValue(ProjectVoteBreakdownRequested(projectId: projectId));
  });

  group('AcceleratorProjectListItem', () {
    late _MockVoteBreakdownBloc breakdownBloc;
    late _MockVoteProjectBloc voteBloc;
    late String? previousSelectedAddress;

    setUp(() {
      previousSelectedAddress = kSelectedAddress;
      kSelectedAddress = producer.toString();
      breakdownBloc = _MockVoteBreakdownBloc();
      voteBloc = _MockVoteProjectBloc();
      when(() => voteBloc.state).thenReturn(const VoteProjectInitial());
    });

    tearDown(() async {
      kSelectedAddress = previousSelectedAddress;
      await breakdownBloc.close();
      await voteBloc.close();
    });

    Future<void> pumpItem(
      WidgetTester tester, {
      required PillarInfo? pillarInfo,
      int? activePillarCount = 10,
      int refreshGeneration = 0,
    }) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: SingleChildScrollView(
              child: AcceleratorProjectListItem(
                acceleratorProject: _votingProject(projectId, owner),
                pillarInfo: pillarInfo,
                activePillarCount: activePillarCount,
                refreshGeneration: refreshGeneration,
                onStepperNotificationSeeMorePressed: () {},
                voteBreakdownBloc: breakdownBloc,
                voteProjectBloc: voteBloc,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('shows voting controls for producer pillar and dispatches '
        'VoteProjectRequested with pinned address', (
      WidgetTester tester,
    ) async {
      final PillarInfo pillar = _pillar('alpha', owner, producer);
      when(() => breakdownBloc.state).thenReturn(
        ProjectVoteBreakdownPopulated(
          voteBreakdown: VoteBreakdown.fromJson(<String, dynamic>{
            'id': projectId.toString(),
            'yes': 2,
            'no': 1,
            'total': 3,
          }),
          pillarVotes: const <PillarVote?>[null],
        ),
      );

      await pumpItem(tester, pillarInfo: pillar);

      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
      expect(find.byIcon(Icons.stop), findsOneWidget);

      await tester.tap(find.byIcon(Icons.check_rounded));
      await tester.pump();

      verify(
        () => voteBloc.add(
          VoteProjectRequested(
            address: producer,
            id: projectId,
            vote: AcceleratorProjectVote.yes,
          ),
        ),
      ).called(1);
    });

    testWidgets(
      'hides voting controls when pillarVotes is null (non-pillar account)',
      (WidgetTester tester) async {
        when(() => breakdownBloc.state).thenReturn(
          ProjectVoteBreakdownPopulated(
            voteBreakdown: VoteBreakdown.fromJson(<String, dynamic>{
              'id': projectId.toString(),
              'yes': 2,
              'no': 1,
              'total': 3,
            }),
            pillarVotes: null,
          ),
        );

        await pumpItem(tester, pillarInfo: null);

        expect(find.byIcon(Icons.check_rounded), findsNothing);
        expect(find.byIcon(Icons.close_rounded), findsNothing);
        expect(find.byIcon(Icons.stop), findsNothing);
      },
    );

    testWidgets(
      'renders safely when quorum exceeds activePillarCount and only abstain '
      'votes exist',
      (WidgetTester tester) async {
        when(() => breakdownBloc.state).thenReturn(
          ProjectVoteBreakdownPopulated(
            voteBreakdown: VoteBreakdown.fromJson(<String, dynamic>{
              'id': projectId.toString(),
              'yes': 0,
              'no': 0,
              'total': 15,
            }),
            pillarVotes: null,
          ),
        );

        await pumpItem(tester, pillarInfo: null);

        expect(find.text('Voting results'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets(
      'requires 34 votes (strictly > 33%) for quorum when 100 Pillars are '
      'active',
      (WidgetTester tester) async {
        final StreamController<ProjectVoteBreakdownState> states =
            StreamController<ProjectVoteBreakdownState>.broadcast();
        addTearDown(states.close);

        whenListen<ProjectVoteBreakdownState>(
          breakdownBloc,
          states.stream,
          initialState: ProjectVoteBreakdownPopulated(
            voteBreakdown: VoteBreakdown.fromJson(<String, dynamic>{
              'id': projectId.toString(),
              'yes': 33,
              'no': 0,
              'total': 33,
            }),
            pillarVotes: null,
          ),
        );

        await pumpItem(tester, pillarInfo: null, activePillarCount: 100);

        expect(find.byTooltip('Quorum not achieved'), findsOneWidget);
        expect(
          find.byTooltip('1 more votes needed to achieve quorum'),
          findsOneWidget,
        );

        states.add(
          ProjectVoteBreakdownPopulated(
            voteBreakdown: VoteBreakdown.fromJson(<String, dynamic>{
              'id': projectId.toString(),
              'yes': 34,
              'no': 0,
              'total': 34,
            }),
            pillarVotes: null,
          ),
        );
        await tester.pumpAndSettle();

        expect(find.byTooltip('Quorum achieved'), findsOneWidget);
      },
    );

    testWidgets(
      'waits for VoteProjectDone before refreshing ProjectVoteBreakdownBloc',
      (WidgetTester tester) async {
        final PillarInfo pillar = _pillar('alpha', owner, producer);
        final StreamController<VoteProjectState> voteStates =
            StreamController<VoteProjectState>.broadcast();
        addTearDown(voteStates.close);

        when(() => breakdownBloc.state).thenReturn(
          ProjectVoteBreakdownPopulated(
            voteBreakdown: VoteBreakdown.fromJson(<String, dynamic>{
              'id': projectId.toString(),
              'yes': 2,
              'no': 1,
              'total': 3,
            }),
            pillarVotes: const <PillarVote?>[null],
          ),
        );
        whenListen<VoteProjectState>(
          voteBloc,
          voteStates.stream,
          initialState: const VoteProjectInitial(),
        );

        await pumpItem(tester, pillarInfo: pillar);

        voteStates.add(const VoteProjectLoading());
        await tester.pump();
        await tester.pump();

        expect(find.byType(SyriusLoadingWidget), findsOneWidget);
        verifyNever(() => breakdownBloc.add(any()));

        voteStates.add(
          VoteProjectDone(accountBlock: AccountBlockTemplate(blockType: 2)),
        );
        await tester.pump();
        await tester.pump();

        verify(
          () => breakdownBloc.add(
            ProjectVoteBreakdownRequested(
              pillarName: 'alpha',
              projectId: projectId,
            ),
          ),
        ).called(1);
      },
    );

    testWidgets(
      're-requests ProjectVoteBreakdownBloc when refreshGeneration increments',
      (WidgetTester tester) async {
        final PillarInfo pillar = _pillar('alpha', owner, producer);
        when(() => breakdownBloc.state).thenReturn(
          ProjectVoteBreakdownPopulated(
            voteBreakdown: VoteBreakdown.fromJson(<String, dynamic>{
              'id': projectId.toString(),
              'yes': 2,
              'no': 1,
              'total': 3,
            }),
            pillarVotes: const <PillarVote?>[null],
          ),
        );

        await pumpItem(tester, pillarInfo: pillar);
        verifyNever(() => breakdownBloc.add(any()));

        await pumpItem(tester, pillarInfo: pillar, refreshGeneration: 1);

        verify(
          () => breakdownBloc.add(
            ProjectVoteBreakdownRequested(
              pillarName: 'alpha',
              projectId: projectId,
            ),
          ),
        ).called(1);
      },
    );
  });
}
