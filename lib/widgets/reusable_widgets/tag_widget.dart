import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_theme.dart';
import 'package:zenon_syrius_wallet_flutter/utils/color_utils.dart';

class TagWidget extends StatelessWidget {
  final IconData? iconData;
  final VoidCallback? onPressed;
  final String text;
  final String? hexColorCode;

  const TagWidget({
    required this.text,
    this.hexColorCode,
    this.onPressed,
    this.iconData,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(50.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 15.0),
            height: 25.0,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(50.0),
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
                        size: 15.0,
                      ),
                      const SizedBox(
                        width: 5.0,
                      ),
                    ],
                  ),
                Text(
                  text,
                  style: kText2TextStyle.copyWith(
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(
          width: 10.0,
        ),
      ],
    );
  }
}
