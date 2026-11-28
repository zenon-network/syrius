import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

/// Final onboarding screen matching mockup Screen 47.
class WalletSuccessScreen extends StatelessWidget {
  /// Creates a [WalletSuccessScreen].
  const WalletSuccessScreen({this._progressBarNumLevels = 5, super.key});

  final int _progressBarNumLevels;

  @override
  Widget build(BuildContext context) {
    return _View(progressBarNumLevels: _progressBarNumLevels);
  }
}

class _View extends StatelessWidget {
  const _View({required this._progressBarNumLevels});

  final int _progressBarNumLevels;

  @override
  Widget build(BuildContext context) {
    final SyriusThemeTokens tokens = context.syriusTheme;
    final String? firstAddress = kSelectedAddress;

    return Scaffold(
      body: SyriusAmbientBackdrop(
        child: Stack(
          children: <Widget>[
            Positioned(
              top: 16,
              left: 18,
              child: Text(
                'S Y R I U S',
                style: TextStyle(
                  fontSize: 11,
                  letterSpacing: 3.5,
                  color: tokens.textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                child: Opacity(
                  opacity: 0.35,
                  child: Center(
                    child: Lottie.asset(
                      'assets/lottie/ic_anim_map.json',
                      fit: BoxFit.contain,
                      errorBuilder: (_, _, _) => const SizedBox.shrink(),
                    ),
                  ),
                ),
              ),
            ),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 540),
                  child: SyriusCard(
                    borderRadius: 14,
                    padding: const EdgeInsets.all(28),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        SyriusHorizontalStepper(
                          steps: <String>[
                            context.l10n.seed,
                            context.l10n.confirm,
                            context.l10n.password,
                            context.l10n.ready,
                          ],
                          currentStep: _progressBarNumLevels,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          context.l10n.youAreAllSet,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: tokens.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          context.l10n.walletSuccessfullyCreated,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: tokens.textSecondary,
                          ),
                        ),
                        if (firstAddress != null &&
                            firstAddress.isNotEmpty) ...<Widget>[
                          const SizedBox(height: 20),
                          Text(
                            context.l10n.addressNumber(1).toUpperCase(),
                            textAlign: TextAlign.center,
                            style: tokens.microLabelStyle(),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Flexible(
                                child: Text(
                                  firstAddress,
                                  overflow: TextOverflow.ellipsis,
                                  style: tokens.monoStyle(
                                    fontSize: 12.5,
                                    color: tokens.textPrimary,
                                  ),
                                ),
                              ),
                              CopyToClipboardButton(firstAddress),
                            ],
                          ),
                        ],
                        const SizedBox(height: 24),
                        OnboardingButton(
                          onPressed: () {
                            Navigator.popUntil(
                              context,
                              ModalRoute.withName(AccessWalletScreen.route),
                            );
                            NavigationUtils.pushReplacement(
                              context,
                              const MainAppContainer(
                                redirectedFromWalletSuccess: true,
                              ),
                            );
                          },
                          text: context.l10n.accessWallet,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
