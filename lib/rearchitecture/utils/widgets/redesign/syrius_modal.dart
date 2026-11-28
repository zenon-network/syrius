import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/extensions/buildcontext_extension.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/theming/syrius_theme_tokens.dart';

/// Shows a centered modal dialog over a softly blurred backdrop matching
/// Screens 05, 06, 12, and 27.
Future<T?> showSyriusBlurredDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  double maxWidth = 480,
}) {
  final SyriusThemeTokens tokens = context.syriusTheme;
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: tokens.modalBarrierColor,
    transitionDuration: const Duration(milliseconds: 160),
    pageBuilder:
        (
          BuildContext dialogContext,
          Animation<double> animation,
          Animation<double> secondaryAnimation,
        ) {
          return BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: maxWidth,
                  maxHeight: MediaQuery.sizeOf(dialogContext).height * 0.88,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: builder(dialogContext),
                ),
              ),
            ),
          );
        },
    transitionBuilder:
        (
          BuildContext context,
          Animation<double> animation,
          Animation<double> secondaryAnimation,
          Widget child,
        ) {
          final CurvedAnimation curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.97, end: 1).animate(curved),
              child: child,
            ),
          );
        },
  );
}

/// Framed modal surface with header bar, hairline divider, content, and
/// optional right-aligned footer actions.
class SyriusModalShell extends StatelessWidget {
  /// Creates a [SyriusModalShell].
  const SyriusModalShell({
    required this.title,
    required this.child,
    this.leadingIcon,
    this.leadingIconColor,
    this.headerTrailing,
    this.actions = const <Widget>[],
    this.showCloseButton = true,
    super.key,
  });

  /// Modal title.
  final String title;

  /// Main modal body.
  final Widget child;

  /// Optional icon rendered before [title].
  final IconData? leadingIcon;

  /// Optional tint for [leadingIcon].
  final Color? leadingIconColor;

  /// Optional widget rendered before the close icon (e.g. `How it works`).
  final Widget? headerTrailing;

  /// Footer action buttons.
  final List<Widget> actions;

  /// Whether to render the top-right close button.
  final bool showCloseButton;

  @override
  Widget build(BuildContext context) {
    final SyriusThemeTokens tokens = context.syriusTheme;
    return Container(
      decoration: BoxDecoration(
        color: tokens.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tokens.border),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 32,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 12, 14),
            child: Row(
              children: <Widget>[
                if (leadingIcon != null) ...<Widget>[
                  Icon(
                    leadingIcon,
                    size: 18,
                    color: leadingIconColor ?? tokens.znnGreen,
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: tokens.textPrimary,
                    ),
                  ),
                ),
                ?headerTrailing,
                if (showCloseButton)
                  IconButton(
                    iconSize: 17,
                    splashRadius: 16,
                    color: tokens.textMuted,
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
              ],
            ),
          ),
          Divider(height: 1, color: tokens.border),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
              child: child,
            ),
          ),
          if (actions.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 18),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  for (int i = 0; i < actions.length; i++) ...<Widget>[
                    if (i > 0) const SizedBox(width: 10),
                    actions[i],
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Crisp two-column metadata row (`LABEL` on left, value widget on right).
class SyriusKeyValueRow extends StatelessWidget {
  /// Creates a [SyriusKeyValueRow].
  const SyriusKeyValueRow({
    required this.label,
    required this.value,
    this.labelWidth = 90,
    super.key,
  });

  /// Micro uppercase key label.
  final String label;

  /// Value widget displayed beside [label].
  final Widget value;

  /// Fixed width for the left label column so rows align cleanly.
  final double labelWidth;

  @override
  Widget build(BuildContext context) {
    final SyriusThemeTokens tokens = context.syriusTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: labelWidth,
            child: Text(label.toUpperCase(), style: tokens.microLabelStyle()),
          ),
          const SizedBox(width: 10),
          Expanded(child: value),
        ],
      ),
    );
  }
}
