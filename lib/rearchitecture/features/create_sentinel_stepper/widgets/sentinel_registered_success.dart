import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:lottie/lottie.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';

/// Success UI shown after a sentinel has been registered.
class SentinelRegisteredSuccess extends StatelessWidget {
  /// Creates a [SentinelRegisteredSuccess].
  const SentinelRegisteredSuccess({
    required this.onViewSentinelsPressed,
    super.key,
  });

  /// Called when the user wants to return to the sentinels view.
  final VoidCallback onViewSentinelsPressed;

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
              child: _ViewSentinelsButton(
                onPressed: onViewSentinelsPressed,
              ),
            ),
          ],
        ),
        Container(height: 20),
      ],
    );
  }
}

/// Animated sentinel success illustration.
class SentinelRegisteredSuccessAnimation extends StatelessWidget {
  /// Creates a [SentinelRegisteredSuccessAnimation].
  const SentinelRegisteredSuccessAnimation({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 50,
      child: SizedBox(
        width: 400,
        height: 400,
        child: Center(
          child: Lottie.asset(
            'assets/lottie/ic_anim_sentinel.json',
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
              text: '${context.l10n.sentinel} ',
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
              text: context.l10n.checkSentinelStatus,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _ViewSentinelsButton extends StatelessWidget {
  const _ViewSentinelsButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      label: Text(context.l10n.viewSentinels),
      onPressed: onPressed,
      icon: const Icon(
        MaterialCommunityIcons.eye_outline,
        color: Colors.white,
      ),
      iconAlignment: .end,
    );
  }
}
