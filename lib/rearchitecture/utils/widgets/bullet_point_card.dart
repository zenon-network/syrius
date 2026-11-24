import 'package:flutter/material.dart';
import 'package:styled_text/styled_text.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/constants/app_sizes.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/extensions/buildcontext_extension.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';

/// A card that displays a vertical list of styled bullet-point strings.
class BulletPointCard extends StatelessWidget {
  /// Creates a bullet-point card.
  const BulletPointCard({
    required this.bulletPoints,
    super.key,
  });

  /// Text displayed as individual bullet points.
  final List<String> bulletPoints;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.newThemeData.inputDecorationTheme.fillColor,
        borderRadius: const BorderRadius.all(Radius.circular(8)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          spacing: kVerticalGap16.height!,
          children: bulletPoints
              .map(
                (String bulletPoint) => Row(
                  children: <Widget>[
                    const Text(
                      '●',
                    ),
                    kHorizontalGap8,
                    Expanded(
                      child: StyledText(
                        text: bulletPoint,
                        tags: const <String, StyledTextTag>{
                          'highlight': StyledTextTag(
                            style: TextStyle(
                              color: AppColors.znnColor,
                            ),
                          ),
                        },
                      ),
                    ),
                  ],
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}
