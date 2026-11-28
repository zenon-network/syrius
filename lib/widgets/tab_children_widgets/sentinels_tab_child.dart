import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/tab_children_widgets/pillars_tab_child.dart';

/// Displays the unified Nodes tab defaulting to Sentinels (Screen 18).
class SentinelsTabChild extends StatelessWidget {
  /// Creates a [SentinelsTabChild].
  const SentinelsTabChild({
    required this.onStepperNotificationSeeMorePressed,
    super.key,
  });

  /// Called when the stepper notification asks to show more details.
  final VoidCallback onStepperNotificationSeeMorePressed;

  @override
  Widget build(BuildContext context) {
    return NodesWorkspaceView(
      initialTab: NodesSubTab.sentinels,
      onStepperNotificationSeeMorePressed: onStepperNotificationSeeMorePressed,
    );
  }
}
