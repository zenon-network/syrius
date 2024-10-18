import 'package:flutter/material.dart';

class ChartLegend extends StatelessWidget {

  const ChartLegend({
    required this.dotColor,
    required this.mainText,
    this.detailsWidget,
    super.key,
  });
  final Color dotColor;
  final String mainText;
  final Widget? detailsWidget;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '● ',
          style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                color: dotColor,
              ),
        ),
        Text(
          mainText,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(
          width: 5,
        ),
        if (detailsWidget != null)
          Expanded(
            child: detailsWidget!,
          ),
      ],
    );
  }
}
