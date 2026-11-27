import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';

/// Informational banner framed with a rounded dotted border.
class DottedBorderInfoWidget extends StatefulWidget {
  /// Creates a [DottedBorderInfoWidget].
  const DottedBorderInfoWidget({
    required this.text,
    this.borderColor = AppColors.znnColor,
    super.key,
  });

  /// Informational text displayed inside the banner.
  final String text;

  /// Color used for both the dotted border and the leading info icon.
  final Color borderColor;

  @override
  State<DottedBorderInfoWidget> createState() => _DottedBorderInfoWidgetState();
}

class _DottedBorderInfoWidgetState extends State<DottedBorderInfoWidget> {
  @override
  Widget build(BuildContext context) {
    return DottedBorder(
      options: RoundedRectDottedBorderOptions(
        padding: const EdgeInsets.all(10),
        color: widget.borderColor,
        radius: const Radius.circular(6),
        dashPattern: const <double>[3],
        strokeWidth: 2,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const SizedBox(
            width: 5,
          ),
          Icon(
            Icons.info_outline,
            color: widget.borderColor,
          ),
          const SizedBox(
            width: 10,
          ),
          Flexible(
            child: Text(
              widget.text,
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(
            width: 10,
          ),
        ],
      ),
    );
  }
}
