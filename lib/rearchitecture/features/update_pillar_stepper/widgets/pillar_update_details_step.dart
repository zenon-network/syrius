import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';

/// Details step for updating a pillar.
class PillarUpdateDetailsStep extends StatelessWidget {
  /// Creates a [PillarUpdateDetailsStep].
  const PillarUpdateDetailsStep({
    required this.onCancelPressed,
    required this.onNextPressed,
    required this.pillarNameController,
    required this.pillarProducerController,
    required this.pillarRewardController,
    super.key,
  });

  /// Called when the user cancels the update flow.
  final VoidCallback onCancelPressed;

  /// Called when valid details can continue to the next step.
  final VoidCallback onNextPressed;

  /// Controller containing the immutable pillar name.
  final TextEditingController pillarNameController;

  /// Controller containing the reward address.
  final TextEditingController pillarRewardController;

  /// Controller containing the producer address.
  final TextEditingController pillarProducerController;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          context.l10n.pillarName,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        kVerticalSpacing,
        TextField(
          controller: pillarNameController,
          enabled: false,
          style: const TextStyle(
            color: AppColors.znnColor,
          ),
        ),
        kVerticalSpacing,
        Text(
          context.l10n.pillarRewardAddress,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        kVerticalSpacing,
        TextFormField(
          autovalidateMode: AutovalidateMode.onUserInteraction,
          decoration: InputDecoration(
            hintText: context.l10n.pillarRewardAddress,
            suffixIcon: FieldSuffixButtons(controller: pillarRewardController),
          ),
          controller: pillarRewardController,
          validator: InputValidators.checkAddress,
          style: const TextStyle(
            color: AppColors.znnColor,
          ),
        ),
        kVerticalSpacing,
        Text(
          context.l10n.pillarProducerAddress,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        kVerticalSpacing,
        TextFormField(
          autovalidateMode: AutovalidateMode.onUserInteraction,
          controller: pillarProducerController,
          decoration: InputDecoration(
            hintText: context.l10n.pillarProducerAddress,
            suffixIcon: FieldSuffixButtons(
              controller: pillarProducerController,
            ),
          ),
          style: const TextStyle(
            color: AppColors.znnColor,
          ),
          validator: InputValidators.validatePillarMomentumAddress,
        ),
        kVerticalSpacing,
        Row(
          children: <Widget>[
            OutlinedButton(
              onPressed: onCancelPressed,
              child: Text(context.l10n.cancel),
            ),
            kHorizontalGap25,
            ListenableBuilder(
              listenable: Listenable.merge(<Listenable>[
                pillarRewardController,
                pillarProducerController,
              ]),
              builder: (_, _) => OutlinedButton(
                onPressed: _arePillarDetailsValid() ? onNextPressed : null,
                child: Text(context.l10n.next),
              ),
            ),
          ],
        ),
      ],
    );
  }

  bool _arePillarDetailsValid() =>
      InputValidators.checkAddress(pillarRewardController.text) == null &&
      InputValidators.validatePillarMomentumAddress(
            pillarProducerController.text,
          ) ==
          null;
}
