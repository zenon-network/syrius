import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';

class SyriusElevatedButton extends StatefulWidget {

  const SyriusElevatedButton({
    required this.text,
    required this.onPressed,
    this.icon,
    this.initialFillColor = AppColors.qsrColor,
    this.style,
    super.key,
  });
  final String text;
  final Color initialFillColor;
  final VoidCallback? onPressed;
  final Widget? icon;
  final ButtonStyle? style;

  @override
  State createState() {
    return _SyriusElevatedButtonState();
  }

  static Widget getFilledButtonPlusIcon() {
    return Container(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.znnColor,
      ),
      alignment: Alignment.center,
      child: const Icon(
        MaterialCommunityIcons.plus,
        color: Colors.white,
        size: 15,
      ),
    );
  }
}

class _SyriusElevatedButtonState extends State<SyriusElevatedButton> {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: widget.onPressed,
      style: widget.style,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Visibility(
            visible: widget.icon != null,
            child: Container(
              alignment: Alignment.center,
              height: 20,
              width: 20,
              child: widget.icon,
            ),
          ),
          Visibility(
            visible: widget.icon != null,
            child: const SizedBox(
              width: 5,
            ),
          ),
          Text(
            widget.text,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
        ],
      ),
    );
  }
}
