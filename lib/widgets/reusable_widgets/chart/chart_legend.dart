import 'package:flutter/material.dart';

class ChartLegend extends StatelessWidget {
  final Color dotColor;
  final String mainText;
  final Widget? detailsWidget;

  const ChartLegend({
    required this.dotColor,
    required this.mainText,
    this.detailsWidget,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
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
          width: 5.0,
        ),
        if (detailsWidget != null)
          Expanded(
            child: detailsWidget!,
          ),
      ],
    );
  }
}
