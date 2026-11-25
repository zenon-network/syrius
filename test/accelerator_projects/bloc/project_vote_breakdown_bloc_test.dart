import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/accelerator_projects/accelerator_projects.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/exceptions/exceptions.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class _MockZenon extends Mock implements Zenon {}

class _MockEmbeddedApi extends Mock implements EmbeddedApi {}

class _MockAcceleratorApi extends Mock implements AcceleratorApi {}

void main() {
  final Hash projectId = Hash.digest(List<int>.filled(32, 3));

  VoteBreakdown createBreakdown() => VoteBreakdown.fromJson(<String, dynamic>{
    'id': projectId.toString(),
    'yes': 5,
    'no': 1,
    'total': 7,
  });

  PillarVote createVote() => PillarVote.fromJson(<String, dynamic>{
    'id': projectId.toString(),
    'name': 'alpha',
    'vote': AcceleratorProjectVote.yes.index,
  });

  group('ProjectVoteBreakdownBloc', () {
    late _MockZenon zenon;
    late _MockEmbeddedApi embedded;
    late _MockAcceleratorApi acceleratorApi;

    setUp(() {
      zenon = _MockZenon();
      embedded = _MockEmbeddedApi();
      acceleratorApi = _MockAcceleratorApi();
      when(() => zenon.embedded).thenReturn(embedded);
      when(() => embedded.accelerator).thenReturn(acceleratorApi);
    });

    test('initial state is ProjectVoteBreakdownInitial', () async {
      final ProjectVoteBreakdownBloc bloc = ProjectVoteBreakdownBloc(
        zenon: zenon,
      );
      expect(bloc.state, const ProjectVoteBreakdownInitial());
      await bloc.close();
    });

    blocTest<ProjectVoteBreakdownBloc, ProjectVoteBreakdownState>(
      'fetches breakdown only when pillarName is null',
      setUp: () {
        when(
          () => acceleratorApi.getVoteBreakdown(projectId),
        ).thenAnswer((_) async => createBreakdown());
      },
      build: () => ProjectVoteBreakdownBloc(zenon: zenon),
      act: (ProjectVoteBreakdownBloc bloc) =>
          bloc.add(ProjectVoteBreakdownRequested(projectId: projectId)),
      expect: () => <Matcher>[
        isA<ProjectVoteBreakdownLoading>(),
        isA<ProjectVoteBreakdownPopulated>()
            .having(
              (ProjectVoteBreakdownPopulated s) => s.voteBreakdown.yes,
              'yes',
              5,
            )
            .having(
              (ProjectVoteBreakdownPopulated s) => s.pillarVotes,
              'pillarVotes',
              isNull,
            ),
      ],
      verify: (_) {
        verifyNever(() => acceleratorApi.getPillarVotes(any(), any()));
      },
    );

    blocTest<ProjectVoteBreakdownBloc, ProjectVoteBreakdownState>(
      'fetches breakdown and pillar votes when pillarName is provided',
      setUp: () {
        when(
          () => acceleratorApi.getVoteBreakdown(projectId),
        ).thenAnswer((_) async => createBreakdown());
        when(
          () => acceleratorApi.getPillarVotes('alpha', <String>[
            projectId.toString(),
          ]),
        ).thenAnswer((_) async => <PillarVote?>[createVote()]);
      },
      build: () => ProjectVoteBreakdownBloc(zenon: zenon),
      act: (ProjectVoteBreakdownBloc bloc) => bloc.add(
        ProjectVoteBreakdownRequested(
          projectId: projectId,
          pillarName: 'alpha',
        ),
      ),
      expect: () => <Matcher>[
        isA<ProjectVoteBreakdownLoading>(),
        isA<ProjectVoteBreakdownPopulated>().having(
          (ProjectVoteBreakdownPopulated s) => s.pillarVotes?.first?.name,
          'pillarVote name',
          'alpha',
        ),
      ],
    );

    blocTest<ProjectVoteBreakdownBloc, ProjectVoteBreakdownState>(
      'emits failure when RPC throws',
      setUp: () {
        when(
          () => acceleratorApi.getVoteBreakdown(projectId),
        ).thenThrow(Exception('rpc down'));
      },
      build: () => ProjectVoteBreakdownBloc(zenon: zenon),
      act: (ProjectVoteBreakdownBloc bloc) =>
          bloc.add(ProjectVoteBreakdownRequested(projectId: projectId)),
      expect: () => <Matcher>[
        isA<ProjectVoteBreakdownLoading>(),
        isA<ProjectVoteBreakdownFailure>().having(
          (ProjectVoteBreakdownFailure s) => s.exception,
          'exception',
          isA<FailureException>(),
        ),
      ],
    );
  });
}
