import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/accelerator_pillar/accelerator_pillar.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/exceptions/exceptions.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class _MockZenon extends Mock implements Zenon {}

class _MockEmbeddedApi extends Mock implements EmbeddedApi {}

class _MockPillarApi extends Mock implements PillarApi {}

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

void main() {
  group('AcceleratorPillarBloc', () {
    late _MockZenon zenon;
    late _MockEmbeddedApi embedded;
    late _MockPillarApi pillarApi;
    late int? previousNumOfPillars;

    final Address owner = _address(1);
    final Address producer = _address(2);
    final Address stranger = _address(3);

    setUp(() {
      previousNumOfPillars = kNumOfPillars;
      kNumOfPillars = 42;
      zenon = _MockZenon();
      embedded = _MockEmbeddedApi();
      pillarApi = _MockPillarApi();
      when(() => zenon.embedded).thenReturn(embedded);
      when(() => embedded.pillar).thenReturn(pillarApi);
    });

    tearDown(() {
      kNumOfPillars = previousNumOfPillars;
    });

    test('initial state is AcceleratorPillarInitial', () async {
      final AcceleratorPillarBloc bloc = AcceleratorPillarBloc(zenon: zenon);
      expect(bloc.state, const AcceleratorPillarInitial());
      await bloc.close();
    });

    blocTest<AcceleratorPillarBloc, AcceleratorPillarState>(
      'emits [loading, populated] for pillar owner address',
      setUp: () {
        when(() => pillarApi.getByOwner(owner)).thenAnswer(
          (_) async => <PillarInfo>[_pillar('alpha', owner, producer)],
        );
      },
      build: () => AcceleratorPillarBloc(zenon: zenon),
      act: (AcceleratorPillarBloc bloc) =>
          bloc.add(AcceleratorPillarRequested(address: owner)),
      expect: () => <AcceleratorPillarState>[
        AcceleratorPillarLoading(address: owner),
        AcceleratorPillarPopulated(
          address: owner,
          pillarInfo: _pillar('alpha', owner, producer),
          activePillarCount: 42,
        ),
      ],
    );

    blocTest<AcceleratorPillarBloc, AcceleratorPillarState>(
      'emits [loading, populated] for pillar producer address',
      setUp: () {
        final PillarInfo pillar = _pillar('alpha', owner, producer);
        when(
          () => pillarApi.getByOwner(producer),
        ).thenAnswer((_) async => <PillarInfo>[]);
        when(() => pillarApi.getAll(pageSize: 10)).thenAnswer(
          (_) async => PillarInfoList.fromJson(<String, dynamic>{
            'count': 1,
            'list': <Map<String, dynamic>>[pillar.toJson()],
          }),
        );
      },
      build: () => AcceleratorPillarBloc(zenon: zenon, pageSize: 10),
      act: (AcceleratorPillarBloc bloc) =>
          bloc.add(AcceleratorPillarRequested(address: producer)),
      expect: () => <AcceleratorPillarState>[
        AcceleratorPillarLoading(address: producer),
        AcceleratorPillarPopulated(
          address: producer,
          pillarInfo: _pillar('alpha', owner, producer),
          activePillarCount: 1,
        ),
      ],
    );

    blocTest<AcceleratorPillarBloc, AcceleratorPillarState>(
      'emits [loading, populated(pillarInfo: null)] for address with no '
      'pillar role',
      setUp: () {
        final PillarInfo pillar = _pillar('alpha', owner, producer);
        when(
          () => pillarApi.getByOwner(stranger),
        ).thenAnswer((_) async => <PillarInfo>[]);
        when(() => pillarApi.getAll(pageSize: 10)).thenAnswer(
          (_) async => PillarInfoList.fromJson(<String, dynamic>{
            'count': 1,
            'list': <Map<String, dynamic>>[pillar.toJson()],
          }),
        );
      },
      build: () => AcceleratorPillarBloc(zenon: zenon, pageSize: 10),
      act: (AcceleratorPillarBloc bloc) =>
          bloc.add(AcceleratorPillarRequested(address: stranger)),
      expect: () => <AcceleratorPillarState>[
        AcceleratorPillarLoading(address: stranger),
        AcceleratorPillarPopulated(
          address: stranger,
          pillarInfo: null,
          activePillarCount: 1,
        ),
      ],
    );

    blocTest<AcceleratorPillarBloc, AcceleratorPillarState>(
      'emits [loading, failure] when RPC throws',
      setUp: () {
        when(
          () => pillarApi.getByOwner(owner),
        ).thenThrow(Exception('node offline'));
      },
      build: () => AcceleratorPillarBloc(zenon: zenon),
      act: (AcceleratorPillarBloc bloc) =>
          bloc.add(AcceleratorPillarRequested(address: owner)),
      expect: () => <Matcher>[
        isA<AcceleratorPillarLoading>(),
        isA<AcceleratorPillarFailure>().having(
          (AcceleratorPillarFailure s) => s.exception,
          'exception',
          isA<FailureException>(),
        ),
      ],
    );
  });
}
