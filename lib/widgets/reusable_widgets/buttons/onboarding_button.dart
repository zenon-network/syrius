import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

/// Pill CTA button styled for wallet onboarding screens.
class OnboardingButton extends MyOutlinedButton {
  /// Creates an [OnboardingButton].
  const OnboardingButton({
    required super.onPressed,
    required String super.text,
    super.key,
  }) : super(minimumSize: const Size(160, 42));

  @override
  MyOutlinedButtonState createState() => _OnboardingButtonState();
}

class _OnboardingButtonState extends MyOutlinedButtonState {
  @override
  Widget build(BuildContext context) {
    return SyriusGradientButton(
      label: widget.text ?? '',
      height: widget.minimumSize?.height ?? 42,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      onPressed: widget.onPressed,
    );
  }
}
