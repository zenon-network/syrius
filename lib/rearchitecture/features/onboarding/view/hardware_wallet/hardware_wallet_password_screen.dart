import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/onboarding/widgets/onboarding_password_view.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// Password creation screen for hardware wallet onboarding.
class HardwareWalletPasswordScreen extends StatelessWidget {
  /// Creates a [HardwareWalletPasswordScreen].
  const HardwareWalletPasswordScreen(this._deviceInfo, {super.key});

  final WalletDefinition _deviceInfo;

  @override
  Widget build(BuildContext context) {
    return OnboardingPasswordView(
      currentLevel: 2,
      numLevels: 4,
      popResult: false,
      onConfirmed: (String password) {
        NavigationUtils.push(
          context,
          CreateLedgerWalletScreen(_deviceInfo, password),
        );
      },
    );
  }
}
