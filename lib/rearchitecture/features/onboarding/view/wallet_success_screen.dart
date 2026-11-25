import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

/// Final onboarding screen confirming wallet creation and entering the app.
class WalletSuccessScreen extends StatelessWidget {
  /// Creates a [WalletSuccessScreen].
  const WalletSuccessScreen({this._progressBarNumLevels = 5, super.key});

  final int _progressBarNumLevels;

  @override
  Widget build(BuildContext context) {
    return _View(progressBarNumLevels: _progressBarNumLevels);
  }
}

class _View extends StatelessWidget {
  const _View({required this._progressBarNumLevels});

  final int _progressBarNumLevels;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.symmetric(vertical: 30),
        child: _buildSuccessBody(context),
      ),
    );
  }

  Widget _buildSuccessBody(BuildContext context) {
    return Column(
      children: <Widget>[
        Column(
          children: <Widget>[
            ProgressBar(
              currentLevel: _progressBarNumLevels,
              numLevels: _progressBarNumLevels,
            ),
            const SizedBox(height: 30),
            Text(
              context.l10n.youAreAllSet,
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            kVerticalSpacing,
            Text(
              context.l10n.walletSuccessfullyCreated,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
        Expanded(
          child: Center(
            child: Lottie.asset(
              'assets/lottie/ic_anim_map.json',
              fit: BoxFit.contain,
            ),
          ),
        ),
        _buildAccessWalletButton(context),
      ],
    );
  }

  Widget _buildAccessWalletButton(BuildContext context) {
    return OnboardingButton(
      onPressed: () {
        Navigator.popUntil(
          context,
          ModalRoute.withName(AccessWalletScreen.route),
        );
        NavigationUtils.pushReplacement(
          context,
          const MainAppContainer(redirectedFromWalletSuccess: true),
        );
      },
      text: context.l10n.accessWallet,
    );
  }
}
