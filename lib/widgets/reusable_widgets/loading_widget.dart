import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';

class SyriusLoadingWidget extends StatelessWidget {

  const SyriusLoadingWidget({
    this.size = 50.0,
    this.strokeWidth = 4.0,
    this.padding = 4.0,
    super.key,
  });
  final double size;
  final double strokeWidth;
  final double padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(padding),
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
