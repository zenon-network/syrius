import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/accelerator_pillar/accelerator_pillar.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class _MockZenon extends Mock implements Zenon {}

class _MockEmbeddedApi extends Mock implements EmbeddedApi {}

class _MockPillarApi extends Mock implements PillarApi {}

Address _address(int seed) => Address.fromPublicKey(List<int>.filled(32, seed));

Map<String, dynamic> _pillarJson(
  String name,
  Address owner,
  Address producer,
) => <String, dynamic>{
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
  'currentStats': <String, dynamic>{
    'producedMomentums': 0,
    'expectedMomentums': 0,
  },
  'weight': '0',
};

void main() {
  final Address owner = _address(1);
  final Address producer = _address(2);
  final Address stranger = _address(3);

  PillarInfo createPillar({
    String name = 'test-pillar',
    Address? ownerAddr,
    Address? producerAddr,
  }) => PillarInfo.fromJson(
    _pillarJson(name, ownerAddr ?? owner, producerAddr ?? producer),
  );

  group('pillarForAddress', () {
    test('matches a pillar by owner address', () {
      expect(
        pillarForAddress(<PillarInfo>[createPillar()], owner)?.name,
        'test-pillar',
      );
    });

    test('matches a pillar by producer address', () {
      expect(
        pillarForAddress(<PillarInfo>[createPillar()], producer)?.name,
        'test-pillar',
      );
    });

    test('returns null when the address has no pillar role', () {
      expect(pillarForAddress(<PillarInfo>[createPillar()], stranger), isNull);
    });

    test('prefers an owner match over a producer match', () {
      final PillarInfo pillarB = createPillar(
        name: 'pillar-b',
        ownerAddr: stranger,
        producerAddr: owner,
      );
      expect(
        pillarForAddress(<PillarInfo>[pillarB, createPillar()], owner)?.name,
        'test-pillar',
      );
    });
  });

  group('voteMethodFor', () {
    test('owner address votes by name', () {
      expect(
        voteMethodFor(createPillar(), owner),
        AcceleratorVoteMethod.byName,
      );
    });

    test('producer address votes by producer address', () {
      expect(
        voteMethodFor(createPillar(), producer),
        AcceleratorVoteMethod.byProdAddress,
      );
    });
  });

  group('resolvePillarForAddress', () {
    late _MockZenon zenon;
    late _MockEmbeddedApi embedded;
    late _MockPillarApi pillarApi;

    setUp(() {
      zenon = _MockZenon();
      embedded = _MockEmbeddedApi();
      pillarApi = _MockPillarApi();
      when(() => zenon.embedded).thenReturn(embedded);
      when(() => embedded.pillar).thenReturn(pillarApi);
    });

    test(
      'returns owner match from getByOwner without scanning getAll',
      () async {
        final PillarInfo owned = createPillar();
        when(
          () => pillarApi.getByOwner(owner),
        ).thenAnswer((_) async => <PillarInfo>[owned]);

        final ResolvedPillarResult result = await resolvePillarForAddress(
          zenon: zenon,
          address: owner,
        );

        expect(result.pillarInfo?.name, 'test-pillar');
        verify(() => pillarApi.getByOwner(owner)).called(1);
        verifyNever(
          () => pillarApi.getAll(
            pageIndex: any(named: 'pageIndex'),
            pageSize: any(named: 'pageSize'),
          ),
        );
      },
    );

    test('falls back to paged pillar.getAll when getByOwner returns empty and '
        'finds producer on later page', () async {
      final PillarInfo otherPillar = createPillar(
        name: 'other-pillar',
        ownerAddr: _address(10),
        producerAddr: _address(11),
      );
      final PillarInfo producerPillar = createPillar(name: 'prod-pillar');
      when(
        () => pillarApi.getByOwner(producer),
      ).thenAnswer((_) async => <PillarInfo>[]);
      when(() => pillarApi.getAll(pageSize: 1)).thenAnswer(
        (_) async => PillarInfoList.fromJson(<String, dynamic>{
          'count': 2,
          'list': <Map<String, dynamic>>[otherPillar.toJson()],
        }),
      );
      when(() => pillarApi.getAll(pageIndex: 1, pageSize: 1)).thenAnswer(
        (_) async => PillarInfoList.fromJson(<String, dynamic>{
          'count': 2,
          'list': <Map<String, dynamic>>[producerPillar.toJson()],
        }),
      );
      when(() => pillarApi.getAll(pageIndex: 2, pageSize: 1)).thenAnswer(
        (_) async => PillarInfoList.fromJson(<String, dynamic>{
          'count': 2,
          'list': <Map<String, dynamic>>[],
        }),
      );

      final ResolvedPillarResult result = await resolvePillarForAddress(
        zenon: zenon,
        address: producer,
        pageSize: 1,
      );

      expect(result.pillarInfo?.name, 'prod-pillar');
      expect(result.activePillarCount, 2);
    });

    test('returns null pillarInfo when address has no role', () async {
      final PillarInfo pillar = createPillar();
      when(
        () => pillarApi.getByOwner(stranger),
      ).thenAnswer((_) async => <PillarInfo>[]);
      when(() => pillarApi.getAll(pageSize: 10)).thenAnswer(
        (_) async => PillarInfoList.fromJson(<String, dynamic>{
          'count': 1,
          'list': <Map<String, dynamic>>[pillar.toJson()],
        }),
      );

      final ResolvedPillarResult result = await resolvePillarForAddress(
        zenon: zenon,
        address: stranger,
        pageSize: 10,
      );

      expect(result.pillarInfo, isNull);
      expect(result.activePillarCount, 1);
    });
  });
}
