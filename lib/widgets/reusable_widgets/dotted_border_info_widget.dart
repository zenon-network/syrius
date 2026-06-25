import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';

class DottedBorderInfoWidget extends StatefulWidget {
  final String text;
  final Color borderColor;

  const DottedBorderInfoWidget({
    required this.text,
    this.borderColor = AppColors.znnColor,
    Key? key,
  }) : super(key: key);

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
