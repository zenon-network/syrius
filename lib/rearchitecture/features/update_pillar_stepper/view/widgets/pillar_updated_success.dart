import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

/// Success action shown after a pillar has been updated.
class PillarUpdatedSuccess extends StatelessWidget {
  /// Creates a [PillarUpdatedSuccess].
  const PillarUpdatedSuccess({
    required this.onViewPillarsPressed,
    super.key,
  });

  /// Called when the user wants to return to the pillars view.
  final VoidCallback onViewPillarsPressed;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 20,
      right: 0,
      left: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          StepperButton(
            text: context.l10n.viewPillars,
            onPressed: onViewPillarsPressed,
          ),
        ],
      ),
    );
  }
}

/// Animated pillar success illustration.
class PillarUpdatedSuccessAnimation extends StatelessWidget {
  /// Creates a [PillarUpdatedSuccessAnimation].
  const PillarUpdatedSuccessAnimation({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 50,
      child: SizedBox(
        width: 400,
        height: 400,
        child: Center(
          child: Lottie.asset(
            'assets/lottie/ic_anim_pillar.json',
            repeat: false,
          ),
        ),
      ),
    );
  }
}
