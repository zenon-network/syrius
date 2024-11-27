import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/buttons/copy_to_clipboard_button.dart';

class DetailRow extends StatelessWidget {

  const DetailRow({
    required this.label,
    required this.value,
    this.valueToShow,
    this.prefixWidget,
    this.canBeCopied = true,
    super.key,
  });
  final String label;
  final String value;
  final String? valueToShow;
  final Widget? prefixWidget;
  final bool canBeCopied;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        Text(label,
            style: const TextStyle(
                fontSize: 12, color: AppColors.subtitleColor,),),
        Row(
          children: <Widget>[
            prefixWidget ?? Container(),
            if (prefixWidget != null)
              const SizedBox(
                width: 5,
              ),
            Text(valueToShow ?? value,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.subtitleColor,),),
            Visibility(
              visible: canBeCopied,
              child: CopyToClipboardButton(
                value,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
