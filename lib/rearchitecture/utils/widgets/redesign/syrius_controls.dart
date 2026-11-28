import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/extensions/buildcontext_extension.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/theming/syrius_theme_tokens.dart';

/// Semantic tone for [SyriusStatusBadge].
enum SyriusBadgeTone {
  /// Neutral gray pill.
  neutral,

  /// Green positive / active / unlocked pill.
  success,

  /// Blue countdown / momentum / waiting pill.
  info,

  /// Amber warning / needs vote pill.
  warning,

  /// Red down / error / failed pill.
  error,

  /// Magenta release version pill.
  release,
}

/// Compact pill status badge used across tables, headers, and settings.
class SyriusStatusBadge extends StatelessWidget {
  /// Creates a [SyriusStatusBadge].
  const SyriusStatusBadge({
    required this.label,
    this.tone = SyriusBadgeTone.neutral,
    this.icon,
    this.leadingDot = false,
    super.key,
  });

  /// Short status label text.
  final String label;

  /// Semantic visual tone.
  final SyriusBadgeTone tone;

  /// Optional leading icon inside the pill.
  final IconData? icon;

  /// Shows a compact circular status dot before [label].
  final bool leadingDot;

  @override
  Widget build(BuildContext context) {
    final SyriusThemeTokens tokens = context.syriusTheme;
    final (Color bg, Color fg, Color? borderColor) = switch (tone) {
      SyriusBadgeTone.neutral => (
        tokens.surfaceElevated,
        tokens.textSecondary,
        tokens.border,
      ),
      SyriusBadgeTone.success => (
        tokens.successSurface,
        tokens.successForeground,
        null,
      ),
      SyriusBadgeTone.info => (tokens.infoSurface, tokens.infoForeground, null),
      SyriusBadgeTone.warning => (
        tokens.warningSurface,
        tokens.warning,
        tokens.warningBorder,
      ),
      SyriusBadgeTone.error => (
        tokens.errorSurface,
        tokens.error,
        tokens.errorBorder,
      ),
      SyriusBadgeTone.release => (
        tokens.releaseSurface,
        tokens.releaseForeground,
        null,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: borderColor != null ? Border.all(color: borderColor) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (leadingDot) ...<Widget>[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
          ],
          if (icon != null) ...<Widget>[
            Icon(icon, size: 12.5, color: fg),
            const SizedBox(width: 5),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: fg,
              fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

/// Option entry for [SyriusSegmentedControl].
class SyriusSegmentOption<T> {
  /// Creates a [SyriusSegmentOption].
  const SyriusSegmentOption({required this.value, required this.label});

  /// Underlying value associated with this segment.
  final T value;

  /// Display text rendered inside the segment pill.
  final String label;
}

/// Pill-track segmented control used for Send/Receive/Zap, filters, and
/// settings multi-choice rows.
class SyriusSegmentedControl<T> extends StatelessWidget {
  /// Creates a [SyriusSegmentedControl].
  const SyriusSegmentedControl({
    required this.options,
    required this.selected,
    required this.onChanged,
    this.compact = false,
    super.key,
  });

  /// Ordered list of segment options.
  final List<SyriusSegmentOption<T>> options;

  /// Currently active value.
  final T selected;

  /// Callback fired when the user picks a segment.
  final ValueChanged<T> onChanged;

  /// Compact height for dense toolbars and settings rows.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final SyriusThemeTokens tokens = context.syriusTheme;
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: tokens.surfaceSubtle,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: tokens.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: options.map((SyriusSegmentOption<T> opt) {
          final bool isActive = opt.value == selected;
          return MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              onTap: () => onChanged(opt.value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 140),
                padding: EdgeInsets.symmetric(
                  horizontal: compact ? 11 : 14,
                  vertical: compact ? 5 : 6,
                ),
                decoration: BoxDecoration(
                  color: isActive ? tokens.surfaceElevated : Colors.transparent,
                  borderRadius: BorderRadius.circular(999),
                  border: isActive
                      ? Border.all(color: tokens.borderStrong)
                      : Border.all(color: Colors.transparent),
                ),
                child: Text(
                  opt.label,
                  style: TextStyle(
                    fontSize: compact ? 12 : 12.5,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                    color: isActive ? tokens.textPrimary : tokens.textSecondary,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// Circular token avatar badge (`Z` green, `Q` blue, or initial for ZTS).
class SyriusTokenAvatar extends StatelessWidget {
  /// Creates a [SyriusTokenAvatar].
  const SyriusTokenAvatar({
    required this.symbol,
    this.color,
    this.size = 24,
    super.key,
  });

  /// Token symbol whose first character is displayed.
  final String symbol;

  /// Optional explicit circle color.
  final Color? color;

  /// Diameter in logical pixels.
  final double size;

  @override
  Widget build(BuildContext context) {
    final SyriusThemeTokens tokens = context.syriusTheme;
    final String upper = symbol.trim().toUpperCase();
    final Color bg =
        color ??
        switch (upper) {
          'ZNN' => tokens.znnGreen,
          'QSR' => tokens.qsrBlue,
          _ => tokens.ztsMagenta,
        };
    final String initial = upper.isNotEmpty ? upper[0] : '?';
    final bool darkText = upper == 'ZNN';

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Text(
        initial,
        style: TextStyle(
          fontSize: size * 0.48,
          fontWeight: FontWeight.w700,
          color: darkText ? const Color(0xFF09130D) : Colors.white,
        ),
      ),
    );
  }
}

/// Sleek horizontal plasma fill bar matching the Home and Plasma screens.
class SyriusPlasmaBar extends StatelessWidget {
  /// Creates a [SyriusPlasmaBar].
  const SyriusPlasmaBar({
    required this.progress,
    this.width,
    this.height = 5,
    super.key,
  });

  /// Normalized plasma fraction between `0.0` and `1.0`.
  final double progress;

  /// Optional explicit bar width.
  final double? width;

  /// Bar thickness in logical pixels.
  final double height;

  @override
  Widget build(BuildContext context) {
    final SyriusThemeTokens tokens = context.syriusTheme;
    final double clamped = progress.clamp(0.0, 1.0);
    return Container(
      width: width,
      height: height,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: tokens.border,
        borderRadius: BorderRadius.circular(999),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: clamped,
        child: Container(
          decoration: BoxDecoration(
            color: tokens.qsrBlue,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
    );
  }
}

/// Compact search input styled for table headers (Pillars, Tokens, AZ).
class SyriusSearchField extends StatelessWidget {
  /// Creates a [SyriusSearchField].
  const SyriusSearchField({
    required this.controller,
    required this.hintText,
    required this.onChanged,
    this.width = 220,
    super.key,
  });

  /// Text controller for the search query.
  final TextEditingController controller;

  /// Placeholder hint text.
  final String hintText;

  /// Callback triggered as the user types.
  final ValueChanged<String> onChanged;

  /// Optional width constraint.
  final double width;

  @override
  Widget build(BuildContext context) {
    final SyriusThemeTokens tokens = context.syriusTheme;
    return SizedBox(
      width: width,
      height: 34,
      child: ValueListenableBuilder<TextEditingValue>(
        valueListenable: controller,
        builder: (_, TextEditingValue val, _) {
          return TextField(
            controller: controller,
            onChanged: onChanged,
            style: TextStyle(fontSize: 12.5, color: tokens.textPrimary),
            decoration: InputDecoration(
              isDense: true,
              filled: true,
              fillColor: tokens.surfaceSubtle,
              hintText: hintText,
              hintStyle: TextStyle(fontSize: 12.5, color: tokens.textMuted),
              prefixIcon: Icon(Icons.search, size: 16, color: tokens.textMuted),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 34,
                minHeight: 34,
              ),
              suffixIcon: val.text.isNotEmpty
                  ? IconButton(
                      padding: EdgeInsets.zero,
                      iconSize: 14,
                      onPressed: () {
                        controller.clear();
                        onChanged('');
                      },
                      icon: Icon(Icons.close, color: tokens.textMuted),
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(9),
                borderSide: BorderSide(color: tokens.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(9),
                borderSide: BorderSide(color: tokens.borderStrong),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Centered empty-list state using the classic Zenon no-data animation.
class SyriusEmptyState extends StatelessWidget {
  /// Creates a [SyriusEmptyState].
  const SyriusEmptyState({
    required this.message,
    this.subtitle,
    this.compact = false,
    super.key,
  });

  /// Primary muted empty state label (e.g. `None yet`).
  final String message;

  /// Optional secondary explanation.
  final String? subtitle;

  /// Reduces vertical padding for small cards.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final SyriusThemeTokens tokens = context.syriusTheme;
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          vertical: compact ? 20 : 48,
          horizontal: 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SizedBox.square(
              dimension: compact ? 28 : 40,
              child: Lottie.asset(
                'assets/lottie/ic_anim_no_data.json',
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => Icon(
                  Icons.do_not_disturb_alt_outlined,
                  size: compact ? 24 : 32,
                  color: tokens.znnGreen,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: tokens.textMuted),
            ),
            if (subtitle != null) ...<Widget>[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: tokens.textMuted),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Horizontal numbered step progress indicator used across Onboarding cards
/// (Screens 45–47).
class SyriusHorizontalStepper extends StatelessWidget {
  /// Creates a [SyriusHorizontalStepper].
  const SyriusHorizontalStepper({
    required this.steps,
    required this.currentStep,
    super.key,
  });

  /// Ordered step labels (e.g. `['Seed', 'Confirm', 'Password', 'Ready']`).
  final List<String> steps;

  /// Zero-based active step index. Steps `< currentStep` render as completed;
  /// when `currentStep >= steps.length`, all steps render completed.
  final int currentStep;

  @override
  Widget build(BuildContext context) {
    final SyriusThemeTokens tokens = context.syriusTheme;
    final List<Widget> children = <Widget>[];
    for (int i = 0; i < steps.length; i++) {
      final bool completed = i < currentStep;
      final bool active = i == currentStep;
      children.add(
        Flexible(
          flex: 0,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: completed ? tokens.znnGreen : Colors.transparent,
                  border: Border.all(
                    color: completed || active
                        ? tokens.znnGreen
                        : tokens.border,
                    width: 1.4,
                  ),
                ),
                child: completed
                    ? Icon(
                        Icons.check,
                        size: 13,
                        color: tokens.gradientButtonForeground,
                      )
                    : Text(
                        '${i + 1}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: active ? tokens.znnGreen : tokens.textMuted,
                        ),
                      ),
              ),
              const SizedBox(width: 6),
              Text(
                steps[i],
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                  color: active ? tokens.textPrimary : tokens.textMuted,
                ),
              ),
            ],
          ),
        ),
      );
      if (i < steps.length - 1) {
        children.add(
          Expanded(
            child: Container(
              height: 1,
              margin: const EdgeInsets.symmetric(horizontal: 6),
              color: completed
                  ? tokens.znnGreen.withValues(alpha: 0.45)
                  : tokens.border,
            ),
          ),
        );
      }
    }
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: SizedBox(
        width: 460,
        child: Row(children: children),
      ),
    );
  }
}

/// Vertical step rail used on split-pane creation flows (Spawn Pillar,
/// Create Token, Screens 19, 20, 25).
class SyriusVerticalStepRail extends StatelessWidget {
  /// Creates a [SyriusVerticalStepRail].
  const SyriusVerticalStepRail({
    required this.steps,
    required this.currentStep,
    this.summaryRows = const <Widget>[],
    this.footer,
    super.key,
  });

  /// Step titles.
  final List<String> steps;

  /// Zero-based active step index (or `steps.length` when all complete).
  final int currentStep;

  /// Optional key-value summary widgets displayed below a hairline divider.
  final List<Widget> summaryRows;

  /// Optional footer card (e.g. token preview).
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final SyriusThemeTokens tokens = context.syriusTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        for (int i = 0; i < steps.length; i++) ...<Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i < currentStep ? tokens.znnGreen : Colors.transparent,
                  border: Border.all(
                    color: i <= currentStep ? tokens.znnGreen : tokens.border,
                    width: 1.4,
                  ),
                ),
                child: i < currentStep
                    ? Icon(
                        Icons.check,
                        size: 13,
                        color: tokens.gradientButtonForeground,
                      )
                    : Text(
                        '${i + 1}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: i == currentStep
                              ? tokens.znnGreen
                              : tokens.textMuted,
                        ),
                      ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  steps[i],
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: i == currentStep
                        ? FontWeight.w600
                        : FontWeight.w400,
                    color: i == currentStep
                        ? tokens.textPrimary
                        : tokens.textMuted,
                  ),
                ),
              ),
            ],
          ),
          if (i < steps.length - 1) const SizedBox(height: 16),
        ],
        if (summaryRows.isNotEmpty) ...<Widget>[
          const SizedBox(height: 20),
          Divider(height: 1, color: tokens.border),
          const SizedBox(height: 16),
          ...summaryRows,
        ],
        if (footer != null) ...<Widget>[const SizedBox(height: 16), footer!],
      ],
    );
  }
}
