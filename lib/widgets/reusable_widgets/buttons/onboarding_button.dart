import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

class OnboardingButton extends MyOutlinedButton {
  const OnboardingButton({
    required VoidCallback? onPressed,
    required String text,
    Key? key,
  }) : super(
          key: key,
          onPressed: onPressed,
          text: text,
          minimumSize: const Size(360.0, 40.0),
        );
}
