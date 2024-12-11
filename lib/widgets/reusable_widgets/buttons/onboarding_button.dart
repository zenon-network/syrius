import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

class OnboardingButton extends MyOutlinedButton {
  const OnboardingButton({
    required super.onPressed,
    required String super.text,
    super.key,
  }) : super(
          minimumSize: const Size(360, 40),
        );
}
