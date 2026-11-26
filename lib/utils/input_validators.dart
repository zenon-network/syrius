import 'package:convert/convert.dart';
import 'package:logging/logging.dart';
import 'package:validators/validators.dart';
import 'package:zenon_syrius_wallet_flutter/l10n/app_localizations.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/l10n/app_localizations_resolver.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class InputValidators {
  static String kEVMAddressRegex = r'^(0x)([a-fA-F0-9]){40}$';

  static String? evmAddress(String? address, {AppLocalizations? l10n}) {
    if (address != null && RegExp(kEVMAddressRegex).hasMatch(address)) {
      return null;
    }
    return (l10n ?? resolveAppLocalizations()).invalidAddress;
  }

  static String? node(String? node, {AppLocalizations? l10n}) {
    if (node != null &&
        RegExp(
          r'^(wss?://)([0-9]{1,3}(?:.[0-9]{1,3}){3}|[^/]+):([0-9]{1,5})$',
        ).hasMatch(node)) {
      return null;
    }
    return (l10n ?? resolveAppLocalizations()).invalidNode;
  }

  static String? recipientAddress(
    String recipientAddress, {
    AppLocalizations? l10n,
  }) {
    if (!kDefaultAddressList.contains(recipientAddress)) {
      return (l10n ?? resolveAppLocalizations()).mustBeAddressFromWallet;
    }
    return null;
  }

  static String? notEmpty(
    String fieldName,
    String? value, {
    AppLocalizations? l10n,
  }) {
    return (value ?? '').isEmpty
        ? (l10n ?? resolveAppLocalizations()).fieldMustNotBeEmpty(fieldName)
        : null;
  }

  static String? validateNumber(String? number, {AppLocalizations? l10n}) {
    final AppLocalizations resolvedL10n = l10n ?? resolveAppLocalizations();
    try {
      if (number == null || number.isEmpty) {
        return resolvedL10n.numberRequired;
      }
      int.parse(number);
      return null;
    } catch (e, stackTrace) {
      Logger(
        'InputValidators',
      ).log(Level.SEVERE, 'validateNumber ', e, stackTrace);
      return resolvedL10n.inputNotValidNumber;
    }
  }

  static String? validateAmount(String? value, {AppLocalizations? l10n}) {
    final AppLocalizations resolvedL10n = l10n ?? resolveAppLocalizations();
    if (value != null) {
      try {
        if (value.isEmpty) {
          return resolvedL10n.invalidAmount;
        }
        BigInt.parse(value);
        return null;
      } catch (e, stackTrace) {
        Logger(
          'InputValidators',
        ).log(Level.SEVERE, 'validateAmount', e, stackTrace);
        return resolvedL10n.error;
      }
    } else {
      return resolvedL10n.valueIsNull;
    }
  }

  static String? correctValue(
    String? value,
    BigInt maxValue,
    int decimals,
    BigInt minValue, {
    bool canBeEqualToMin = false,
    bool canBeBlank = false,
    AppLocalizations? l10n,
  }) {
    final AppLocalizations resolvedL10n = l10n ?? resolveAppLocalizations();
    if (value != null) {
      try {
        if (maxValue == BigInt.zero) {
          if (canBeEqualToMin) {
            return null;
          }
          return resolvedL10n.emptyBalance;
        }
        if (value.isEmpty) {
          if (canBeBlank) {
            return null;
          } else {
            return resolvedL10n.enterValidAmount;
          }
        }

        final BigInt inputNum = value.extractDecimals(decimals);

        if (value.contains('.') && value.split('.')[1].length > decimals) {
          return resolvedL10n.inputtedNumberHasTooManyDecimals;
        }
        if (maxValue < minValue) {
          return resolvedL10n.availableBalanceMustBeAtLeast(
            minValue.addDecimals(decimals),
          );
        }
        if (canBeEqualToMin) {
          return minValue <= inputNum && inputNum <= maxValue
              ? null
              : maxValue == minValue
              ? resolvedL10n.valueMustBe(minValue.addDecimals(decimals))
              : resolvedL10n.valueMustBeBetween(
                  minValue.addDecimals(decimals),
                  maxValue.addDecimals(decimals),
                );
        }
        return minValue < inputNum && inputNum <= maxValue
            ? null
            : maxValue == minValue
            ? resolvedL10n.valueMustBe(minValue.addDecimals(decimals))
            : resolvedL10n.valueMustBeBetween(
                minValue.addDecimals(decimals),
                maxValue.addDecimals(decimals),
              );
      } catch (e, stackTrace) {
        Logger(
          'InputValidators',
        ).log(Level.SEVERE, 'correctValue', e, stackTrace);
        return resolvedL10n.error;
      }
    }
    return resolvedL10n.valueCannotBeEmpty;
  }

  static String? checkAddress(String? value, {AppLocalizations? l10n}) {
    final AppLocalizations resolvedL10n = l10n ?? resolveAppLocalizations();
    if (value != null) {
      if (value.isEmpty) {
        return resolvedL10n.enterAddress;
      }
      return Address.isValid(value) ? null : resolvedL10n.invalidAddress;
    } else {
      return resolvedL10n.valueIsNull;
    }
  }

  static String? checkPasswordMatch(
    String firstPass,
    String? secondPass, {
    AppLocalizations? l10n,
  }) {
    if (firstPass != secondPass) {
      return (l10n ?? resolveAppLocalizations()).passwordsDoNotMatch;
    }
    return null;
  }

  static String? validatePassword(String? value, {AppLocalizations? l10n}) {
    final AppLocalizations resolvedL10n = l10n ?? resolveAppLocalizations();
    if (value != null) {
      if (value.length < 8) {
        return resolvedL10n.passwordNotStrongEnough;
      }
      const String pattern =
          r'''^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[`~!@#$%^&*()\-_=+\[\]\{\}\\|;:",<.>\/\?']).{8,}$''';
      final RegExp regExp = RegExp(pattern);
      if (regExp.hasMatch(value)) {
        return null;
      }
      return resolvedL10n.invalidPassword;
    } else {
      return resolvedL10n.valueIsNull;
    }
  }

  static String? validatePillarMomentumAddress(
    String? value, {
    AppLocalizations? l10n,
  }) {
    final AppLocalizations resolvedL10n = l10n ?? resolveAppLocalizations();
    if (value != null) {
      final String? addressError = checkAddress(value, l10n: resolvedL10n);
      if (addressError == null) {
        if (kDefaultAddressList.contains(value)) {
          return resolvedL10n.pillarProducerAddressDifferentSeed;
        }
      } else {
        return addressError;
      }
      return null;
    } else {
      return resolvedL10n.valueIsNull;
    }
  }

  static String? isMaxSupplyZero(String? value, {AppLocalizations? l10n}) {
    final AppLocalizations resolvedL10n = l10n ?? resolveAppLocalizations();
    if (value != null) {
      try {
        if (BigInt.parse(value) != BigInt.zero) {
          return resolvedL10n.maxSupplyZeroForNonMintableTokens;
        }
        return null;
      } catch (e, stackTrace) {
        Logger(
          'InputValidators',
        ).log(Level.SEVERE, 'isMaxSupplyZero', e, stackTrace);
        return resolvedL10n.error;
      }
    } else {
      return resolvedL10n.valueIsNull;
    }
  }

  static String? checkUrl(String? value, {AppLocalizations? l10n}) {
    final List<String> protocols = <String>['https'];

    if (isURL(value, protocols: protocols)) {
      return null;
    }
    return (l10n ?? resolveAppLocalizations()).invalidUrl;
  }

  static String? checkHash(String? value, {AppLocalizations? l10n}) {
    try {
      if (Hash.parse(value!).runtimeType == Hash) {
        return null;
      }
    } catch (e) {
      return (l10n ?? resolveAppLocalizations()).invalidHash;
    }
    return (l10n ?? resolveAppLocalizations()).invalidHash;
  }

  static Future<String?> checkSecret(
    HtlcInfo htlc,
    String? value, {
    AppLocalizations? l10n,
  }) async {
    if (value != null) {
      try {
        final Hash preimageCheck = htlc.hashType == htlcHashTypeSha3
            ? Hash.digest(hex.decode(value))
            : Hash.fromBytes(await Crypto.sha256Bytes(hex.decode(value)));

        if (preimageCheck == Hash.fromBytes(htlc.hashLock)) {
          return null;
        }
      } catch (e) {
        return (l10n ?? resolveAppLocalizations()).invalidSecret;
      }
    }
    return (l10n ?? resolveAppLocalizations()).invalidSecret;
  }
}
