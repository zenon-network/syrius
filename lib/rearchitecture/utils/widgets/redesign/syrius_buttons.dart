import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/extensions/buildcontext_extension.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/theming/syrius_theme_tokens.dart';

/// Primary pill CTA button using the signature Zenon green-to-blue gradient.
class SyriusGradientButton extends StatelessWidget {
  /// Creates a [SyriusGradientButton].
  const SyriusGradientButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.expanded = false,
    this.height = 40,
    this.padding = const EdgeInsets.symmetric(horizontal: 20),
    this.fontSize = 13.5,
    super.key,
  });

  /// Text label inside the pill button.
  final String label;

  /// Callback when pressed, or `null` when disabled.
  final VoidCallback? onPressed;

  /// Optional leading icon.
  final IconData? icon;

  /// Displays a compact spinner instead of [label] while true.
  final bool isLoading;

  /// Whether the button expands to fill available horizontal width.
  final bool expanded;

  /// Fixed height of the pill button.
  final double height;

  /// Horizontal inner padding.
  final EdgeInsetsGeometry padding;

  /// Font size of [label].
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final SyriusThemeTokens tokens = context.syriusTheme;
    final bool enabled = onPressed != null && !isLoading;

    final Widget content = Row(
      mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        if (isLoading)
          SizedBox.square(
            dimension: 15,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                tokens.gradientButtonForeground,
              ),
            ),
          )
        else ...<Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 16, color: tokens.gradientButtonForeground),
            const SizedBox(width: 7),
          ],
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w600,
                color: tokens.gradientButtonForeground,
              ),
            ),
          ),
        ],
      ],
    );

    return Opacity(
      opacity: enabled ? 1 : 0.48,
      child: Material(
        color: Colors.transparent,
        child: Ink(
          height: height,
          width: expanded ? double.infinity : null,
          decoration: BoxDecoration(
            gradient: tokens.primaryGradient,
            borderRadius: BorderRadius.circular(999),
          ),
          child: InkWell(
            onTap: enabled ? onPressed : null,
            borderRadius: BorderRadius.circular(999),
            mouseCursor: enabled
                ? SystemMouseCursors.click
                : SystemMouseCursors.forbidden,
            child: Padding(
              padding: padding,
              child: Center(child: content),
            ),
          ),
        ),
      ),
    );
  }
}

/// Secondary neutral pill button used for card actions, table actions,
/// cancel controls, and toggles.
class SyriusPillButton extends StatelessWidget {
  /// Creates a [SyriusPillButton].
  const SyriusPillButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.trailingIcon,
    this.isLoading = false,
    this.compact = false,
    this.destructive = false,
    this.highlighted = false,
    this.height,
    this.padding,
    super.key,
  });

  /// Button text label.
  final String label;

  /// Callback when pressed, or `null` when disabled.
  final VoidCallback? onPressed;

  /// Optional leading icon.
  final IconData? icon;

  /// Optional trailing icon (e.g. dropdown chevron).
  final IconData? trailingIcon;

  /// Displays a compact loading spinner while true.
  final bool isLoading;

  /// Uses smaller height and horizontal padding for dense table rows.
  final bool compact;

  /// Uses destructive error text styling.
  final bool destructive;

  /// Highlights the border/tint subtly for selected filter chips.
  final bool highlighted;

  /// Optional explicit height override.
  final double? height;

  /// Optional explicit padding override.
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final SyriusThemeTokens tokens = context.syriusTheme;
    final bool enabled = onPressed != null && !isLoading;
    final double resolvedHeight = height ?? (compact ? 29 : 36);
    final EdgeInsetsGeometry resolvedPadding =
        padding ?? EdgeInsets.symmetric(horizontal: compact ? 12 : 16);

    final Color fgColor = destructive
        ? tokens.error
        : enabled
        ? tokens.textPrimary
        : tokens.textMuted;

    final Color bgColor = highlighted
        ? tokens.surfaceElevated
        : enabled
        ? tokens.surfaceElevated
        : tokens.surfaceSubtle;

    final Color borderColor = highlighted ? tokens.borderStrong : tokens.border;

    return Material(
      color: Colors.transparent,
      child: Ink(
        height: resolvedHeight,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: borderColor),
        ),
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(999),
          mouseCursor: enabled
              ? SystemMouseCursors.click
              : SystemMouseCursors.forbidden,
          child: Padding(
            padding: resolvedPadding,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                if (isLoading)
                  SizedBox.square(
                    dimension: 13,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.8,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        tokens.znnGreen,
                      ),
                    ),
                  )
                else ...<Widget>[
                  if (icon != null) ...<Widget>[
                    Icon(icon, size: compact ? 13.5 : 15, color: fgColor),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: compact ? 12 : 13,
                      fontWeight: FontWeight.w500,
                      color: fgColor,
                    ),
                  ),
                  if (trailingIcon != null) ...<Widget>[
                    const SizedBox(width: 5),
                    Icon(
                      trailingIcon,
                      size: compact ? 14 : 15,
                      color: tokens.textSecondary,
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Borderless inline ghost text/icon action button (e.g. `Rewards`,
/// `explorer`, `Disconnect`, `What changed`, `< Back`).
class SyriusGhostButton extends StatelessWidget {
  /// Creates a [SyriusGhostButton].
  const SyriusGhostButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.color,
    this.fontSize = 12.5,
    super.key,
  });

  /// Button text.
  final String label;

  /// Tap callback.
  final VoidCallback? onPressed;

  /// Optional leading icon.
  final IconData? icon;

  /// Optional foreground color override.
  final Color? color;

  /// Font size for [label].
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final SyriusThemeTokens tokens = context.syriusTheme;
    final Color fg = color ?? tokens.textSecondary;
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(8),
      mouseCursor: onPressed != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (icon != null) ...<Widget>[
              Icon(icon, size: fontSize + 1.5, color: fg),
              const SizedBox(width: 5),
            ],
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w500,
                  color: fg,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
