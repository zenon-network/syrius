import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/accelerator_project_details/accelerator_project_details.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/exceptions/exceptions.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class _MockZenon extends Mock implements Zenon {}

class _MockEmbeddedApi extends Mock implements EmbeddedApi {}

class _MockAcceleratorApi extends Mock implements AcceleratorApi {}

void main() {
  final Hash projectId = Hash.digest(List<int>.filled(32, 4));
  final Address owner = Address.fromPublicKey(List<int>.filled(32, 8));

  Project createProject() => Project(
    id: projectId,
    name: 'Demo',
    owner: owner,
    description: 'Project description',
    url: 'https://zenon.network',
    znnFundsNeeded: BigInt.from(100),
    qsrFundsNeeded: BigInt.from(1000),
    creationTimestamp: 100,
    lastUpdateTimestamp: 100,
    status: AcceleratorProjectStatus.active.index,
    phaseIds: <Hash>[],
    voteBreakdown: VoteBreakdown.fromJson(<String, dynamic>{
      'id': projectId.toString(),
      'yes': 1,
      'no': 0,
      'total': 1,
    }),
    phases: <Phase>[],
  );

  group('RefreshProjectBloc', () {
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

    test('initial state is RefreshProjectInitial', () async {
      final RefreshProjectBloc bloc = RefreshProjectBloc(zenon: zenon);
      expect(bloc.state, const RefreshProjectInitial());
      await bloc.close();
    });

    blocTest<RefreshProjectBloc, RefreshProjectState>(
      'emits [loading, populated] on success',
      setUp: () {
        when(
          () => acceleratorApi.getProjectById(projectId.toString()),
        ).thenAnswer((_) async => createProject());
      },
      build: () => RefreshProjectBloc(zenon: zenon),
      act: (RefreshProjectBloc bloc) =>
          bloc.add(RefreshProjectRequested(projectId: projectId)),
      expect: () => <Matcher>[
        isA<RefreshProjectLoading>(),
        isA<RefreshProjectPopulated>().having(
          (RefreshProjectPopulated s) => s.project.name,
          'project name',
          'Demo',
        ),
      ],
    );

    blocTest<RefreshProjectBloc, RefreshProjectState>(
      'emits [loading, failure] on error',
      setUp: () {
        when(
          () => acceleratorApi.getProjectById(projectId.toString()),
        ).thenThrow(Exception('not found'));
      },
      build: () => RefreshProjectBloc(zenon: zenon),
      act: (RefreshProjectBloc bloc) =>
          bloc.add(RefreshProjectRequested(projectId: projectId)),
      expect: () => <Matcher>[
        isA<RefreshProjectLoading>(),
        isA<RefreshProjectFailure>().having(
          (RefreshProjectFailure s) => s.exception,
          'exception',
          isA<FailureException>(),
        ),
      ],
    );
  });
}
