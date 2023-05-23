import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/loading_widget.dart';

class LoadingInfoText extends StatelessWidget {
  final String text;

  const LoadingInfoText({
    required this.text,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SyriusLoadingWidget(
          size: 16.0,
          strokeWidth: 2.0,
        ),
        const SizedBox(
          width: 10.0,
        ),
        Text(
          text,
          style:
              const TextStyle(fontSize: 14.0, color: AppColors.subtitleColor),
        )
      ],
    );
  }
}
