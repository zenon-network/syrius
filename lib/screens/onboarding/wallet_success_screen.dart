import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:zenon_syrius_wallet_flutter/screens/screens.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

class WalletSuccessScreen extends StatefulWidget {

  const WalletSuccessScreen({
    this.progressBarNumLevels = 5,
    super.key,
  });
  final int progressBarNumLevels;

  @override
  State<WalletSuccessScreen> createState() => _WalletSuccessScreenState();
}

class _WalletSuccessScreenState extends State<WalletSuccessScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 30,
        ),
        child: _getSuccessBody(),
      ),
    );
  }

  Column _getSuccessBody() {
    return Column(
      children: <Widget>[
        Column(
          children: [
            ProgressBar(
              currentLevel: widget.progressBarNumLevels,
              numLevels: widget.progressBarNumLevels,
            ),
            const SizedBox(
              height: 30,
            ),
            Text(
              "You're all set",
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            kVerticalSpacing,
            Text(
              'The wallet has been successfully created',
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
        _getAccessWalletActionButton(),
      ],
    );
  }

  Widget _getAccessWalletActionButton() {
    return OnboardingButton(
      onPressed: () {
        Navigator.popUntil(
          context,
          ModalRoute.withName(AccessWalletScreen.route),
        );
        NavigationUtils.pushReplacement(
          context,
          const MainAppContainer(
            redirectedFromWalletSuccess: true,
          ),
        );
      },
      text: 'Access wallet',
    );
  }
}
