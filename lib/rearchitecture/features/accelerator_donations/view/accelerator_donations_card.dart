import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/accelerator_donation_stepper/accelerator_donation_stepper.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/screens/screens.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';

/// Card that launches the Accelerator donation stepper.
class AcceleratorDonationsCard extends StatelessWidget {
  /// Creates an [AcceleratorDonationsCard].
  const AcceleratorDonationsCard({
    required this._onStepperNotificationSeeMorePressed,
    this._onDonationSubmitted,
    super.key,
  });

  final VoidCallback _onStepperNotificationSeeMorePressed;
  final VoidCallback? _onDonationSubmitted;

  @override
  Widget build(BuildContext context) {
    return NewCardScaffold(
      data: _buildCardData(context),
      body: _View(
        onStepperNotificationSeeMorePressed:
            _onStepperNotificationSeeMorePressed,
        onDonationSubmitted: _onDonationSubmitted,
      ),
    );
  }

  CardData _buildCardData(BuildContext context) => CardData(
    title: context.l10n.acceleratorDonations,
    description: context.l10n.thankYouForSupportingAccelerator,
  );
}

class _View extends StatelessWidget {
  const _View({
    required this._onStepperNotificationSeeMorePressed,
    this._onDonationSubmitted,
  });

  final VoidCallback _onStepperNotificationSeeMorePressed;
  final VoidCallback? _onDonationSubmitted;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        const Icon(
          MaterialCommunityIcons.ufo_outline,
          size: 75,
          color: AppColors.znnColor,
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SizedBox(
              width: 200,
              child: Text(
                context.l10n.fuelForTheMothership,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            kVerticalSpacing,
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (BuildContext context) => StepperScreen(
                      stepper: AcceleratorDonationStepperPage(
                        onDonationSubmitted: _onDonationSubmitted,
                      ),
                      onStepperNotificationSeeMorePressed:
                          _onStepperNotificationSeeMorePressed,
                    ),
                  ),
                );
              },
              label: Text(context.l10n.donate),
              icon: const Icon(Icons.add),
            ),
          ],
        ),
      ],
    );
  }
}
