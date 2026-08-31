import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';

/// Success UI shown after a token has been created.
class TokenCreatedSuccess extends StatelessWidget {
  /// Creates a [TokenCreatedSuccess].
  const TokenCreatedSuccess({
    required this.onCreateAnotherTokenPressed,
    required this.onViewTokensPressed,
    super.key,
  });

  /// Called when the user wants to create another token.
  final VoidCallback onCreateAnotherTokenPressed;

  /// Called when the user wants to return to the tokens view.
  final VoidCallback onViewTokensPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: 50,
        bottom: 20,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          OutlinedButton.icon(
            label: Text(context.l10n.createAnotherToken),
            onPressed: onCreateAnotherTokenPressed,
            icon: const Icon(Icons.refresh, color: Colors.white,),
            iconAlignment: .end,
          ),
          const SizedBox(
            width: 80,
          ),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.ztsColor,
              side: const BorderSide(color: AppColors.ztsColor),
            ),
            onPressed: onViewTokensPressed,
            child: Text(context.l10n.viewMyTokens),
          ),
        ],
      ),
    );
  }
}

/// Animated token success illustration.
class TokenCreatedSuccessAnimation extends StatelessWidget {
  /// Creates a [TokenCreatedSuccessAnimation].
  const TokenCreatedSuccessAnimation({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 50,
      child: SizedBox(
        width: 400,
        height: 400,
        child: Center(
          child: Lottie.asset(
            'assets/lottie/ic_anim_zts.json',
            repeat: false,
          ),
        ),
      ),
    );
  }
}
