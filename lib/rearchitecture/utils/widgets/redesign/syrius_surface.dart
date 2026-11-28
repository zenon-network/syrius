import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/extensions/buildcontext_extension.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/theming/syrius_theme_tokens.dart';

/// Standard crisp flat card surface matching the Syrius redesign language.
class SyriusCard extends StatelessWidget {
  /// Creates a [SyriusCard].
  const SyriusCard({
    required this.child,
    this.padding,
    this.borderRadius = 12,
    this.backgroundColor,
    this.borderColor,
    this.gradient,
    this.clipBehavior = Clip.antiAlias,
    super.key,
  });

  /// Content displayed inside the card.
  final Widget child;

  /// Optional internal padding around [child].
  final EdgeInsetsGeometry? padding;

  /// Corner radius in logical pixels.
  final double borderRadius;

  /// Optional override for the card surface color.
  final Color? backgroundColor;

  /// Optional override for the hairline border color.
  final Color? borderColor;

  /// Optional background gradient (overrides [backgroundColor] when set).
  final Gradient? gradient;

  /// Clipping behavior for rounded corners.
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    final SyriusThemeTokens tokens = context.syriusTheme;
    return Container(
      clipBehavior: clipBehavior,
      decoration: BoxDecoration(
        color: gradient == null ? (backgroundColor ?? tokens.surface) : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: borderColor ?? tokens.border),
      ),
      padding: padding,
      child: child,
    );
  }
}

/// Top full-width hero banner with subtle green-to-blue radial wash.
class SyriusHeroBanner extends StatelessWidget {
  /// Creates a [SyriusHeroBanner].
  const SyriusHeroBanner({
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
    super.key,
  });

  /// Content inside the hero banner.
  final Widget child;

  /// Inner padding around [child].
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final SyriusThemeTokens tokens = context.syriusTheme;
    return SyriusCard(
      gradient: tokens.heroBannerGradient,
      padding: padding,
      child: child,
    );
  }
}

/// Soft ambient multi-corner Zenon glow backdrop used on Lock, Welcome,
/// and Onboarding screens.
class SyriusAmbientBackdrop extends StatelessWidget {
  /// Creates a [SyriusAmbientBackdrop].
  const SyriusAmbientBackdrop({
    required this.child,
    this.showBrandHeader = true,
    super.key,
  });

  /// Foreground content positioned above the ambient glow.
  final Widget child;

  /// Whether to render the subtle top-left `S Y R I U S` wordmark bar.
  final bool showBrandHeader;

  @override
  Widget build(BuildContext context) {
    final SyriusThemeTokens tokens = context.syriusTheme;
    final bool isDark = context.isDarkMode;
    final Color baseBg = isDark
        ? const Color(0xFF141514)
        : const Color(0xFFECEEEC);

    return ColoredBox(
      color: baseBg,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(-0.75, -0.35),
                    radius: 0.95,
                    colors: <Color>[tokens.ambientGreen, Colors.transparent],
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.35, -0.8),
                    radius: 0.9,
                    colors: <Color>[tokens.ambientViolet, Colors.transparent],
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.7, 0.75),
                    radius: 1,
                    colors: <Color>[tokens.ambientBlue, Colors.transparent],
                  ),
                ),
              ),
            ),
          ),
          if (showBrandHeader)
            Positioned(
              top: 12,
              left: 16,
              child: IgnorePointer(
                child: Text(
                  'S Y R I U S',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 3.2,
                    color: tokens.textMuted,
                  ),
                ),
              ),
            ),
          child,
        ],
      ),
    );
  }
}

/// Compact vertical label + value metric column used in summary bars.
class SyriusMetricBlock extends StatelessWidget {
  /// Creates a [SyriusMetricBlock].
  const SyriusMetricBlock({
    required this.label,
    required this.value,
    this.valueSuffix,
    this.suffixColor,
    this.secondaryText,
    super.key,
  });

  /// Uppercase micro-label rendered above the value.
  final String label;

  /// Primary metric text rendered in tabular monospace.
  final String value;

  /// Optional ticker/unit suffix rendered next to [value].
  final String? valueSuffix;

  /// Color applied to [valueSuffix].
  final Color? suffixColor;

  /// Optional secondary muted annotation (e.g. fiat equivalent or note).
  final String? secondaryText;

  @override
  Widget build(BuildContext context) {
    final SyriusThemeTokens tokens = context.syriusTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(label.toUpperCase(), style: tokens.microLabelStyle()),
        const SizedBox(height: 5),
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: <Widget>[
            Text(
              value,
              style: tokens.monoStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: tokens.textPrimary,
              ),
            ),
            if (valueSuffix != null) ...<Widget>[
              const SizedBox(width: 5),
              Text(
                valueSuffix!,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: suffixColor ?? tokens.textSecondary,
                ),
              ),
            ],
            if (secondaryText != null) ...<Widget>[
              const SizedBox(width: 8),
              Text(
                secondaryText!,
                style: tokens.monoStyle(fontSize: 12, color: tokens.textMuted),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

/// Hairline horizontal divider themed with [SyriusThemeTokens.border].
class SyriusDivider extends StatelessWidget {
  /// Creates a [SyriusDivider].
  const SyriusDivider({this.height = 1, super.key});

  /// Total vertical extent of the divider.
  final double height;

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: height,
      thickness: 1,
      color: context.syriusTheme.border,
    );
  }
}
