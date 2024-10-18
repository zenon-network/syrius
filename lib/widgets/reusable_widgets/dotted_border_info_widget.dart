import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';

class DottedBorderInfoWidget extends StatefulWidget {

  const DottedBorderInfoWidget({
    required this.text,
    this.borderColor = AppColors.znnColor,
    super.key,
  });
  final String text;
  final Color borderColor;

  @override
  State<DottedBorderInfoWidget> createState() => _DottedBorderInfoWidgetState();
}

class _DottedBorderInfoWidgetState extends State<DottedBorderInfoWidget> {
  @override
  Widget build(BuildContext context) {
    return DottedBorder(
      padding: const EdgeInsets.all(5),
      color: widget.borderColor,
      borderType: BorderType.RRect,
      radius: const Radius.circular(6),
      dashPattern: const [3.0],
      strokeWidth: 2,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(
            MaterialCommunityIcons.exclamation_thick,
            size: 25,
            color: widget.borderColor,
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
