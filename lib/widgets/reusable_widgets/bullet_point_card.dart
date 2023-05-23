import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';
import 'package:zenon_syrius_wallet_flutter/utils/extensions.dart';

class BulletPointCard extends StatelessWidget {
  final List<RichText> bulletPoints;

  const BulletPointCard({
    required this.bulletPoints,
    Key? key,
  }) : super(key: key);

  static TextSpan textSpan(String text, {List<TextSpan>? children}) {
    return TextSpan(
        text: text,
        style: const TextStyle(fontSize: 14.0, color: AppColors.subtitleColor),
        children: children);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).hoverColor,
        borderRadius: const BorderRadius.all(Radius.circular(8.0)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: bulletPoints
              .map((e) => Row(
                    children: [
                      const Text('●',
                          style: TextStyle(
                              fontSize: 14.0, color: AppColors.subtitleColor)),
                      const SizedBox(width: 10.0),
                      Expanded(child: e)
                    ],
                  ))
              .toList()
              .zip(
                List.generate(
                  bulletPoints.length - 1,
                  (index) => const SizedBox(
                    height: 15.0,
                  ),
                ),
              ),
        ),
      ),
    );
  }
}
