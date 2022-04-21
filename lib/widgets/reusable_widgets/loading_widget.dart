import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';

class SyriusLoadingWidget extends StatelessWidget {
  final double size;
  final double strokeWidth;

  const SyriusLoadingWidget({
    this.size = 50.0,
    this.strokeWidth = 4.0,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: Container(
        alignment: Alignment.center,
        height: size,
        width: size,
        child: CircularProgressIndicator(
          strokeWidth: strokeWidth,
          valueColor: const AlwaysStoppedAnimation<Color>(
            AppColors.znnColor,
          ),
        ),
      ),
    );
  }
}
