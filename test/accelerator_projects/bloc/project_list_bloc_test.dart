import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/accelerator_projects/accelerator_projects.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/exceptions/exceptions.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class _MockZenon extends Mock implements Zenon {}

class _MockEmbeddedApi extends Mock implements EmbeddedApi {}

class _MockAcceleratorApi extends Mock implements AcceleratorApi {}

Address _address(int seed) => Address.fromPublicKey(List<int>.filled(32, seed));

Hash _hash(int seed) => Hash.digest(List<int>.filled(32, seed));

Project _project({
  required int seed,
  required String name,
  required Address owner,
  required AcceleratorProjectStatus status,
  int lastUpdateTimestamp = 1000,
  List<Phase> phases = const <Phase>[],
}) {
  final Hash id = _hash(seed);
  return Project(
    id: id,
    name: name,
    owner: owner,
    description: 'Description for $name',
    url: 'https://$name.example.org',
    znnFundsNeeded: BigInt.from(100),
    qsrFundsNeeded: BigInt.from(1000),
    creationTimestamp: 100,
    lastUpdateTimestamp: lastUpdateTimestamp,
    status: status.index,
    phaseIds: phases.map((Phase p) => p.id).toList(),
    voteBreakdown: VoteBreakdown.fromJson(<String, dynamic>{
      'id': id.toString(),
      'yes': 1,
      'no': 0,
      'total': 1,
    }),
    phases: phases,
  );
}

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

ProjectList _projectList(List<Project> items) =>
    ProjectList.fromJson(<String, dynamic>{
      'count': items.length,
      'list': items
          .map(
            (Project p) => <String, dynamic>{
              'id': p.id.toString(),
              'owner': p.owner.toString(),
              'name': p.name,
              'description': p.description,
              'url': p.url,
              'znnFundsNeeded': p.znnFundsNeeded.toString(),
              'qsrFundsNeeded': p.qsrFundsNeeded.toString(),
              'creationTimestamp': p.creationTimestamp,
              'lastUpdateTimestamp': p.lastUpdateTimestamp,
              'status': p.statusInt,
              'votes': p.voteBreakdown.toJson(),
              'phaseIds': p.phaseIds.map((Hash h) => h.toString()).toList(),
              'phases': p.phases
                  .map(
                    (Phase ph) => <String, dynamic>{
                      'phase': <String, dynamic>{
                        'id': ph.id.toString(),
                        'projectID': ph.projectId.toString(),
                        'name': ph.name,
                        'description': ph.description,
                        'url': ph.url,
                        'znnFundsNeeded': ph.znnFundsNeeded.toString(),
                        'qsrFundsNeeded': ph.qsrFundsNeeded.toString(),
                        'creationTimestamp': ph.creationTimestamp,
                        'acceptedTimestamp': ph.acceptedTimestamp,
                        'status': ph.statusInt,
                      },
                      'votes': ph.voteBreakdown.toJson(),
                    },
                  )
                  .toList(),
            },
          )
          .toList(),
    });

void main() {
  final Address myAddr = _address(1);
  final Address otherAddr = _address(2);
  final Address prodAddr = _address(3);

  group('ProjectListBloc', () {
    late _MockZenon zenon;
    late _MockEmbeddedApi embedded;
    late _MockAcceleratorApi acceleratorApi;
    late Project activeOther;
    late Project votingOther;
    late Project votingMine;

    setUp(() {
      zenon = _MockZenon();
      embedded = _MockEmbeddedApi();
      acceleratorApi = _MockAcceleratorApi();
      when(() => zenon.embedded).thenReturn(embedded);
      when(() => embedded.accelerator).thenReturn(acceleratorApi);

      activeOther = _project(
        seed: 1,
        name: 'ActiveProject',
        owner: otherAddr,
        status: AcceleratorProjectStatus.active,
        lastUpdateTimestamp: 300,
      );
      votingOther = _project(
        seed: 2,
        name: 'VotingProject',
        owner: otherAddr,
        status: AcceleratorProjectStatus.voting,
        lastUpdateTimestamp: 100,
      );
      votingMine = _project(
        seed: 3,
        name: 'MyProposal',
        owner: myAddr,
        status: AcceleratorProjectStatus.voting,
        lastUpdateTimestamp: 200,
      );
    });

    blocTest<ProjectListBloc, ProjectListState>(
      'non-pillar address sees only active projects and wallet-owned projects',
      setUp: () {
        when(() => acceleratorApi.getAll(pageSize: 10)).thenAnswer(
          (_) async =>
              _projectList(<Project>[activeOther, votingOther, votingMine]),
        );
      },
      build: () => ProjectListBloc(
        zenon: zenon,
        walletAddressesProvider: () => <String>[myAddr.toString()],
        pageSize: 10,
        listenToWsReconnect: false,
      ),
      act: (ProjectListBloc bloc) => bloc.add(const ProjectListRequested()),
      expect: () => <Matcher>[
        isA<ProjectListState>().having(
          (ProjectListState s) => s.status,
          'status',
          ProjectListStatus.loading,
        ),
        isA<ProjectListState>()
            .having(
              (ProjectListState s) => s.status,
              'status',
              ProjectListStatus.populated,
            )
            .having(
              (ProjectListState s) =>
                  s.projects.map((Project p) => p.name).toList(),
              'project names',
              <String>['ActiveProject', 'MyProposal'],
            ),
      ],
    );

    blocTest<ProjectListBloc, ProjectListState>(
      'pillar address sees all projects including multi-page results and supports needsVoting / alreadyVoted',
      setUp: () {
        when(() => acceleratorApi.getAll(pageSize: 2)).thenAnswer(
          (_) async => _projectList(<Project>[activeOther, votingOther]),
        );
        when(
          () => acceleratorApi.getAll(pageIndex: 1, pageSize: 2),
        ).thenAnswer((_) async => _projectList(<Project>[votingMine]));
        when(() => acceleratorApi.getPillarVotes('alpha', any())).thenAnswer((
          Invocation invocation,
        ) async {
          final List<String> requestedIds =
              invocation.positionalArguments[1] as List<String>;
          return requestedIds.map((String id) {
            if (id == votingMine.id.toString()) {
              return PillarVote.fromJson(<String, dynamic>{
                'id': id,
                'name': 'alpha',
                'vote': AcceleratorProjectVote.yes.index,
              });
            }
            return null;
          }).toList();
        });
      },
      build: () => ProjectListBloc(
        zenon: zenon,
        pillarInfo: _pillar('alpha', otherAddr, prodAddr),
        walletAddressesProvider: () => <String>[prodAddr.toString()],
        pageSize: 2,
        listenToWsReconnect: false,
      ),
      act: (ProjectListBloc bloc) async {
        bloc.add(const ProjectListRequested());
        await Future<void>.delayed(Duration.zero);
        bloc.add(
          const ProjectListFilterTagToggled(
            tag: AcceleratorProjectFilterTag.needsVoting,
          ),
        );
      },
      verify: (ProjectListBloc bloc) {
        expect(bloc.state.status, ProjectListStatus.populated);
        expect(
          bloc.state.projects.map((Project p) => p.name).toList(),
          <String>['VotingProject'],
        );
      },
    );

    blocTest<ProjectListBloc, ProjectListState>(
      'sorts projects ascending then descending by lastUpdateTimestamp',
      setUp: () {
        when(() => acceleratorApi.getAll(pageSize: 10)).thenAnswer(
          (_) async =>
              _projectList(<Project>[activeOther, votingOther, votingMine]),
        );
      },
      build: () => ProjectListBloc(
        zenon: zenon,
        pillarInfo: _pillar('alpha', myAddr, prodAddr),
        walletAddressesProvider: () => <String>[myAddr.toString()],
        pageSize: 10,
        listenToWsReconnect: false,
      ),
      act: (ProjectListBloc bloc) async {
        bloc.add(const ProjectListRequested());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const ProjectListSortToggled());
      },
      verify: (ProjectListBloc bloc) {
        expect(
          bloc.state.projects.map((Project p) => p.name).toList(),
          <String>['VotingProject', 'MyProposal', 'ActiveProject'],
        );
      },
    );

    blocTest<ProjectListBloc, ProjectListState>(
      'clears pillar-only filter tags when pillarInfo becomes null',
      setUp: () {
        when(() => acceleratorApi.getAll(pageSize: 10)).thenAnswer(
          (_) async => _projectList(<Project>[activeOther, votingOther]),
        );
        when(
          () => acceleratorApi.getPillarVotes('alpha', any()),
        ).thenAnswer((_) async => <PillarVote?>[null, null]);
      },
      build: () => ProjectListBloc(
        zenon: zenon,
        pillarInfo: _pillar('alpha', myAddr, prodAddr),
        walletAddressesProvider: () => <String>[myAddr.toString()],
        pageSize: 10,
        listenToWsReconnect: false,
      ),
      act: (ProjectListBloc bloc) async {
        bloc.add(
          const ProjectListFilterTagToggled(
            tag: AcceleratorProjectFilterTag.needsVoting,
          ),
        );
        await Future<void>.delayed(Duration.zero);
        bloc.add(const ProjectListPillarUpdated(pillarInfo: null));
      },
      verify: (ProjectListBloc bloc) {
        expect(bloc.state.pillarInfo, isNull);
        expect(bloc.state.selectedTags, isEmpty);
        expect(
          bloc.state.projects.map((Project p) => p.name).toList(),
          <String>['ActiveProject'],
        );
      },
    );

    blocTest<ProjectListBloc, ProjectListState>(
      'refresh clears cache and search query and re-fetches from RPC',
      setUp: () {
        when(
          () => acceleratorApi.getAll(pageSize: 10),
        ).thenAnswer((_) async => _projectList(<Project>[activeOther]));
      },
      build: () => ProjectListBloc(
        zenon: zenon,
        walletAddressesProvider: () => <String>[myAddr.toString()],
        debounceDuration: Duration.zero,
        pageSize: 10,
        listenToWsReconnect: false,
      ),
      act: (ProjectListBloc bloc) async {
        bloc.add(const ProjectListSearchChanged(query: 'nonexistent'));
        await Future<void>.delayed(const Duration(milliseconds: 20));
        bloc.add(const ProjectListRequested(refresh: true, clearSearch: true));
      },
      verify: (ProjectListBloc bloc) {
        expect(bloc.state.searchQuery, isEmpty);
        expect(bloc.state.projects.length, 1);
        verify(() => acceleratorApi.getAll(pageSize: 10)).called(2);
      },
    );

    blocTest<ProjectListBloc, ProjectListState>(
      'emits failure when accelerator.getAll throws',
      setUp: () {
        when(
          () => acceleratorApi.getAll(
            pageIndex: any(named: 'pageIndex'),
            pageSize: any(named: 'pageSize'),
          ),
        ).thenThrow(Exception('rpc failure'));
      },
      build: () => ProjectListBloc(zenon: zenon, listenToWsReconnect: false),
      act: (ProjectListBloc bloc) => bloc.add(const ProjectListRequested()),
      expect: () => <Matcher>[
        isA<ProjectListState>().having(
          (ProjectListState s) => s.status,
          'status',
          ProjectListStatus.loading,
        ),
        isA<ProjectListState>()
            .having(
              (ProjectListState s) => s.status,
              'status',
              ProjectListStatus.failure,
            )
            .having(
              (ProjectListState s) => s.exception,
              'exception',
              isA<FailureException>(),
            ),
      ],
    );

    test(
      'ignores stale refresh response that completes after a newer search',
      () async {
        final Completer<ProjectList> refreshCompleter =
            Completer<ProjectList>();
        final Completer<ProjectList> searchCompleter = Completer<ProjectList>();
        int callCount = 0;

        when(() => acceleratorApi.getAll(pageSize: 10)).thenAnswer((_) {
          callCount += 1;
          return callCount == 1
              ? refreshCompleter.future
              : searchCompleter.future;
        });

        final ProjectListBloc bloc = ProjectListBloc(
          zenon: zenon,
          walletAddressesProvider: () => <String>[myAddr.toString()],
          debounceDuration: Duration.zero,
          pageSize: 10,
          listenToWsReconnect: false,
        )..add(const ProjectListRequested(refresh: true));
        await Future<void>.delayed(Duration.zero);

        bloc.add(const ProjectListSearchChanged(query: 'MyProposal'));
        await Future<void>.delayed(const Duration(milliseconds: 20));

        // Search completes first with filtered list.
        searchCompleter.complete(
          _projectList(<Project>[activeOther, votingMine]),
        );
        await Future<void>.delayed(Duration.zero);

        expect(bloc.state.status, ProjectListStatus.populated);
        expect(bloc.state.searchQuery, 'MyProposal');
        expect(
          bloc.state.projects.map((Project p) => p.name).toList(),
          <String>['MyProposal'],
        );

        // Stale unfiltered refresh completes second and must be ignored.
        refreshCompleter.complete(
          _projectList(<Project>[activeOther, votingMine]),
        );
        await Future<void>.delayed(Duration.zero);

        expect(bloc.state.status, ProjectListStatus.populated);
        expect(bloc.state.searchQuery, 'MyProposal');
        expect(
          bloc.state.projects.map((Project p) => p.name).toList(),
          <String>['MyProposal'],
        );

        await bloc.close();
      },
    );

    test('ignores stale pillar filter response that completes after pillar '
        'changes', () async {
      final PillarInfo pillarA = _pillar('alpha', myAddr, prodAddr);
      final PillarInfo pillarB = _pillar('beta', otherAddr, prodAddr);
      final Completer<List<PillarVote?>> pillarAVotes =
          Completer<List<PillarVote?>>();
      final Completer<List<PillarVote?>> pillarBVotes =
          Completer<List<PillarVote?>>();

      when(() => acceleratorApi.getAll(pageSize: 10)).thenAnswer(
        (_) async =>
            _projectList(<Project>[activeOther, votingOther, votingMine]),
      );
      when(
        () => acceleratorApi.getPillarVotes('alpha', any()),
      ).thenAnswer((_) => pillarAVotes.future);
      when(
        () => acceleratorApi.getPillarVotes('beta', any()),
      ).thenAnswer((_) => pillarBVotes.future);

      // Initial fetch populates cache.
      final ProjectListBloc bloc = ProjectListBloc(
        zenon: zenon,
        pillarInfo: pillarA,
        walletAddressesProvider: () => <String>[myAddr.toString()],
        pageSize: 10,
        listenToWsReconnect: false,
      )..add(const ProjectListRequested());
      await Future<void>.delayed(Duration.zero);

      // Trigger slow filter for pillarA.
      bloc.add(
        const ProjectListFilterTagToggled(
          tag: AcceleratorProjectFilterTag.needsVoting,
        ),
      );
      await Future<void>.delayed(Duration.zero);

      // Switch active pillar to pillarB while pillarA's vote lookup is still
      // in flight.
      bloc.add(ProjectListPillarUpdated(pillarInfo: pillarB));
      await Future<void>.delayed(Duration.zero);

      // pillarB finishes first (already voted on votingOther, so only
      // votingMine needs voting).
      pillarBVotes.complete(<PillarVote?>[
        null,
        PillarVote.fromJson(<String, dynamic>{
          'id': votingOther.id.toString(),
          'name': 'beta',
          'vote': AcceleratorProjectVote.yes.index,
        }),
        null,
      ]);
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.status, ProjectListStatus.populated);
      expect(bloc.state.pillarInfo?.name, 'beta');
      expect(bloc.state.projects.map((Project p) => p.name).toList(), <String>[
        'MyProposal',
      ]);

      // Stale pillarA response arrives late and must not revert pillarInfo
      // or projects.
      pillarAVotes.complete(<PillarVote?>[null, null, null]);
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.status, ProjectListStatus.populated);
      expect(bloc.state.pillarInfo?.name, 'beta');
      expect(bloc.state.projects.map((Project p) => p.name).toList(), <String>[
        'MyProposal',
      ]);

      await bloc.close();
    });

    test('preserves pending refresh when overtaken by search so new projects '
        'appear', () async {
      final Completer<ProjectList> refreshCompleter = Completer<ProjectList>();
      final Completer<ProjectList> searchFetchCompleter =
          Completer<ProjectList>();
      int callCount = 0;

      when(() => acceleratorApi.getAll(pageSize: 10)).thenAnswer((_) {
        callCount += 1;
        if (callCount == 1) {
          return Future<ProjectList>.value(
            _projectList(<Project>[activeOther]),
          );
        }
        if (callCount == 2) {
          return refreshCompleter.future;
        }
        return searchFetchCompleter.future;
      });

      // 1. Initial load caches [ActiveProject].
      final ProjectListBloc bloc = ProjectListBloc(
        zenon: zenon,
        walletAddressesProvider: () => <String>[myAddr.toString()],
        debounceDuration: Duration.zero,
        pageSize: 10,
        listenToWsReconnect: false,
      )..add(const ProjectListRequested());
      await Future<void>.delayed(Duration.zero);
      expect(bloc.state.projects.map((Project p) => p.name).toList(), <String>[
        'ActiveProject',
      ]);

      // 2. Refresh starts while the node now has [ActiveProject, MyProposal].
      bloc.add(const ProjectListRequested(refresh: true));
      await Future<void>.delayed(Duration.zero);

      // 3. Search overtakes the in-flight refresh. Because cache is stale,
      // it must fetch fresh data instead of serving the old cache.
      bloc.add(const ProjectListSearchChanged(query: 'MyProposal'));
      await Future<void>.delayed(const Duration(milliseconds: 20));

      // 4. Search fetch resolves with the new project; then the overtaken
      // refresh finishes later.
      searchFetchCompleter.complete(
        _projectList(<Project>[activeOther, votingMine]),
      );
      await Future<void>.delayed(Duration.zero);
      refreshCompleter.complete(
        _projectList(<Project>[activeOther, votingMine]),
      );
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.status, ProjectListStatus.populated);
      expect(bloc.state.projects.map((Project p) => p.name).toList(), <String>[
        'MyProposal',
      ]);

      // Clearing search shows both projects from the refreshed cache without
      // needing another manual refresh.
      bloc.add(const ProjectListSearchChanged(query: ''));
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(bloc.state.projects.map((Project p) => p.name).toList(), <String>[
        'ActiveProject',
        'MyProposal',
      ]);

      await bloc.close();
    });
  });
}
