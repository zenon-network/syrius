import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:zenon_syrius_wallet_flutter/screens/onboarding/access_wallet_screen.dart';
import 'package:zenon_syrius_wallet_flutter/screens/swap/swap_info_screen.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/utils/navigation_utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/main_app_container.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/buttons/onboarding_button.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/progress_bars.dart';

class WalletSuccessScreen extends StatefulWidget {
  final int progressBarNumLevels;

  const WalletSuccessScreen({
    this.progressBarNumLevels = 5,
    Key? key,
  }) : super(key: key);

  @override
  _WalletSuccessScreenState createState() => _WalletSuccessScreenState();
}

class _WalletSuccessScreenState extends State<WalletSuccessScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 30.0,
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
              height: 30.0,
            ),
            Text(
              'You\'re all set',
              style: Theme.of(context).textTheme.headline1,
            ),
            kVerticalSpacing,
            Text(
              'The wallet has been successfully created',
              style: Theme.of(context).textTheme.headline4,
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
        Column(
          children: [
            _getAccessWalletActionButton(),
            kVerticalSpacing,
            _getSwapWalletButton(),
          ],
        ),
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

  Widget _getSwapWalletButton() {
    return OnboardingButton(
      onPressed: () {
        NavigationUtils.push(
          context,
          const SwapInfoScreen(),
        );
      },
      text: 'Swap wallet',
    );
  }
}
