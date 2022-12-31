import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:zenon_syrius_wallet_flutter/screens/screens.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

class SwapInfoScreen extends StatelessWidget {
  const SwapInfoScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 30.0,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            const ProgressBar(
              currentLevel: 1,
              numLevels: 4,
            ),
            Text(
              'Swap wallet',
              style: Theme.of(context).textTheme.headline1,
            ),
            SizedBox(
              width: 500.0,
              child: Text(
                'This procedure will swap your funds from the legacy network '
                'to Alphanet - Network of Momentum Phase 0. Please make sure you '
                'have wallet backups before proceeding',
                style: Theme.of(context).textTheme.headline4,
                textAlign: TextAlign.center,
              ),
            ),
            const Icon(
              MaterialCommunityIcons.swap_horizontal,
              color: AppColors.znnColor,
              size: 200.0,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OnboardingButton(
                  text: 'Go back',
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
                const SizedBox(
                  width: 70.0,
                ),
                SizedBox(
                  width: 360.0,
                  child: SyriusElevatedButton(
                    onPressed: () {
                      NavigationUtils.push(
                        context,
                        const SwapImportScreen(),
                      );
                    },
                    text: 'Start Swap',
                    initialFillColor: AppColors.znnColor,
                    icon: SvgPicture.asset(
                      'assets/svg/ic_swap_icon.svg',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
