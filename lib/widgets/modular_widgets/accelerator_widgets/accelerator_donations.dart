import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:zenon_syrius_wallet_flutter/screens/screens.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

class AcceleratorDonations extends StatelessWidget {
  final VoidCallback onStepperNotificationSeeMorePressed;

  const AcceleratorDonations({
    required this.onStepperNotificationSeeMorePressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return CardScaffold(
      title: 'Accelerator Donations',
      childBuilder: () => _getWidgetBody(context),
      description: 'Thank you for supporting the Accelerator',
    );
  }

  Widget _getWidgetBody(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        const Icon(
          MaterialCommunityIcons.ufo_outline,
          size: 75.0,
          color: AppColors.znnColor,
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 200.0,
              child: Text(
                'Fuel for the Mothership',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            kVerticalSpacing,
            SyriusElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => StepperScreen(
                      stepper: const AcceleratorDonationStepper(),
                      onStepperNotificationSeeMorePressed:
                          onStepperNotificationSeeMorePressed,
                    ),
                  ),
                );
              },
              text: 'Donate',
              initialFillColor: AppColors.znnColor,
              icon: SyriusElevatedButton.getFilledButtonPlusIcon(),
            ),
          ],
        ),
      ],
    );
  }
}
