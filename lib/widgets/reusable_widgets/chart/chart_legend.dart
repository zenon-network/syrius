import 'package:flutter/material.dart';

/// Legend row displaying a colored indicator dot, label, and optional details.
class ChartLegend extends StatelessWidget {
  /// Creates a [ChartLegend].
  const ChartLegend({
    required this.dotColor,
    required this.mainText,
    this.detailsWidget,
    super.key,
  });

  /// Color of the circular legend dot.
  final Color dotColor;

  /// Primary label text next to the dot.
  final String mainText;

  /// Optional trailing widget displayed beside [mainText].
  final Widget? detailsWidget;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
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
