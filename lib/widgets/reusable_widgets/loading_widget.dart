import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';

/// Branded circular loading spinner sized with optional padding.
class SyriusLoadingWidget extends StatelessWidget {
  /// Creates a [SyriusLoadingWidget].
  const SyriusLoadingWidget({
    this.size = 50.0,
    this.strokeWidth = 4.0,
    this.padding = 4.0,
    super.key,
  });

  /// Diameter of the progress indicator container.
  final double size;

  /// Stroke width of the circular progress indicator.
  final double strokeWidth;

  /// Uniform padding around the indicator container.
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
