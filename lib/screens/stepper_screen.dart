import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/notifications/notifications.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/extensions/buildcontext_extension.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/theming/syrius_theme_tokens.dart';

/// Screen scaffold that displays a stepper widget alongside notifications.
class StepperScreen extends StatelessWidget {
  /// Creates a [StepperScreen].
  const StepperScreen({
    required this.stepper,
    required this.onStepperNotificationSeeMorePressed,
    this.breadcrumbParent,
    this.title,
    super.key,
  });

  /// Callback invoked when the user presses "See more" on a notification.
  final VoidCallback onStepperNotificationSeeMorePressed;

  /// The stepper widget displayed inside the card body.
  final Widget stepper;

  /// Optional parent section breadcrumb shown beside the back arrow.
  final String? breadcrumbParent;

  /// Optional flow title shown beside [breadcrumbParent].
  final String? title;

  @override
  Widget build(BuildContext context) {
    final SyriusThemeTokens tokens = context.syriusTheme;
    return Theme(
      data: context.newThemeData,
      child: Scaffold(
        backgroundColor: tokens.shellBackground,
        body: Container(
          margin: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              NotificationWidget(
                onSeeMorePressed: onStepperNotificationSeeMorePressed,
              ),
              Expanded(
                child: Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: tokens.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: tokens.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Container(
                        height: 48,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: tokens.border),
                          ),
                        ),
                        child: Row(
                          children: <Widget>[
                            InkWell(
                              onTap: () => Navigator.pop(context),
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 4,
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    Icon(
                                      Icons.chevron_left,
                                      size: 18,
                                      color: tokens.textSecondary,
                                    ),
                                    if (breadcrumbParent != null)
                                      Text(
                                        breadcrumbParent!,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: tokens.textSecondary,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            if (title != null) ...<Widget>[
                              const SizedBox(width: 8),
                              Text(
                                title!,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: tokens.textPrimary,
                                ),
                              ),
                            ],
                            const Spacer(),
                            IconButton(
                              iconSize: 18,
                              splashRadius: 16,
                              color: tokens.textMuted,
                              onPressed: () {
                                Navigator.pop(context);
                              },
                              icon: const Icon(Icons.clear),
                            ),
                          ],
                        ),
                      ),
                      Expanded(child: stepper),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
