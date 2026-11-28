@Tags(<String>['bend'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/pow_generating_status/pow_generating_status.dart';
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

bool _realCanFusePlasma({
  required int qsr,
  required int balance,
  required bool isInteger,
  required bool validBeneficiary,
}) {
  final String amountText = isInteger ? '$qsr' : '$qsr.5';
  final String beneficiary = validBeneficiary
      ? emptyAddress.toString()
      : 'not-a-zenon-address';
  final bool integerFormatOk = RegExp(r'^[0-9]+$').hasMatch(amountText);
  final String? amountError = InputValidators.correctValue(
    amountText,
    BigInt.from(balance) * _kBaseUnit,
    coinDecimals,
    fuseMinQsrAmount,
    canBeEqualToMin: true,
  );
  final String? addressError = InputValidators.checkAddress(beneficiary);
  return integerFormatOk && amountError == null && addressError == null;
}

bool _realValidStakeMonths(int months) {
  final int durationSec = months * stakeTimeUnitSec;
  return durationSec >= stakeTimeMinSec && durationSec <= stakeTimeMaxSec;
}

bool _realCanCreateStake({
  required int amount,
  required int balance,
  required int months,
}) {
  final String? amountError = InputValidators.correctValue(
    '$amount',
    BigInt.from(balance) * _kBaseUnit,
    coinDecimals,
    stakeMinZnnAmount,
    canBeEqualToMin: true,
  );
  return amountError == null && _realValidStakeMonths(months);
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
            expectBendMatch(
              domain: _kDomain,
              caseId: '$caseId/tier_color',
              actual: color,
              expected: expectedColor,
            );
            expectBendMatch(
              domain: _kDomain,
              caseId: '$caseId/tier_tooltip',
              actual: tooltip,
              expected: expectedTooltip,
            );
          case 'can_fuse_plasma':
            final bool actual = _realCanFusePlasma(
              qsr: requireInt(args, 'qsr'),
              balance: requireInt(args, 'balance'),
              isInteger: requireBool(args, 'is_integer'),
              validBeneficiary: requireBool(args, 'valid_beneficiary'),
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
            final bool revocable = lastHeight > expHeight;
            final int seconds = revocable
                ? 0
                : kSecondsPerMomentum * (expHeight - lastHeight);
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
            final bool actual = _realValidStakeMonths(
              requireInt(args, 'months'),
            );
            expectBendMatch(
              domain: _kDomain,
              caseId: caseId,
              actual: actual,
              expected: expected,
            );
          case 'stake_duration_u32':
            final int months = requireInt(args, 'months');
            final int actual = months * stakeTimeUnitSec;
            expectBendMatch(
              domain: _kDomain,
              caseId: caseId,
              actual: actual,
              expected: expected,
            );
          case 'can_create_stake':
            final bool actual = _realCanCreateStake(
              amount: requireInt(args, 'amount'),
              balance: requireInt(args, 'balance'),
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
            final bool actual = reward.qsrAmount > BigInt.zero;
            expectBendMatch(
              domain: _kDomain,
              caseId: caseId,
              actual: actual,
              expected: expected,
            );
          case 'parallel_plasma_staking_check':
            final bool fuseOk = _realCanFusePlasma(
              qsr: requireInt(args, 'qsr'),
              balance: requireInt(args, 'qsr_bal'),
              isInteger: requireBool(args, 'is_int'),
              validBeneficiary: requireBool(args, 'valid_ben'),
            );
            final bool stakeOk = _realCanCreateStake(
              amount: requireInt(args, 'znn'),
              balance: requireInt(args, 'znn_bal'),
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

      expect(seenOps, isNotEmpty);
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

      expectBendMatch(
        domain: _kDomain,
        caseId: 'pow_generating_status_nested_edges',
        actual: observed.map((PowStatus s) => s.name).toList(),
        expected: <String>[PowStatus.generating.name, PowStatus.done.name],
      );
    });
  });
}
