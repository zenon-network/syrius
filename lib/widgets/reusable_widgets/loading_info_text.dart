import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/loading_widget.dart';

class LoadingInfoText extends StatelessWidget {

  const LoadingInfoText({
    required this.text,
    this.tooltipText,
    super.key,
  });
  final String text;
  final String? tooltipText;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SyriusLoadingWidget(
          size: 16,
          strokeWidth: 2,
        ),
        const SizedBox(
          width: 10,
        ),
        Text(
          text,
          style:
              const TextStyle(fontSize: 14, color: AppColors.subtitleColor),
        ),
        Visibility(
          visible: tooltipText != null,
          child: const SizedBox(
            width: 5,
          ),
        ),
        Visibility(
          visible: tooltipText != null,
          child: Tooltip(
            message: tooltipText ?? '',
            child: const Padding(
              padding: EdgeInsets.only(top: 1),
              child: Icon(
                Icons.help,
                color: AppColors.subtitleColor,
                size: 14,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
