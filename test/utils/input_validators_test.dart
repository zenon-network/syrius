import 'package:flutter_test/flutter_test.dart';
import 'package:zenon_syrius_wallet_flutter/l10n/app_localizations_en.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class _CustomAppLocalizations extends AppLocalizationsEn {
  _CustomAppLocalizations() : super('en');

  @override
  String get invalidAddress => '[L10N] invalidAddress';

  @override
  String get invalidNode => '[L10N] invalidNode';

  @override
  String get mustBeAddressFromWallet => '[L10N] mustBeAddressFromWallet';

  @override
  String fieldMustNotBeEmpty(String fieldName) =>
      '[L10N] fieldMustNotBeEmpty:$fieldName';

  @override
  String get numberRequired => '[L10N] numberRequired';

  @override
  String get inputNotValidNumber => '[L10N] inputNotValidNumber';

  @override
  String get invalidAmount => '[L10N] invalidAmount';

  @override
  String get error => '[L10N] error';

  @override
  String get valueIsNull => '[L10N] valueIsNull';

  @override
  String get emptyBalance => '[L10N] emptyBalance';

  @override
  String get enterValidAmount => '[L10N] enterValidAmount';

  @override
  String get inputtedNumberHasTooManyDecimals =>
      '[L10N] inputtedNumberHasTooManyDecimals';

  @override
  String availableBalanceMustBeAtLeast(String minValue) =>
      '[L10N] availableBalanceMustBeAtLeast:$minValue';

  @override
  String valueMustBe(String value) => '[L10N] valueMustBe:$value';

  @override
  String valueMustBeBetween(String minValue, String maxValue) =>
      '[L10N] valueMustBeBetween:$minValue..$maxValue';

  @override
  String get valueCannotBeEmpty => '[L10N] valueCannotBeEmpty';

  @override
  String get enterAddress => '[L10N] enterAddress';

  @override
  String get passwordsDoNotMatch => '[L10N] passwordsDoNotMatch';

  @override
  String get passwordNotStrongEnough => '[L10N] passwordNotStrongEnough';

  @override
  String get invalidPassword => '[L10N] invalidPassword';

  @override
  String get pillarProducerAddressDifferentSeed =>
      '[L10N] pillarProducerAddressDifferentSeed';

  @override
  String get maxSupplyZeroForNonMintableTokens =>
      '[L10N] maxSupplyZeroForNonMintableTokens';

  @override
  String get invalidUrl => '[L10N] invalidUrl';

  @override
  String get invalidHash => '[L10N] invalidHash';

  @override
  String get invalidSecret => '[L10N] invalidSecret';
}

void main() {
  group('InputValidators localization', () {
    final AppLocalizationsEn en = AppLocalizationsEn();
    final _CustomAppLocalizations custom = _CustomAppLocalizations();
    const String validAddress = 'z1qqjnwjjpnue8xmmpanz6csze6tcmtzzdtfsww7';
    late List<String?> previousAddresses;

    setUp(() {
      previousAddresses = kDefaultAddressList;
      kDefaultAddressList = <String?>[validAddress];
    });

    tearDown(() {
      kDefaultAddressList = previousAddresses;
    });

    test('evmAddress uses provided AppLocalizations', () {
      expect(
        InputValidators.evmAddress(
          '0x0123456789abcdef0123456789abcdef01234567',
          l10n: custom,
        ),
        isNull,
      );
      expect(InputValidators.evmAddress('invalid'), en.invalidAddress);
      expect(
        InputValidators.evmAddress('invalid', l10n: custom),
        '[L10N] invalidAddress',
      );
    });

    test('node uses provided AppLocalizations', () {
      expect(InputValidators.node('wss://node.zenon.network:35998'), isNull);
      expect(InputValidators.node('not-a-node'), en.invalidNode);
      expect(
        InputValidators.node('not-a-node', l10n: custom),
        '[L10N] invalidNode',
      );
    });

    test('recipientAddress uses provided AppLocalizations', () {
      expect(InputValidators.recipientAddress(validAddress), isNull);
      expect(
        InputValidators.recipientAddress('z1other'),
        en.mustBeAddressFromWallet,
      );
      expect(
        InputValidators.recipientAddress('z1other', l10n: custom),
        '[L10N] mustBeAddressFromWallet',
      );
    });

    test('notEmpty uses provided AppLocalizations', () {
      expect(InputValidators.notEmpty('Name', 'value', l10n: custom), isNull);
      expect(
        InputValidators.notEmpty('Name', ''),
        en.fieldMustNotBeEmpty('Name'),
      );
      expect(
        InputValidators.notEmpty('Name', '', l10n: custom),
        '[L10N] fieldMustNotBeEmpty:Name',
      );
    });

    test('validateNumber uses provided AppLocalizations', () {
      expect(InputValidators.validateNumber('42', l10n: custom), isNull);
      expect(InputValidators.validateNumber(''), en.numberRequired);
      expect(
        InputValidators.validateNumber('', l10n: custom),
        '[L10N] numberRequired',
      );
      expect(InputValidators.validateNumber('abc'), en.inputNotValidNumber);
      expect(
        InputValidators.validateNumber('abc', l10n: custom),
        '[L10N] inputNotValidNumber',
      );
    });

    test('validateAmount uses provided AppLocalizations', () {
      expect(InputValidators.validateAmount('100', l10n: custom), isNull);
      expect(InputValidators.validateAmount(null), en.valueIsNull);
      expect(
        InputValidators.validateAmount(null, l10n: custom),
        '[L10N] valueIsNull',
      );
      expect(InputValidators.validateAmount(''), en.invalidAmount);
      expect(
        InputValidators.validateAmount('', l10n: custom),
        '[L10N] invalidAmount',
      );
      expect(InputValidators.validateAmount('bad'), en.error);
      expect(
        InputValidators.validateAmount('bad', l10n: custom),
        '[L10N] error',
      );
    });

    test(
      'correctValue uses provided AppLocalizations for every error branch',
      () {
        expect(
          InputValidators.correctValue(
            null,
            BigInt.from(100),
            0,
            BigInt.zero,
            l10n: custom,
          ),
          '[L10N] valueCannotBeEmpty',
        );
        expect(
          InputValidators.correctValue(
            '1',
            BigInt.zero,
            0,
            BigInt.zero,
            l10n: custom,
          ),
          '[L10N] emptyBalance',
        );
        expect(
          InputValidators.correctValue(
            '',
            BigInt.from(100),
            0,
            BigInt.zero,
            l10n: custom,
          ),
          '[L10N] enterValidAmount',
        );
        expect(
          InputValidators.correctValue(
            '1.123',
            BigInt.from(10000),
            2,
            BigInt.zero,
            l10n: custom,
          ),
          '[L10N] inputtedNumberHasTooManyDecimals',
        );
        expect(
          InputValidators.correctValue(
            '5',
            BigInt.from(5),
            0,
            BigInt.from(10),
            l10n: custom,
          ),
          '[L10N] availableBalanceMustBeAtLeast:10',
        );
        expect(
          InputValidators.correctValue(
            '5',
            BigInt.from(10),
            0,
            BigInt.from(10),
            canBeEqualToMin: true,
            l10n: custom,
          ),
          '[L10N] valueMustBe:10',
        );
        expect(
          InputValidators.correctValue(
            '5',
            BigInt.from(10),
            0,
            BigInt.from(10),
            l10n: custom,
          ),
          '[L10N] valueMustBe:10',
        );
        expect(
          InputValidators.correctValue(
            '50',
            BigInt.from(20),
            0,
            BigInt.from(10),
            canBeEqualToMin: true,
            l10n: custom,
          ),
          '[L10N] valueMustBeBetween:10..20',
        );
        expect(
          InputValidators.correctValue(
            '10',
            BigInt.from(20),
            0,
            BigInt.from(10),
            l10n: custom,
          ),
          '[L10N] valueMustBeBetween:10..20',
        );
        expect(
          InputValidators.correctValue(
            'not-a-number',
            BigInt.from(20),
            0,
            BigInt.zero,
            l10n: custom,
          ),
          '[L10N] error',
        );
        expect(
          InputValidators.correctValue(
            '15',
            BigInt.from(20),
            0,
            BigInt.from(10),
            l10n: custom,
          ),
          isNull,
        );
      },
    );

    test('checkAddress uses provided AppLocalizations', () {
      expect(InputValidators.checkAddress(validAddress, l10n: custom), isNull);
      expect(
        InputValidators.checkAddress(null, l10n: custom),
        '[L10N] valueIsNull',
      );
      expect(
        InputValidators.checkAddress('', l10n: custom),
        '[L10N] enterAddress',
      );
      expect(
        InputValidators.checkAddress('bad-address', l10n: custom),
        '[L10N] invalidAddress',
      );
    });

    test('password validators use provided AppLocalizations', () {
      expect(
        InputValidators.checkPasswordMatch(
          'A1!aaaaa',
          'A1!aaaaa',
          l10n: custom,
        ),
        isNull,
      );
      expect(
        InputValidators.checkPasswordMatch(
          'A1!aaaaa',
          'different',
          l10n: custom,
        ),
        '[L10N] passwordsDoNotMatch',
      );
      expect(
        InputValidators.validatePassword(null, l10n: custom),
        '[L10N] valueIsNull',
      );
      expect(
        InputValidators.validatePassword('short', l10n: custom),
        '[L10N] passwordNotStrongEnough',
      );
      expect(
        InputValidators.validatePassword('abcdefgh', l10n: custom),
        '[L10N] invalidPassword',
      );
      expect(
        InputValidators.validatePassword('Strong1!', l10n: custom),
        isNull,
      );
    });

    test('validatePillarMomentumAddress uses provided AppLocalizations', () {
      expect(
        InputValidators.validatePillarMomentumAddress(null, l10n: custom),
        '[L10N] valueIsNull',
      );
      expect(
        InputValidators.validatePillarMomentumAddress('', l10n: custom),
        '[L10N] enterAddress',
      );
      expect(
        InputValidators.validatePillarMomentumAddress(
          validAddress,
          l10n: custom,
        ),
        '[L10N] pillarProducerAddressDifferentSeed',
      );
      expect(
        InputValidators.validatePillarMomentumAddress(
          emptyAddress.toString(),
          l10n: custom,
        ),
        isNull,
      );
    });

    test('isMaxSupplyZero uses provided AppLocalizations', () {
      expect(InputValidators.isMaxSupplyZero('0', l10n: custom), isNull);
      expect(
        InputValidators.isMaxSupplyZero(null, l10n: custom),
        '[L10N] valueIsNull',
      );
      expect(
        InputValidators.isMaxSupplyZero('5', l10n: custom),
        '[L10N] maxSupplyZeroForNonMintableTokens',
      );
      expect(
        InputValidators.isMaxSupplyZero('bad', l10n: custom),
        '[L10N] error',
      );
    });

    test(
      'checkUrl, checkHash, and checkSecret use provided AppLocalizations',
      () async {
        expect(
          InputValidators.checkUrl('https://zenon.network', l10n: custom),
          isNull,
        );
        expect(
          InputValidators.checkUrl('http://insecure.example', l10n: custom),
          '[L10N] invalidUrl',
        );

        expect(
          InputValidators.checkHash(emptyHash.toString(), l10n: custom),
          isNull,
        );
        expect(
          InputValidators.checkHash('not-a-hash', l10n: custom),
          '[L10N] invalidHash',
        );

        final List<int> preimage = <int>[1, 2, 3, 4];
        final HtlcInfo htlc = HtlcInfo(
          id: emptyHash,
          timeLocked: emptyAddress,
          hashLocked: emptyAddress,
          tokenStandard: znnZts,
          amount: BigInt.one,
          expirationTime: 0,
          hashType: htlcHashTypeSha3,
          keyMaxSize: 32,
          hashLock: Hash.digest(preimage).getBytes()!,
        );
        expect(
          await InputValidators.checkSecret(htlc, '01020304', l10n: custom),
          isNull,
        );
        expect(
          await InputValidators.checkSecret(htlc, 'deadbeef', l10n: custom),
          '[L10N] invalidSecret',
        );
        expect(
          await InputValidators.checkSecret(htlc, 'zzzz', l10n: custom),
          '[L10N] invalidSecret',
        );
      },
    );
  });
}
