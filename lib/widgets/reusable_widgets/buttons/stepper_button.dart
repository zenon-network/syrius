import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

class StepperButton extends MyOutlinedButton {
  const StepperButton({
    required super.onPressed,
    super.text,
    super.outlineColor,
    super.child,
    super.key,
  }) : super(
          minimumSize: const Size(120, 40),
        );

  factory StepperButton.icon({
    required String label,
    required IconData iconData,
    required VoidCallback onPressed,
  }) =>
      _MyStepperButtonWithIcon(
        onPressed: onPressed,
        label: label,
        iconData: iconData,
      );
}

class _MyStepperButtonWithIcon extends StepperButton {
  _MyStepperButtonWithIcon({
    required String label,
    required IconData iconData,
    required VoidCallback super.onPressed,
  }) : super(
          child: _MyStepperButtonWithIconChild(
            label: label,
            iconData: iconData,
          ),
        );
}

class _MyStepperButtonWithIconChild extends StatelessWidget {

  const _MyStepperButtonWithIconChild({
    required this.label,
    required this.iconData,
  });
  final String label;
  final IconData iconData;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label),
        const SizedBox(
          width: 10,
        ),
        Icon(
          iconData,
          size: 17,
          color: Theme.of(context).textTheme.headlineSmall!.color,
        ),
      ],
    );
  }
}
