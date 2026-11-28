@Tags(<String>['bend'])
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenon_syrius_wallet_flutter/l10n/app_localizations_en.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/settings_addresses/settings_addresses.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/math_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

import 'bend_conformance_helper.dart';

const String _kDomain = 'amounts';

const String _kAddr0 = 'z1qqjnwjjpnue8xmmpanz6csze6tcmtzzdtfsww7';
const String _kAddr1 = 'z1qzal6c5s9rjnnxd2z7dvdhjxpmmj4fmw56a0mz';

class _TestProtocolHandler extends ProtocolHandler {
  @override
  void register(String scheme, {String? executable, List<String>? arguments}) {}

  @override
  void unregister(String scheme) {}
}

class _InMemorySettingsAddressesRepository
    implements SettingsAddressesRepository {
  _InMemorySettingsAddressesRepository({
    required Map<String, String> labels,
  }) : _labels = Map<String, String>.of(labels);

  final Map<String, String> _labels;

  @override
  List<String> getAddresses() => const <String>[_kAddr0, _kAddr1];

  @override
  String? getSelectedAddress() => _kAddr0;

  @override
  Map<String, String> getAddressLabels() => Map<String, String>.of(_labels);

  @override
  Future<void> saveDefaultAddress(String address) async {}

  @override
  Future<void> generateNewAddresses(int count) async {}

  @override
  Future<void> updateAddressLabel({
    required String address,
    required String label,
  }) async {
    _labels[address] = label;
  }
}

Token _buildAssetToken(String kind, int id) {
  return switch (kind) {
    'znn' => kZnnCoin,
    'qsr' => kQsrCoin,
    'zts' => Token(
      'Token$id',
      'T$id',
      'token$id.example',
      BigInt.from(100),
      8,
      emptyAddress,
      TokenStandard.fromBytes(<int>[
        1,
        2,
        3,
        4,
        5,
        6,
        7,
        8,
        (id >> 8) & 0xFF,
        id & 0xFF,
      ]),
      BigInt.from(1000),
      true,
      true,
      true,
    ),
    _ => fail('Unknown AssetKind "$kind"'),
  };
}

PlasmaInfo _plasmaInfo(int currentPlasma) {
  return PlasmaInfo.fromJson(<String, dynamic>{
    'currentPlasma': currentPlasma,
    'maxPlasma': currentPlasma,
    'qsrAmount': '0',
  });
}

String _colorKey(Color color) {
  if (color == AppColors.ztsColor) {
    return 'zts';
  }
  if (color == Colors.orange) {
    return 'orange';
  }
  if (color == Colors.yellow) {
    return 'yellow';
  }
  if (color == AppColors.znnColor) {
    return 'znn';
  }
  fail('Unexpected plasma Color: $color');
}

String _tierKey(PlasmaTier tier) {
  return switch (tier) {
    PlasmaTier.insufficient => 'insufficient',
    PlasmaTier.low => 'low',
    PlasmaTier.average => 'average',
    PlasmaTier.high => 'high',
  };
}

String _passwordTierKey(PasswordStrengthTier tier) {
  return switch (tier) {
    PasswordStrengthTier.empty => 'empty',
    PasswordStrengthTier.weak => 'weak',
    PasswordStrengthTier.medium => 'medium',
    PasswordStrengthTier.strong => 'strong',
  };
}

String _formatExtractInput({
  required int whole,
  required int frac,
  required int fracLen,
}) {
  if (fracLen == 0) {
    return '$whole';
  }
  return '$whole.${frac.toString().padLeft(fracLen, '0')}';
}

BigInt _pow10BigInt(int d) {
  BigInt acc = BigInt.one;
  final BigInt ten = BigInt.from(10);
  for (int i = 0; i < d; i += 1) {
    acc *= ten;
  }
  return acc;
}

String _buildCorrectValueInput({
  required BigInt val,
  required int dec,
  required bool isBlank,
  required bool parseOk,
  required int fracDigits,
}) {
  if (isBlank) {
    return '';
  }
  if (!parseOk) {
    return fracDigits > 0 ? '1.2.3' : 'not-a-number';
  }
  if (dec == 0) {
    if (fracDigits == 0) {
      return val.toString();
    }
    return '$val.${'0' * fracDigits}';
  }
  final BigInt scale = _pow10BigInt(dec);
  final BigInt whole = val ~/ scale;
  final BigInt rem = val % scale;
  final String baseFrac = rem.toString().padLeft(dec, '0');
  if (fracDigits > dec) {
    return '$whole.$baseFrac${'0' * (fracDigits - dec)}';
  }
  if (fracDigits == 0 && rem == BigInt.zero) {
    return whole.toString();
  }
  if (fracDigits > 0 &&
      baseFrac.substring(fracDigits) == '0' * (dec - fracDigits)) {
    return '$whole.${baseFrac.substring(0, fracDigits)}';
  }
  return '$whole.$baseFrac';
}

String _classifyCorrectValueError({
  required String? error,
  required bool isBlank,
  required AppLocalizationsEn l10n,
  required BigInt minVal,
  required BigInt maxVal,
  required int dec,
}) {
  if (error == null) {
    return 'ok';
  }
  if (error == l10n.emptyBalance) {
    return 'empty_balance';
  }
  if (error == l10n.enterValidAmount) {
    return isBlank ? 'blank' : 'parse';
  }
  if (error == l10n.error) {
    return 'parse';
  }
  if (error == l10n.inputtedNumberHasTooManyDecimals) {
    return 'too_many_decimals';
  }
  if (error == l10n.availableBalanceMustBeAtLeast(minVal.addDecimals(dec))) {
    return 'max_below_min';
  }
  if (error == l10n.valueMustBe(minVal.addDecimals(dec)) ||
      error ==
          l10n.valueMustBeBetween(
            minVal.addDecimals(dec),
            maxVal.addDecimals(dec),
          )) {
    return 'out_of_range';
  }
  fail('Unclassified InputValidators.correctValue error: "$error"');
}

String _synthesizePassword({
  required int len,
  required bool hasUpper,
  required bool hasLower,
  required bool hasDigit,
  required bool hasSpecial,
}) {
  if (len == 0) {
    return '';
  }
  if (len < 8) {
    return 'a' * len;
  }
  final List<String> chars = <String>[
    if (hasUpper) 'A',
    if (hasLower) 'a',
    if (hasDigit) '1',
    if (hasSpecial) '!',
  ];
  final String filler = hasLower
      ? 'b'
      : hasUpper
      ? 'B'
      : hasDigit
      ? '2'
      : hasSpecial
      ? '@'
      : ' ';
  while (chars.length < len) {
    chars.add(filler);
  }
  return chars.join();
}

String _codesToPassword(List<int> codes) {
  return String.fromCharCodes(
    codes.map((int code) => 33 + (code % 90)),
  );
}

void main() {
  final AppLocalizationsEn l10n = AppLocalizationsEn();
  final _TestProtocolHandler protocolHandler = _TestProtocolHandler();

  group('Bend conformance: $_kDomain', () {
    test(
      'all Bend oracle vectors match Syrius amount, validator, and UI-edge '
      'implementations',
      () async {
        final List<Map<String, dynamic>> vectors = loadBendVectors(_kDomain);
        final Set<String> seenOps = <String>{};

        for (final Map<String, dynamic> vector in vectors) {
          final String caseId = requireCaseId(vector);
          final String op = requireOp(vector);
          final Map<String, dynamic> args = requireArgs(vector);
          final Object? expected = vector['expected'];
          seenOps.add(op);

          switch (op) {
            case 'big_min_max':
              final BigInt a = requireBigInt(args, 'a');
              final BigInt b = requireBigInt(args, 'b');
              expectBendMatch(
                domain: _kDomain,
                caseId: caseId,
                actual: <String, Object>{
                  'min': MathUtils.bigMin(a, b).toInt(),
                  'max': MathUtils.bigMax(a, b).toInt(),
                },
                expected: expected,
              );

            case 'extract_decimals':
              final String raw = _formatExtractInput(
                whole: requireInt(args, 'whole'),
                frac: requireInt(args, 'frac'),
                fracLen: requireInt(args, 'frac_len'),
              );
              final int decimals = requireInt(args, 'decimals');
              expectBendMatch(
                domain: _kDomain,
                caseId: caseId,
                actual: raw.extractDecimals(decimals).toInt(),
                expected: expected,
              );

            case 'roundtrip_decimals':
              final BigInt baseUnits = requireBigInt(args, 'base_units');
              final int decimals = requireInt(args, 'decimals');
              final String formatted = baseUnits.addDecimals(decimals);
              final int roundtripped = formatted
                  .extractDecimals(decimals)
                  .toInt();
              expectBendMatch(
                domain: _kDomain,
                caseId: caseId,
                actual: roundtripped,
                expected: expected,
              );

            case 'correct_value':
              final BigInt val = requireBigInt(args, 'val');
              final BigInt maxVal = requireBigInt(args, 'max_val');
              final int dec = requireInt(args, 'dec');
              final BigInt minVal = requireBigInt(args, 'min_val');
              final bool canEqMin = requireBool(args, 'can_eq_min');
              final bool canBeBlank = requireBool(args, 'can_be_blank');
              final bool isBlank = requireBool(args, 'is_blank');
              final bool parseOk = requireBool(args, 'parse_ok');
              final int fracDigits = requireInt(args, 'frac_digits');
              final String input = _buildCorrectValueInput(
                val: val,
                dec: dec,
                isBlank: isBlank,
                parseOk: parseOk,
                fracDigits: fracDigits,
              );
              final String? err = InputValidators.correctValue(
                input,
                maxVal,
                dec,
                minVal,
                canBeEqualToMin: canEqMin,
                canBeBlank: canBeBlank,
                l10n: l10n,
              );
              final String errorKind = _classifyCorrectValueError(
                error: err,
                isBlank: isBlank,
                l10n: l10n,
                minVal: minVal,
                maxVal: maxVal,
                dec: dec,
              );
              expectBendMatch(
                domain: _kDomain,
                caseId: caseId,
                actual: <String, Object>{
                  'ok': err == null,
                  'error': errorKind,
                },
                expected: expected,
              );

            case 'asset_cmp':
              final Token a = _buildAssetToken(
                requireString(args, 'a'),
                requireInt(args, 'a_id'),
              );
              final Token b = _buildAssetToken(
                requireString(args, 'b'),
                requireInt(args, 'b_id'),
              );
              expectBendMatch(
                domain: _kDomain,
                caseId: caseId,
                actual: compareAssets(a, b),
                expected: expected,
              );

            case 'plasma_tier':
              final int plasma = requireInt(args, 'plasma');
              final PlasmaInfo info = _plasmaInfo(plasma);
              final PlasmaTier tier = classifyPlasmaTier(plasma);
              final Color color = ColorUtils.getPlasmaColor(info);
              final String tooltip = WidgetUtils.getPlasmaToolTipMessage(info);
              expectBendMatch(
                domain: _kDomain,
                caseId: caseId,
                actual: <String, Object>{
                  'tier': _tierKey(tier),
                  'color': _colorKey(color),
                  'tooltip': tooltip,
                },
                expected: expected,
              );

            case 'password_strength':
              final String password = _synthesizePassword(
                len: requireInt(args, 'len'),
                hasUpper: requireBool(args, 'has_upper'),
                hasLower: requireBool(args, 'has_lower'),
                hasDigit: requireBool(args, 'has_digit'),
                hasSpecial: requireBool(args, 'has_special'),
              );
              final bool isValid =
                  InputValidators.validatePassword(password, l10n: l10n) ==
                  null;
              final PasswordStrengthTier tier = classifyPasswordStrength(
                password,
                isValid: isValid,
              );
              expectBendMatch(
                domain: _kDomain,
                caseId: caseId,
                actual: <String, Object>{
                  'valid': isValid,
                  'tier': _passwordTierKey(tier),
                },
                expected: expected,
              );

            case 'password_match':
              final String a = _codesToPassword(requireIntList(args, 'a'));
              final String b = _codesToPassword(requireIntList(args, 'b'));
              final bool matched =
                  InputValidators.checkPasswordMatch(a, b, l10n: l10n) == null;
              expectBendMatch(
                domain: _kDomain,
                caseId: caseId,
                actual: matched,
                expected: expected,
              );

            case 'resolve_max_amount':
              final BigInt cur = requireBigInt(args, 'cur');
              final BigInt maxBal = requireBigInt(args, 'max_bal');
              final int decimals = requireInt(args, 'decimals');
              final String? resolvedText = resolveMaxAmountText(
                maxBalance: maxBal,
                decimals: decimals,
                currentAmount: cur,
              );
              final BigInt effective = resolvedText == null
                  ? cur
                  : resolvedText.extractDecimals(decimals);
              expectBendMatch(
                domain: _kDomain,
                caseId: caseId,
                actual: effective.toInt(),
                expected: expected,
              );

            case 'validate_address_label':
              final int len = requireInt(args, 'len');
              final bool isDup = requireBool(args, 'is_dup');
              final String candidate = 'a' * len;
              final Map<String, String> existingLabels = <String, String>{
                if (isDup && len > 0) _kAddr1: candidate,
              };
              final _InMemorySettingsAddressesRepository repo =
                  _InMemorySettingsAddressesRepository(labels: existingLabels);
              final SettingsAddressesBloc bloc = SettingsAddressesBloc(
                repository: repo,
              )
                ..add(
                  SettingsAddressesLabelUpdated(
                    address: _kAddr0,
                    label: candidate,
                  ),
                );
              await bloc.stream.firstWhere(
                (SettingsAddressesState s) => s.labelUpdateNonce > 0,
              );
              final SettingsAddressLabelError? labelError =
                  bloc.state.labelError;
              await bloc.close();
              final String actualError = switch (labelError) {
                null => 'ok',
                SettingsAddressLabelError.empty => 'empty',
                SettingsAddressLabelError.tooLong => 'too_long',
                SettingsAddressLabelError.alreadyExists => 'duplicate',
                SettingsAddressLabelError.unexpected => 'unexpected',
              };
              expectBendMatch(
                domain: _kDomain,
                caseId: caseId,
                actual: actualError,
                expected: expected,
              );

            case 'validate_protocol_args':
              final int argCount = requireInt(args, 'arg_count');
              final bool hasPlaceholder = requireBool(args, 'has_placeholder');
              final List<String> rawArgs = argCount == 0
                  ? <String>[]
                  : <String>[
                      if (hasPlaceholder) '%s' else '--arg',
                      for (int i = 1; i < argCount; i += 1) '--arg$i',
                    ];
              bool accepted;
              try {
                protocolHandler.getArguments(rawArgs);
                accepted = true;
                // ProtocolHandler.getArguments explicitly throws ArgumentError
                // for empty lists or lists missing the '%s' placeholder.
                // ignore: avoid_catching_errors
              } on ArgumentError {
                accepted = false;
              }
              expectBendMatch(
                domain: _kDomain,
                caseId: caseId,
                actual: accepted,
                expected: expected,
              );

            default:
              fail('Unhandled Bend conformance op "$_kDomain/$op"');
          }
        }

        expect(
          seenOps,
          equals(const <String>{
            'asset_cmp',
            'big_min_max',
            'correct_value',
            'extract_decimals',
            'password_match',
            'password_strength',
            'plasma_tier',
            'resolve_max_amount',
            'roundtrip_decimals',
            'validate_address_label',
            'validate_protocol_args',
          }),
        );
      },
    );

    test(
      'sortAssets and resolveMaxAmountText preserve ordering and clamping',
      () {
        final Token ztsA = _buildAssetToken('zts', 1);
        final Token ztsB = _buildAssetToken('zts', 2);
        final List<Token> sorted = sortAssets(<Token>[
          ztsA,
          kQsrCoin,
          ztsB,
          kZnnCoin,
        ]);
        expect(
          sorted.map((Token t) => t.symbol).toList(),
          equals(<String>['ZNN', 'QSR', 'T1', 'T2']),
        );

        final String? negativeClamped = resolveMaxAmountText(
          maxBalance: BigInt.from(-5),
          decimals: 0,
          currentAmount: BigInt.from(10),
        );
        expect(negativeClamped, equals('0'));

        final String? alreadyMax = resolveMaxAmountText(
          maxBalance: BigInt.from(42),
          decimals: 0,
          currentAmount: BigInt.from(42),
        );
        expect(alreadyMax, isNull);
      },
    );
  }, skip: bendConformanceSkipReason);
}
