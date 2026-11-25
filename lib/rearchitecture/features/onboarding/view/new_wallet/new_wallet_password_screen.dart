import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/onboarding/widgets/onboarding_password_view.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';

/// Password creation screen for new wallet onboarding.
class NewWalletPasswordScreen extends StatelessWidget {
  /// Creates a [NewWalletPasswordScreen].
  const NewWalletPasswordScreen(this._seedWords, {super.key});

  final List<String> _seedWords;

  @override
  Widget build(BuildContext context) {
    return OnboardingPasswordView(
      currentLevel: 3,
      numLevels: 5,
      popResult: false,
      onConfirmed: (String password) {
        NavigationUtils.push(
          context,
          CreateKeyStoreScreen(_seedWords.join(' '), password),
        );
      },
    );
  }
}
