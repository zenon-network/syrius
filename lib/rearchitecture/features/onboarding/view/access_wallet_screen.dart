import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';

/// Welcome screen letting the user create, import, or connect a hardware
/// wallet (Screen 44).
class AccessWalletScreen extends StatelessWidget {
  /// Creates an [AccessWalletScreen].
  const AccessWalletScreen({super.key});

  /// Named route for [AccessWalletScreen].
  static const String route = 'access-wallet-screen';

  @override
  Widget build(BuildContext context) {
    return const _View();
  }
}

class _View extends StatelessWidget {
  const _View();

  @override
  Widget build(BuildContext context) {
    final SyriusThemeTokens tokens = context.syriusTheme;

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
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 920),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      SizedBox.square(
                        dimension: 340,
                        child: Lottie.asset(
                          'assets/lottie/ic_anim_welcome.json',
                          repeat: false,
                          errorBuilder: (_, _, _) => Icon(
                            Icons.public,
                            size: 160,
                            color: tokens.znnGreen.withValues(alpha: 0.4),
                          ),
                        ),
                      ),
                      const SizedBox(width: 56),
                      Expanded(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 400),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Text(
                                context.l10n.welcome,
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  color: tokens.textPrimary,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                context.l10n.selectOptionToAccessWallet,
                                style: TextStyle(
                                  fontSize: 13.5,
                                  color: tokens.textSecondary,
                                ),
                              ),
                              const SizedBox(height: 24),
                              _WelcomeOptionTile(
                                title: context.l10n.createWallet,
                                subtitle: context.l10n.twelveOrTwentyFourWords,
                                icon: Icons.add,
                                highlight: true,
                                onTap: () => NavigationUtils.push(
                                  context,
                                  const NewWalletSeedChoiceScreen(
                                    export: false,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              _WelcomeOptionTile(
                                title: context.l10n.importWallet,
                                subtitle:
                                    context.l10n.inputSeedOrImportSeedVault,
                                icon: Icons.description_outlined,
                                onTap: () => NavigationUtils.push(
                                  context,
                                  const ImportWalletSeedChoiceScreen(),
                                ),
                              ),
                              const SizedBox(height: 12),
                              _WelcomeOptionTile(
                                title: context.l10n.hardwareWallet,
                                subtitle: 'Ledger',
                                icon: Icons.usb_rounded,
                                onTap: () => NavigationUtils.push(
                                  context,
                                  const HardwareWalletDeviceChoiceScreen(),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
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

class _WelcomeOptionTile extends StatefulWidget {
  const _WelcomeOptionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    this.highlight = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final bool highlight;

  @override
  State<_WelcomeOptionTile> createState() => _WelcomeOptionTileState();
}

class _WelcomeOptionTileState extends State<_WelcomeOptionTile> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final SyriusThemeTokens tokens = context.syriusTheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: _hovered ? tokens.surfaceElevated : tokens.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _hovered ? tokens.borderStrong : tokens.border,
            ),
          ),
          child: Row(
            children: <Widget>[
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: widget.highlight ? tokens.primaryGradient : null,
                  color: widget.highlight ? null : tokens.surfaceSubtle,
                  border: widget.highlight
                      ? null
                      : Border.all(color: tokens.border),
                ),
                child: Icon(
                  widget.icon,
                  size: 19,
                  color: widget.highlight
                      ? tokens.gradientButtonForeground
                      : tokens.textSecondary,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: tokens.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: tokens.textMuted),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: tokens.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
