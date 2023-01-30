import 'package:validators/validators.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:zenon_syrius_wallet_flutter/utils/logger.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class InputValidators {
  static String kEVMAddressRegex = r'^(0x)([a-fA-F0-9]){40}$';

  static String? evmAddress(String? address) {
    if (address != null && RegExp(kEVMAddressRegex).hasMatch(address)) {
      return null;
    }
    return 'Invalid address';
  }

  static String? node(String? node) {
    if (node != null &&
        RegExp(r'^(wss?://)([0-9]{1,3}(?:.[0-9]{1,3}){3}|[^/]+):([0-9]{1,5})$')
            .hasMatch(node)) {
      return null;
    }
    return 'Invalid Node';
  }

  static String? recipientAddress(String recipientAddress) {
    if (!kDefaultAddressList.contains(recipientAddress)) {
      return 'Must be an address from your wallet';
    }
    return null;
  }

  static String? notEmpty(String fieldName, String? value) {
    return (value ?? '').isEmpty ? '$fieldName must not be empty' : null;
  }

  static String? validateNumber(String? number) {
    try {
      if (number == null) {
        return 'Add a number';
      }
      int.parse(number);
      return null;
    } catch (e) {
      return 'Input is not a valid number';
    }
  }

  static String? validateAmount(String? value) {
    if (value != null) {
      try {
        if (value.isEmpty) {
          return 'Invalid amount';
        }
        if (value.length > kAmountInputMaxCharacterLength) {
          return 'Input max length is $kAmountInputMaxCharacterLength characters';
        }
        double.parse(value);
        return null;
      } catch (e) {
        Logger.logError(e);
        return 'Error';
      }
    } else {
      return 'Value is null';
    }
  }

  static String? correctValue(
    String? value,
    num? maxValue,
    int decimals, {
    num min = 0,
    bool canBeEqualToMin = false,
    bool canBeBlank = false,
  }) {
    if (value != null) {
      try {
        if (maxValue == 0) {
          if (canBeEqualToMin) {
            return null;
          }
          return 'Empty balance';
        }
        if (value.isEmpty) {
          if (canBeBlank) {
            return null;
          } else {
            return 'Enter a valid amount';
          }
        }
        if (value.length > kAmountInputMaxCharacterLength) {
          return 'Input max length is $kAmountInputMaxCharacterLength characters';
        }
        double inputNum = double.parse(value);
        if (value.contains('.') && value.split('.')[1].length > decimals) {
          return 'Inputted number has too many decimals';
        }
        if (maxValue! < min) {
          return 'Your available balance must be at least $min';
        }
        if (canBeEqualToMin) {
          return min <= inputNum && inputNum <= maxValue
              ? null
              : maxValue == min
                  ? 'Value must be $min'
                  : 'Value must be between $min and $maxValue';
        }
        return min < inputNum && inputNum <= maxValue
            ? null
            : maxValue == min
                ? 'Value must be $min'
                : 'Value must be between $min and $maxValue';
      } catch (e) {
        Logger.logError(e);
        return 'Error';
      }
    }
    return 'Value can\'t be empty';
  }

  static String? checkAddress(String? value) {
    if (value != null) {
      if (value.isEmpty) {
        return 'Enter an address';
      }
      return Address.isValid(value) ? null : 'Invalid address';
    } else {
      return 'Value is null';
    }
  }

  static String? checkPasswordMatch(String firstPass, String? secondPass) {
    if (firstPass != secondPass) {
      return 'Passwords do not match';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value != null) {
      if (value.length < 8) {
        return 'Password not strong enough';
      }
      String pattern =
          r'''^(?=.*?[A-Z])(?=.*?[a-z])(?=.*?[0-9])(?=.*?[`~!@#$%^&*()\-_=+\[\]\{\}\\|;:",<.>\/\?']).{8,}$''';
      RegExp regExp = RegExp(pattern);
      if (regExp.hasMatch(value)) {
        return null;
      }
      return 'Invalid password';
    } else {
      return 'Value is null';
    }
  }

  static String? validatePillarMomentumAddress(String? value) {
    if (value != null) {
      if (checkAddress(value) == null) {
        if (kDefaultAddressList.contains(value)) {
          return 'Pillar producer address must be generated from a different seed';
        }
      } else {
        return checkAddress(value);
      }
      return null;
    } else {
      return 'Value is null';
    }
  }

  static String? isMaxSupplyZero(String? value) {
    if (value != null) {
      try {
        if (double.parse(value) != 0) {
          return 'Max supply must be 0 for non-mintable tokens';
        }
        return null;
      } catch (e) {
        Logger.logError(e);
        return 'Error';
      }
    } else {
      return 'Value is null';
    }
  }

  static String? checkUrl(String? value) {
    if (isURL(value)) {
      return null;
    }
    return 'Invalid URL';
  }
}
