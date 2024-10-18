import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_theme.dart';
import 'package:zenon_syrius_wallet_flutter/utils/color_utils.dart';

class TagWidget extends StatelessWidget {

  const TagWidget({
    required this.text,
    this.hexColorCode,
    this.onPressed,
    this.iconData,
    this.textColor,
    super.key,
  });
  final IconData? iconData;
  final VoidCallback? onPressed;
  final String text;
  final String? hexColorCode;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(50),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            height: 25,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(50),
              color: hexColorCode != null
                  ? ColorUtils.getColorFromHexCode(hexColorCode!)
                  : Theme.of(context).colorScheme.secondary,
            ),
            child: Row(
              children: [
                if (iconData != null)
                  Row(
                    children: [
                      Icon(
                        iconData,
                        color: Colors.white,
                        size: 15,
                      ),
                      const SizedBox(
                        width: 5,
                      ),
                    ],
                  ),
                Text(
                  text,
                  style: kBodySmallTextStyle.copyWith(
                    color: textColor ?? Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(
          width: 10,
        ),
      ],
    );
  }
}
