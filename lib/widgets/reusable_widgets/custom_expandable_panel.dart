import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';

/// Collapsible panel with a styled header and expandable body content.
class CustomExpandablePanel extends StatefulWidget {
  /// Creates a [CustomExpandablePanel].
  const CustomExpandablePanel(
    this.header,
    this.expandedChild, {
    super.key,
  });

  /// Header title shown in both collapsed and expanded states.
  final String header;

  /// Widget revealed when the panel is expanded.
  final Widget expandedChild;

  @override
  State<CustomExpandablePanel> createState() => _CustomExpandablePanelState();

  /// Builds a styled [Text] widget suitable for use as [expandedChild].
  static Widget getGenericTextExpandedChild(
    String expandedText,
    BuildContext context,
  ) {
    return Text(
      expandedText,
      style: Theme.of(context).textTheme.titleSmall,
    );
  }
}

class _CustomExpandablePanelState extends State<CustomExpandablePanel> {
  @override
  Widget build(BuildContext context) {
    return ExpandableTheme(
      data: const ExpandableThemeData(
        iconColor: AppColors.maxAmountBorder,
        headerAlignment: ExpandablePanelHeaderAlignment.center,
        bodyAlignment: ExpandablePanelBodyAlignment.left,
      ),
      child: ExpandablePanel(
        collapsed: Container(),
        header: Padding(
          padding: const EdgeInsets.only(
            left: 15,
          ),
          child: Text(
            widget.header,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        expanded: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 5,
            horizontal: 15,
          ),
          child: widget.expandedChild,
        ),
      ),
    );
  }
}
