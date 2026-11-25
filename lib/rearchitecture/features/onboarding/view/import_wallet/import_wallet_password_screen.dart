import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/onboarding/widgets/onboarding_password_view.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';

/// Password creation screen for importing a wallet from a seed or Seed Vault.
class ImportWalletPasswordScreen extends StatelessWidget {
  /// Creates an [ImportWalletPasswordScreen].
  const ImportWalletPasswordScreen(
    this._seed, {
    this._progressBarNumLevels = 5,
    super.key,
  });

  final String _seed;
  final int _progressBarNumLevels;

  @override
  Widget build(BuildContext context) {
    return OnboardingPasswordView(
      currentLevel: _progressBarNumLevels - 2,
      numLevels: _progressBarNumLevels,
      headerSpacing: 100,
      progressBarSpacing: kVerticalSpacing.height ?? 15,
      onConfirmed: (String password) {
        NavigationUtils.push(
          context,
          CreateKeyStoreScreen(
            _seed,
            password,
            progressBarNumLevels: _progressBarNumLevels,
          ),
        );
      },
    );
  }
}
