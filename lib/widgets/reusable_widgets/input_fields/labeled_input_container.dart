import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';

class LabeledInputContainer extends StatelessWidget {
  final String labelText;
  final Widget inputWidget;
  final String? helpText;

  const LabeledInputContainer({
    required this.labelText,
    required this.inputWidget,
    this.helpText,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              labelText,
              style: const TextStyle(
                fontSize: 14.0,
                color: AppColors.darkHintTextColor,
              ),
            ),
            const SizedBox(width: 3.0),
            Visibility(
              visible: helpText != null,
              child: Tooltip(
                message: helpText ?? '',
                child: const Padding(
                  padding: EdgeInsets.only(top: 3.0),
                  child: Icon(
                    Icons.help,
                    color: AppColors.darkHintTextColor,
                    size: 12.0,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 3.0),
        inputWidget
      ],
    );
  }
}
