import 'package:flutter_test/flutter_test.dart';
import 'package:zenon_syrius_wallet_flutter/l10n/app_localizations_en.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/accelerator_donation_stepper/accelerator_donation_stepper.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

void main() {
  final BigInt tenCoins = BigInt.from(10 * oneZnn);

  group('areDonationInputsValid', () {
    test('accepts ZNN-only donation within balance', () {
      expect(
        areDonationInputsValid(
          znnInput: '5',
          qsrInput: '',
          znnBalance: tenCoins,
          qsrBalance: BigInt.zero,
        ),
        isTrue,
      );
    });

    test('accepts QSR-only donation within balance', () {
      expect(
        areDonationInputsValid(
          znnInput: '',
          qsrInput: '5',
          znnBalance: BigInt.zero,
          qsrBalance: tenCoins,
        ),
        isTrue,
      );
    });

    test('accepts combined ZNN and QSR donation', () {
      expect(
        areDonationInputsValid(
          znnInput: '2.5',
          qsrInput: '1.5',
          znnBalance: tenCoins,
          qsrBalance: tenCoins,
        ),
        isTrue,
      );
    });

    test('rejects empty inputs and zero amounts', () {
      expect(
        areDonationInputsValid(
          znnInput: '',
          qsrInput: '',
          znnBalance: tenCoins,
          qsrBalance: tenCoins,
        ),
        isFalse,
      );
      expect(
        areDonationInputsValid(
          znnInput: '0',
          qsrInput: '0',
          znnBalance: tenCoins,
          qsrBalance: tenCoins,
        ),
        isFalse,
      );
    });

    test('rejects non-zero input when balance is zero', () {
      expect(
        areDonationInputsValid(
          znnInput: '1',
          qsrInput: '',
          znnBalance: BigInt.zero,
          qsrBalance: tenCoins,
        ),
        isFalse,
      );
      expect(
        validateAcceleratorAmount(
          value: '1',
          maxValue: BigInt.zero,
          decimals: coinDecimals,
          minValue: BigInt.zero,
          canBeBlank: true,
        ),
        isNotNull,
      );
    });

    test('rejects amount exceeding balance', () {
      expect(
        areDonationInputsValid(
          znnInput: '11',
          qsrInput: '',
          znnBalance: tenCoins,
          qsrBalance: tenCoins,
        ),
        isFalse,
      );
    });

    test('returns localized validation messages when l10n is provided', () {
      final AppLocalizationsEn l10n = AppLocalizationsEn();
      expect(
        validateAcceleratorAmount(
          value: '',
          maxValue: tenCoins,
          decimals: coinDecimals,
          minValue: BigInt.zero,
          l10n: l10n,
        ),
        l10n.enterValidAmount,
      );
      expect(
        validateAcceleratorAmount(
          value: '1.123456789',
          maxValue: tenCoins,
          decimals: coinDecimals,
          minValue: BigInt.zero,
          l10n: l10n,
        ),
        l10n.inputtedNumberHasTooManyDecimals,
      );
      expect(
        validateAcceleratorAmount(
          value: '1',
          maxValue: BigInt.zero,
          decimals: coinDecimals,
          minValue: BigInt.zero,
          l10n: l10n,
        ),
        l10n.valueMustBeZero,
      );
    });
  });
}
