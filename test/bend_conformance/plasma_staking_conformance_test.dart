@Tags(<String>['bend'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/create_stake/create_stake.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/fuse_plasma/fuse_plasma.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/fused_plasma/fused_plasma.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/pow_generating_status/pow_generating_status.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/stake_collect/stake_collect.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

import 'bend_conformance_helper.dart';

const String _kDomain = 'plasma_staking';

final BigInt _kBaseUnit = BigInt.from(100000000);

PlasmaInfo _plasmaInfo(int currentPlasma) => PlasmaInfo.fromJson(
  <String, dynamic>{
    'currentPlasma': currentPlasma,
    'maxPlasma': currentPlasma,
    'qsrAmount': '0',
  },
);

int _realOpPlasmaThreshold(String op) {
  return switch (op) {
    'min_plasma' => minPlasmaAmount.toInt(),
    'delegate' => kDelegatePlasmaAmountNeeded,
    'stake' => kStakePlasmaAmountNeeded,
    'issue_token' => kIssueTokenPlasmaAmountNeeded,
    'pillar' => kPillarPlasmaAmountNeeded,
    'sentinel' => kSentinelPlasmaAmountNeeded,
    _ => fail('Unknown PlasmaOp "$op"'),
  };
}

void main() {
  group('Bend conformance: $_kDomain', () {
    test('all Bend oracle vectors match Syrius plasma & staking logic', () {
      final List<Map<String, dynamic>> vectors = loadBendVectors(_kDomain);
      final PlasmaApi plasmaApi = Zenon().embedded.plasma;
      final Set<String> seenOps = <String>{};

      for (final Map<String, dynamic> vector in vectors) {
        final String caseId = requireCaseId(vector);
        final String op = requireOp(vector);
        final Map<String, dynamic> args = requireArgs(vector);
        final Object? expected = vector['expected'];
        seenOps.add(op);

        switch (op) {
          case 'plasma_for_qsr_u32':
            final int qsr = requireInt(args, 'qsr');
            final BigInt plasmaScaled = plasmaApi.getPlasmaByQsr(
              BigInt.from(qsr) * _kBaseUnit,
            );
            final int actual = (plasmaScaled ~/ _kBaseUnit).toInt();
            expectBendMatch(
              domain: _kDomain,
              caseId: caseId,
              actual: actual,
              expected: expected,
            );
          case 'op_plasma_u32':
            final String opName = requireString(args, 'op');
            final int actual = _realOpPlasmaThreshold(opName);
            expectBendMatch(
              domain: _kDomain,
              caseId: caseId,
              actual: actual,
              expected: expected,
            );
            // Cross-check plasma tier / ColorUtils / WidgetUtils bijection.
            final PlasmaTier tier = classifyPlasmaTier(actual);
            final PlasmaInfo info = _plasmaInfo(actual);
            final Color color = ColorUtils.getPlasmaColor(info);
            final String tooltip = WidgetUtils.getPlasmaToolTipMessage(info);
            final (Color expectedColor, String expectedTooltip) =
                switch (tier) {
                  PlasmaTier.insufficient => (
                    AppColors.ztsColor,
                    'Insufficient Plasma',
                  ),
                  PlasmaTier.low => (Colors.orange, 'Low Plasma'),
                  PlasmaTier.average => (Colors.yellow, 'Average Plasma'),
                  PlasmaTier.high => (AppColors.znnColor, 'High Plasma'),
                };
            expect(color, equals(expectedColor));
            expect(tooltip, equals(expectedTooltip));
          case 'can_fuse_plasma':
            final int qsr = requireInt(args, 'qsr');
            final bool isInteger = requireBool(args, 'is_integer');
            final bool validBeneficiary = requireBool(
              args,
              'valid_beneficiary',
            );
            final bool actual = canFusePlasma(
              amountText: isInteger ? '$qsr' : '$qsr.5',
              maxQsrBalance:
                  BigInt.from(requireInt(args, 'balance')) * _kBaseUnit,
              beneficiaryAddress: validBeneficiary
                  ? emptyAddress.toString()
                  : 'not-a-zenon-address',
            );
            expectBendMatch(
              domain: _kDomain,
              caseId: caseId,
              actual: actual,
              expected: expected,
            );
          case 'fusion_status':
            final int lastHeight = requireInt(args, 'last_height');
            final int expHeight = requireInt(args, 'exp_height');
            final bool revocable = isFusionRevocable(
              lastMomentumHeight: lastHeight,
              expirationHeight: expHeight,
            );
            final int seconds = computeFusionCountdownSeconds(
              lastMomentumHeight: lastHeight,
              expirationHeight: expHeight,
            );
            expectBendMatch(
              domain: _kDomain,
              caseId: caseId,
              actual: <String, Object>{
                'revocable': revocable,
                'seconds': seconds,
              },
              expected: expected,
            );
          case 'valid_stake_months':
            final bool actual = isValidStakeMonths(requireInt(args, 'months'));
            expectBendMatch(
              domain: _kDomain,
              caseId: caseId,
              actual: actual,
              expected: expected,
            );
          case 'stake_duration_u32':
            final int actual = stakeDurationForMonths(
              requireInt(args, 'months'),
            );
            expectBendMatch(
              domain: _kDomain,
              caseId: caseId,
              actual: actual,
              expected: expected,
            );
          case 'can_create_stake':
            final bool actual = canCreateStake(
              amountText: '${requireInt(args, 'amount')}',
              maxZnnBalance:
                  BigInt.from(requireInt(args, 'balance')) * _kBaseUnit,
              months: requireInt(args, 'months'),
            );
            expectBendMatch(
              domain: _kDomain,
              caseId: caseId,
              actual: actual,
              expected: expected,
            );
          case 'can_collect_stake_rewards':
            final BigInt qsr = BigInt.from(requireInt(args, 'qsr'));
            final BigInt znn = BigInt.from(requireInt(args, 'znn'));
            final UncollectedReward reward = UncollectedReward.fromJson(
              <String, dynamic>{
                'address': emptyAddress.toString(),
                'znnAmount': znn.toString(),
                'qsrAmount': qsr.toString(),
              },
            );
            expectBendMatch(
              domain: _kDomain,
              caseId: caseId,
              actual: canCollectStakeRewards(reward),
              expected: expected,
            );
          case 'parallel_plasma_staking_check':
            final int qsr = requireInt(args, 'qsr');
            final bool isInt = requireBool(args, 'is_int');
            final bool validBen = requireBool(args, 'valid_ben');
            final bool fuseOk = canFusePlasma(
              amountText: isInt ? '$qsr' : '$qsr.5',
              maxQsrBalance:
                  BigInt.from(requireInt(args, 'qsr_bal')) * _kBaseUnit,
              beneficiaryAddress: validBen
                  ? emptyAddress.toString()
                  : 'not-a-zenon-address',
            );
            final bool stakeOk = canCreateStake(
              amountText: '${requireInt(args, 'znn')}',
              maxZnnBalance:
                  BigInt.from(requireInt(args, 'znn_bal')) * _kBaseUnit,
              months: requireInt(args, 'months'),
            );
            expectBendMatch(
              domain: _kDomain,
              caseId: caseId,
              actual: fuseOk && stakeOk,
              expected: expected,
            );
          default:
            fail('Unhandled Bend conformance op "$_kDomain/$op"');
        }
      }

      expect(
        seenOps,
        equals(const <String>{
          'plasma_for_qsr_u32',
          'op_plasma_u32',
          'can_fuse_plasma',
          'fusion_status',
          'valid_stake_months',
          'stake_duration_u32',
          'can_create_stake',
          'can_collect_stake_rewards',
          'parallel_plasma_staking_check',
        }),
      );
    });

    test(
      'PowGeneratingStatusBloc enforces nested ref-count and 0-clamp',
      () async {
        final PowGeneratingStatusBloc bloc = PowGeneratingStatusBloc();
        addTearDown(bloc.close);

        final List<PowStatus> observed = <PowStatus>[];
        bloc.stream.listen(
          (PowGeneratingStatusState state) => observed.add(state.status),
        );

        // Clamping at 0: done before generating emits nothing.
        bloc
          ..add(const PowGeneratingStatusChanged(PowStatus.done))
          ..add(const PowGeneratingStatusChanged(PowStatus.generating))
          ..add(const PowGeneratingStatusChanged(PowStatus.generating))
          ..add(const PowGeneratingStatusChanged(PowStatus.done))
          ..add(const PowGeneratingStatusChanged(PowStatus.done))
          ..add(const PowGeneratingStatusChanged(PowStatus.done));

        await Future<void>.delayed(Duration.zero);

        expect(
          observed.map((PowStatus s) => s.name).toList(),
          equals(<String>[PowStatus.generating.name, PowStatus.done.name]),
        );
      },
    );
  });
}
