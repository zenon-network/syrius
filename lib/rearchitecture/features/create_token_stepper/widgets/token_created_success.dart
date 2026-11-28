import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';

/// Success UI shown after a token has been created.
class TokenCreatedSuccess extends StatelessWidget {
  /// Creates a [TokenCreatedSuccess].
  const TokenCreatedSuccess({
    required this.onCreateAnotherTokenPressed,
    required this.onViewTokensPressed,
    this.tokenName,
    super.key,
  });

  /// Called when the user wants to create another token.
  final VoidCallback onCreateAnotherTokenPressed;

  /// Called when the user wants to return to the tokens view.
  final VoidCallback onViewTokensPressed;

  /// Optional name of the newly issued token.
  final String? tokenName;

  @override
  Widget build(BuildContext context) {
    final SyriusThemeTokens tokens = context.syriusTheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SizedBox.square(
              dimension: 160,
              child: Lottie.asset(
                'assets/lottie/ic_anim_zts.json',
                repeat: false,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              (tokenName != null && tokenName!.isNotEmpty)
                  ? tokenName!
                  : context.l10n.issueToken,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: tokens.textPrimary,
              ),
            ),
            const SizedBox(height: 22),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: <Widget>[
                SyriusGradientButton(
                  label: context.l10n.viewMyTokens,
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  onPressed: onViewTokensPressed,
                ),
                SyriusPillButton(
                  label: context.l10n.createAnotherToken,
                  height: 38,
                  onPressed: onCreateAnotherTokenPressed,
                ),
              ],
            ),
          ],
        ),
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
