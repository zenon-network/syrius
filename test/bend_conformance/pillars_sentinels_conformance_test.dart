@Tags(<String>['bend'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/pillars/pillars.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

import 'bend_conformance_helper.dart';

const String _kDomain = 'pillars_sentinels';

final BigInt _kBaseUnit = BigInt.from(100000000);

// Distinct valid Zenon addresses for wallet-vs-external producer testing.
final String _kWalletAddr = emptyAddress.toString();
final String _kExternalAddr = plasmaAddress.toString();

void main() {
  group('Bend conformance: $_kDomain', () {
    test('all Bend oracle vectors match Syrius pillars & sentinels logic', () {
      final List<Map<String, dynamic>> vectors = loadBendVectors(_kDomain);
      final List<String?> savedAddresses = List<String?>.of(
        kDefaultAddressList,
      );
      addTearDown(() {
        kDefaultAddressList
          ..clear()
          ..addAll(savedAddresses);
      });

      final Set<String> seenOps = <String>{};

      for (final Map<String, dynamic> vector in vectors) {
        final String caseId = requireCaseId(vector);
        final String op = requireOp(vector);
        final Map<String, dynamic> args = requireArgs(vector);
        final Object? expected = vector['expected'];
        seenOps.add(op);

        switch (op) {
          case 'role_constants':
            final String role = requireString(args, 'role');
            final Map<String, Object> actual = switch (role) {
              'pillar' => <String, Object>{
                'plasma_u32': kPillarPlasmaAmountNeeded,
                'znn_u32': (pillarRegisterZnnAmount ~/ _kBaseUnit).toInt(),
                'qsr_burned': true,
              },
              'sentinel' => <String, Object>{
                'plasma_u32': kSentinelPlasmaAmountNeeded,
                'znn_u32': (sentinelRegisterZnnAmount ~/ _kBaseUnit).toInt(),
                'qsr_cost_u32':
                    (sentinelRegisterQsrAmount ~/ _kBaseUnit).toInt(),
                'qsr_burned': false,
              },
              _ => fail('Unknown role "$role"'),
            };
            expectBendMatch(
              domain: _kDomain,
              caseId: caseId,
              actual: actual,
              expected: expected,
            );
          case 'qsr_deposit_summary':
            final BigInt balance = BigInt.from(requireInt(args, 'balance'));
            final BigInt cost = BigInt.from(requireInt(args, 'cost'));
            final BigInt deposit = BigInt.from(requireInt(args, 'deposit'));
            final PillarQsrDepositSummary summary =
                computePillarQsrDepositSummary(
                  qsrBalance: balance,
                  qsrCost: cost,
                  qsrDeposit: deposit,
                );
            expectBendMatch(
              domain: _kDomain,
              caseId: caseId,
              actual: <String, Object>{
                'remaining': summary.remaining.toInt(),
                'max_deposit': summary.maxDeposit.toInt(),
                'is_covered': summary.isCovered,
                'can_withdraw': summary.canWithdraw,
                'clamped_deposit': summary.clampedDeposit.toInt(),
              },
              expected: expected,
            );
            // Conservation and bounded-fraction sanity checks.
            expect(
              (summary.clampedDeposit + summary.remaining).toInt(),
              equals(cost.toInt()),
            );
            expect(
              summary.depositedFraction >= 0.0 &&
                  summary.remainingFraction >= 0.0 &&
                  summary.depositedFraction + summary.remainingFraction <=
                      1.0 + 1e-12,
              isTrue,
            );
          case 'safe_uptime_pct':
            final int produced = requireInt(args, 'produced');
            final int expectedMomentums = requireInt(args, 'expected');
            final int actual = computeMomentumUptimePercentage(
              produced,
              expectedMomentums,
            );
            expectBendMatch(
              domain: _kDomain,
              caseId: caseId,
              actual: actual,
              expected: expected,
            );
          case 'valid_pillar_producer':
            final bool addrValid = requireBool(args, 'addr_valid');
            final bool inWallet = requireBool(args, 'in_wallet');
            kDefaultAddressList
              ..clear()
              ..add(_kWalletAddr);
            final String candidate = !addrValid
                ? 'invalid-zenon-address'
                : (inWallet ? _kWalletAddr : _kExternalAddr);
            final bool actual =
                InputValidators.validatePillarMomentumAddress(candidate) ==
                null;
            expectBendMatch(
              domain: _kDomain,
              caseId: caseId,
              actual: actual,
              expected: expected,
            );
          case 'reward_pct':
            final int pct = requireInt(args, 'pct');
            final bool valid = isValidPillarRewardPercentage(pct);
            final int ownerPct = computeOwnerRewardPercentage(pct);
            expectBendMatch(
              domain: _kDomain,
              caseId: caseId,
              actual: <String, Object>{
                'valid': valid,
                'owner_pct': ownerPct,
              },
              expected: expected,
            );
          case 'can_delegate':
            final int znnBal = requireInt(args, 'znn_bal');
            final bool actual = canDelegateWithZnnBalance(
              BigInt.from(znnBal) * _kBaseUnit,
            );
            expectBendMatch(
              domain: _kDomain,
              caseId: caseId,
              actual: actual,
              expected: expected,
            );
          case 'can_collect_rewards':
            final String role = requireString(args, 'role');
            final BigInt znn = BigInt.from(requireInt(args, 'znn'));
            final BigInt qsr = BigInt.from(requireInt(args, 'qsr'));
            final UncollectedReward reward = UncollectedReward.fromJson(
              <String, dynamic>{
                'address': emptyAddress.toString(),
                'znnAmount': znn.toString(),
                'qsrAmount': qsr.toString(),
              },
            );
            final bool actual = switch (role) {
              'pillar' => canCollectPillarRewards(reward),
              'sentinel' => canCollectSentinelRewards(reward),
              _ => fail('Unknown role "$role"'),
            };
            expectBendMatch(
              domain: _kDomain,
              caseId: caseId,
              actual: actual,
              expected: expected,
            );
          case 'has_reward_history':
            final String role = requireString(args, 'role');
            final Object? rawEntries = args['entries'];
            if (rawEntries is! List<dynamic>) {
              fail('Expected List for "entries" in $args');
            }
            final List<RewardHistoryEntry> entries = <RewardHistoryEntry>[];
            for (int i = 0; i < rawEntries.length; i += 1) {
              final Object? raw = rawEntries[i];
              if (raw is! Map<String, dynamic>) {
                fail('Expected Map entry in "entries": $raw');
              }
              entries.add(
                RewardHistoryEntry.fromJson(<String, dynamic>{
                  'epoch': i,
                  'znnAmount': BigInt.from(requireInt(raw, 'znn')).toString(),
                  'qsrAmount': BigInt.from(requireInt(raw, 'qsr')).toString(),
                }),
              );
            }
            final bool actual = switch (role) {
              'pillar' => hasPillarRewardHistory(entries),
              'sentinel' => hasSentinelRewardHistory(entries),
              _ => fail('Unknown role "$role"'),
            };
            expectBendMatch(
              domain: _kDomain,
              caseId: caseId,
              actual: actual,
              expected: expected,
            );
          case 'parallel_spawn_readiness':
            final bool actual =
                hasSufficientSpawnPlasma(
                  currentPlasma: requireInt(args, 'plasma'),
                  requiredPlasma: requireInt(args, 'plasma_req'),
                ) &&
                computePillarQsrDepositSummary(
                  qsrBalance: BigInt.zero,
                  qsrCost: BigInt.from(requireInt(args, 'qsr_cost')),
                  qsrDeposit: BigInt.from(requireInt(args, 'deposit')),
                ).isCovered &&
                hasSufficientSpawnZnn(
                  znnBalance: BigInt.from(requireInt(args, 'znn_bal')),
                  requiredZnn: BigInt.from(requireInt(args, 'znn_req')),
                );
            expectBendMatch(
              domain: _kDomain,
              caseId: caseId,
              actual: actual,
              expected: expected,
            );
          default:
            fail('Unhandled Bend conformance op "$_kDomain/$op"');
        }
      }

      expect(
        seenOps,
        equals(const <String>{
          'role_constants',
          'qsr_deposit_summary',
          'safe_uptime_pct',
          'valid_pillar_producer',
          'reward_pct',
          'can_delegate',
          'can_collect_rewards',
          'has_reward_history',
          'parallel_spawn_readiness',
        }),
      );
    });

    test('Validations.pillarName enforces protocol length and grammar', () {
      expect(Validations.pillarName(''), isNotNull);
      expect(Validations.pillarName('A' * pillarNameMaxLength), isNull);
      expect(
        Validations.pillarName('A' * (pillarNameMaxLength + 1)),
        isNotNull,
      );
    });
  });
}
