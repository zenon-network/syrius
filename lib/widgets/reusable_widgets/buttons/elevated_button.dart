import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';

class SyriusElevatedButton extends StatefulWidget {
  final String text;
  final Color initialFillColor;
  final VoidCallback? onPressed;
  final Widget icon;

  const SyriusElevatedButton({
    required this.text,
    required this.onPressed,
    required this.icon,
    this.initialFillColor = AppColors.qsrColor,
    Key? key,
  }) : super(key: key);

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
        size: 15.0,
      ),
    );
  }
}

class _SyriusElevatedButtonState extends State<SyriusElevatedButton> {
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: widget.onPressed,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            alignment: Alignment.center,
            height: 20.0,
            width: 20.0,
            child: widget.icon,
          ),
          const SizedBox(
            width: 5.0,
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
