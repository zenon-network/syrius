import 'package:flutter_test/flutter_test.dart';
import 'package:zenon_syrius_wallet_flutter/utils/accelerator_utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

Address _address(int seed) => Address.fromPublicKey(List<int>.filled(32, seed));

Map<String, dynamic> _pillarJson(
        String name, Address owner, Address producer) =>
    {
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
      'currentStats': {'producedMomentums': 0, 'expectedMomentums': 0},
      'weight': '0',
    };

void main() {
  final owner = _address(1);
  final producer = _address(2);
  final stranger = _address(3);

  PillarInfo pillar() => PillarInfo.fromJson(_pillarJson(
        'test-pillar',
        owner,
        producer,
      ));

  group('AcceleratorUtils.pillarForAddress', () {
    test('matches a pillar by owner address', () {
      expect(
        AcceleratorUtils.pillarForAddress([pillar()], owner)?.name,
        'test-pillar',
      );
    });

    test('matches a pillar by producer address', () {
      expect(
        AcceleratorUtils.pillarForAddress([pillar()], producer)?.name,
        'test-pillar',
      );
    });

    test('returns null when the address has no pillar role', () {
      expect(AcceleratorUtils.pillarForAddress([pillar()], stranger), isNull);
    });

    test('prefers an owner match over a producer match', () {
      final pillarB =
          PillarInfo.fromJson(_pillarJson('pillar-b', stranger, owner));
      expect(
        AcceleratorUtils.pillarForAddress([pillar(), pillarB], owner)?.name,
        'test-pillar',
      );
    });
  });

  group('AcceleratorUtils.voteMethodFor', () {
    test('owner address votes by name', () {
      expect(
        AcceleratorUtils.voteMethodFor(pillar(), owner),
        AcceleratorVoteMethod.byName,
      );
    });

    test('producer address votes by producer address', () {
      expect(
        AcceleratorUtils.voteMethodFor(pillar(), producer),
        AcceleratorVoteMethod.byProdAddress,
      );
    });
  });
}
