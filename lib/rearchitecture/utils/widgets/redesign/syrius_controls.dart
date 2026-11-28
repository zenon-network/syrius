import 'package:flutter/foundation.dart';
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
    this.enabled = true,
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

  /// Whether user selection is enabled.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final SyriusThemeTokens tokens = context.syriusTheme;
    return Opacity(
      opacity: enabled ? 1.0 : 0.6,
      child: Container(
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
              cursor: enabled
                  ? SystemMouseCursors.click
                  : SystemMouseCursors.basic,
              child: GestureDetector(
                onTap: enabled ? () => onChanged(opt.value) : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 140),
                  padding: EdgeInsets.symmetric(
                    horizontal: compact ? 11 : 14,
                    vertical: compact ? 5 : 6,
                  ),
                  decoration: BoxDecoration(
                    color: isActive
                        ? tokens.surfaceElevated
                        : Colors.transparent,
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
                      color: isActive
                          ? tokens.textPrimary
                          : tokens.textSecondary,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
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
      child: SizedBox(width: 460, child: Row(children: children)),
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

/// Separated [ListView] with scroll-bottom and unfilled-viewport pagination
/// for paginated tables and activity feeds.
class SyriusPaginatedListView extends StatefulWidget {
  /// Creates a [SyriusPaginatedListView].
  const SyriusPaginatedListView({
    required this.itemCount,
    required this.itemBuilder,
    required this.hasReachedMax,
    required this.onLoadMore,
    this.isLoadingMore,
    this.dataIdentity,
    this.hasLoadMoreError = false,
    this.separatorBuilder,
    this.padding = EdgeInsets.zero,
    super.key,
  });

  /// Number of loaded data rows (excluding any bottom loading indicator).
  final int itemCount;

  /// Builds each data row at `index` in `[0, itemCount)`.
  final IndexedWidgetBuilder itemBuilder;

  /// Whether all pages have been fetched.
  final bool hasReachedMax;

  /// Dispatches the next page request when reaching the end of the list.
  final VoidCallback onLoadMore;

  /// Optional in-flight signal from the backing paginated BLoC so failed,
  /// filtered-empty, or discarded page requests reliably release the request
  /// guard when they settle.
  final ValueListenable<bool>? isLoadingMore;

  /// Optional backing data snapshot reference (e.g., `state.data`). Changes in
  /// identity release the request guard even when filtered [itemCount] and
  /// [hasReachedMax] stay unchanged.
  final Object? dataIdentity;

  /// Whether the most recent load-more request failed while keeping already
  /// loaded rows visible. When true, renders an inline retry footer instead of
  /// auto-looping retries.
  final bool hasLoadMoreError;

  /// Optional separator between rows. Defaults to a hairline [Divider].
  final IndexedWidgetBuilder? separatorBuilder;

  /// List padding.
  final EdgeInsetsGeometry padding;

  @override
  State<SyriusPaginatedListView> createState() =>
      _SyriusPaginatedListViewState();
}

class _SyriusPaginatedListViewState extends State<SyriusPaginatedListView> {
  final ScrollController _controller = ScrollController();
  bool _isRequesting = false;
  bool _wasLoadingMore = false;
  bool _dataChangedSinceRequest = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScroll);
    _wasLoadingMore = widget.isLoadingMore?.value ?? false;
    widget.isLoadingMore?.addListener(_onLoadingMoreChanged);
    _requestIfViewportUnfilled();
  }

  @override
  void didUpdateWidget(covariant SyriusPaginatedListView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isLoadingMore != widget.isLoadingMore) {
      oldWidget.isLoadingMore?.removeListener(_onLoadingMoreChanged);
      _wasLoadingMore = widget.isLoadingMore?.value ?? false;
      widget.isLoadingMore?.addListener(_onLoadingMoreChanged);
    }
    if (widget.hasLoadMoreError && !oldWidget.hasLoadMoreError) {
      _isRequesting = false;
    }
    final bool dataReplaced =
        widget.dataIdentity != null &&
        !identical(oldWidget.dataIdentity, widget.dataIdentity);
    final bool metricsChanged =
        oldWidget.itemCount != widget.itemCount ||
        oldWidget.hasReachedMax != widget.hasReachedMax;
    if (dataReplaced || metricsChanged) {
      _dataChangedSinceRequest = true;
      if (!(widget.isLoadingMore?.value ?? false)) {
        _isRequesting = false;
        _requestIfViewportUnfilled();
      }
    }
  }

  @override
  void dispose() {
    widget.isLoadingMore?.removeListener(_onLoadingMoreChanged);
    _controller.dispose();
    super.dispose();
  }

  void _onLoadingMoreChanged() {
    final bool loading = widget.isLoadingMore?.value ?? false;
    if (_wasLoadingMore && !loading) {
      // Request settled (success, failure, filtered-empty, or discarded).
      _isRequesting = false;
      final bool hadDataProgress = _dataChangedSinceRequest;
      _dataChangedSinceRequest = false;
      if (hadDataProgress) {
        _requestIfViewportUnfilled();
      }
    }
    _wasLoadingMore = loading;
  }

  void _onScroll() {
    if (!_controller.hasClients || widget.hasLoadMoreError) {
      return;
    }
    final ScrollPosition pos = _controller.position;
    if (pos.pixels >= pos.maxScrollExtent - 160) {
      _triggerLoadMore();
    }
  }

  void _requestIfViewportUnfilled() {
    if (widget.hasReachedMax || widget.hasLoadMoreError) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_controller.hasClients || widget.hasLoadMoreError) {
        return;
      }
      if (_controller.position.maxScrollExtent <= 0) {
        _triggerLoadMore();
      }
    });
  }

  void _triggerLoadMore() {
    if (_isRequesting ||
        (widget.isLoadingMore?.value ?? false) ||
        widget.hasReachedMax) {
      return;
    }
    _isRequesting = true;
    _dataChangedSinceRequest = false;
    try {
      widget.onLoadMore();
    } on Object {
      _isRequesting = false;
      rethrow;
    }
  }

  Widget _buildLoadMoreErrorFooter(
    BuildContext context,
    SyriusThemeTokens tokens,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(Icons.error_outline_rounded, size: 15, color: tokens.error),
          const SizedBox(width: 8),
          Text(
            context.l10n.somethingWentWrong,
            style: TextStyle(fontSize: 12.5, color: tokens.textSecondary),
          ),
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: _triggerLoadMore,
            icon: const Icon(Icons.refresh_rounded, size: 14),
            label: Text(context.l10n.retry),
            style: OutlinedButton.styleFrom(
              foregroundColor: tokens.textPrimary,
              side: BorderSide(color: tokens.borderStrong),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: const Size(0, 30),
              textStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final SyriusThemeTokens tokens = context.syriusTheme;
    final int totalCount = widget.itemCount + (widget.hasReachedMax ? 0 : 1);

    return ListView.separated(
      controller: _controller,
      padding: widget.padding,
      itemCount: totalCount,
      separatorBuilder:
          widget.separatorBuilder ??
          (_, _) => Divider(height: 1, color: tokens.border),
      itemBuilder: (BuildContext context, int index) {
        if (index >= widget.itemCount) {
          if (widget.isLoadingMore != null) {
            return ValueListenableBuilder<bool>(
              valueListenable: widget.isLoadingMore!,
              builder: (_, bool loading, _) {
                if (loading) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Center(
                      child: SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  );
                }
                if (widget.hasLoadMoreError) {
                  return _buildLoadMoreErrorFooter(context, tokens);
                }
                return const SizedBox(height: 16);
              },
            );
          }
          if (widget.hasLoadMoreError) {
            return _buildLoadMoreErrorFooter(context, tokens);
          }
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 14),
            child: Center(
              child: SizedBox.square(
                dimension: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          );
        }
        return widget.itemBuilder(context, index);
      },
    );
  }
}
