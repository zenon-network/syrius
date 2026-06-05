import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:lottie/lottie.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';

/// Success UI shown after a pillar has been registered.
class PillarRegisteredSuccess extends StatelessWidget {
  /// Creates a [PillarRegisteredSuccess].
  const PillarRegisteredSuccess({
    required this.onRegisterAnotherPressed,
    required this.onViewPillarsPressed,
    super.key,
  });

  /// Called when the user wants to register another pillar.
  final VoidCallback onRegisterAnotherPressed;

  /// Called when the user wants to return to the pillars view.
  final VoidCallback onViewPillarsPressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        _SuccessMessage(
          onControllerPressed: () {
            unawaited(NavigationUtils.openUrl(kZnnController));
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SizedBox(
              width: 250,
              child: _RegisterAnotherButton(
                onPressed: onRegisterAnotherPressed,
              ),
            ),
            const SizedBox(width: 80),
            SizedBox(
              width: 250,
              child: _ViewPillarsButton(
                onPressed: onViewPillarsPressed,
              ),
            ),
          ],
        ),
        Container(height: 20),
      ],
    );
  }
}

/// Animated pillar success illustration.
class PillarRegisteredSuccessAnimation extends StatelessWidget {
  /// Creates a [PillarRegisteredSuccessAnimation].
  const PillarRegisteredSuccessAnimation({super.key});

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

class _SuccessMessage extends StatelessWidget {
  const _SuccessMessage({required this.onControllerPressed});

  final VoidCallback onControllerPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 50),
      margin: const EdgeInsets.symmetric(vertical: 20, horizontal: 50),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: const BorderRadius.all(Radius.circular(10)),
      ),
      child: RichText(
        textAlign: TextAlign.center,
        text: TextSpan(
          style: Theme.of(context).textTheme.titleMedium,
          children: <InlineSpan>[
            TextSpan(
              text: '${context.l10n.pillar} ',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            TextSpan(
              text: context.l10n.successfully,
              style: Theme.of(context).textTheme.titleMedium!.copyWith(
                color: AppColors.znnColor,
              ),
            ),
            TextSpan(
              text: context.l10n.registeredUse,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            TextSpan(
              text: context.l10n.znnController,
              style: Theme.of(context).textTheme.titleMedium!.copyWith(
                color: AppColors.znnColor,
                decoration: TextDecoration.underline,
              ),
              recognizer: TapGestureRecognizer()..onTap = onControllerPressed,
            ),
            const WidgetSpan(
              child: Icon(
                MaterialCommunityIcons.link,
                size: 20,
                color: AppColors.znnColor,
              ),
            ),
            TextSpan(
              text: context.l10n.checkPillarStatus,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _RegisterAnotherButton extends StatelessWidget {
  const _RegisterAnotherButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      label: Text(context.l10n.registerAnotherPillar),
      onPressed: onPressed,
      icon: const Icon(Icons.refresh, color: Colors.white),
      iconAlignment: .end,
    );
  }
}

class _ViewPillarsButton extends StatelessWidget {
  const _ViewPillarsButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      label: Text(context.l10n.viewPillars),
      onPressed: onPressed,
      icon: const Icon(MaterialCommunityIcons.pillar, color: Colors.white),
      iconAlignment: .end,
    );
  }
}
