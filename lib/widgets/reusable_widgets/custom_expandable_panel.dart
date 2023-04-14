import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';

class CustomExpandablePanel extends StatefulWidget {
  final String header;
  final Widget expandedChild;

  const CustomExpandablePanel(
    this.header,
    this.expandedChild, {
    Key? key,
  }) : super(key: key);

  @override
  State<CustomExpandablePanel> createState() => _CustomExpandablePanelState();

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
            left: 15.0,
          ),
          child: Text(
            widget.header,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ),
        expanded: Padding(
          padding: const EdgeInsets.symmetric(
            vertical: 5.0,
            horizontal: 15.0,
          ),
          child: widget.expandedChild,
        ),
      ),
    );
  }
}
