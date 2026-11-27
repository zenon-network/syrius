import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

/// Full-width [MyOutlinedButton] styled for wallet onboarding screens.
class OnboardingButton extends MyOutlinedButton {
  /// Creates an [OnboardingButton].
  const OnboardingButton({
    required super.onPressed,
    required String super.text,
    super.key,
  }) : super(
          minimumSize: const Size(360, 40),
        );
}
