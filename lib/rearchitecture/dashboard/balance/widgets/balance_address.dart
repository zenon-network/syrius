import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';

/// A stateless widget that takes in a [ValueNotifier] that holds a color
/// which will be used to highlight the prefix and the suffix of the [address]
///
/// Inside the widget tree there is a [FocusableActionDetector] that knows
/// when the mouse hovers over the [Text] widget that displays the [address]
/// and changes the value of the [edgesColorNotifier]

class BalanceAddress extends StatelessWidget {

  const BalanceAddress({
    required this.address,
    required this.edgesColorNotifier,
    super.key,
  });
  final String address;
  final ValueNotifier<Color> edgesColorNotifier;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: edgesColorNotifier,
      builder: (_, Color? edgesColor, __) {
        return FocusableActionDetector(
          onShowHoverHighlight: (x) {
            if (x) {
              edgesColorNotifier.value = AppColors.znnColor;
            } else {
              edgesColorNotifier.value = Theme.of(context).hintColor;
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border.all(color: Theme.of(context).colorScheme.surface),
              borderRadius: BorderRadius.circular(15),
            ),
            padding: const EdgeInsets.symmetric(
              vertical: 4,
              horizontal: 8,
            ),
            margin: const EdgeInsets.only(
              bottom: 12,
              top: 12,
            ),
            child: AutoSizeText.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: address.substring(0, 3),
                    style: TextStyle(color: edgesColor),
                  ),
                  TextSpan(
                    text: address.substring(
                      3,
                      address.length - 6,
                    ),
                    style: TextStyle(
                      color: Theme.of(context).hintColor,
                    ),
                  ),
                  TextSpan(
                    text: address.substring(
                      address.length - 6,
                      address.length,
                    ),
                    style: TextStyle(
                      color: edgesColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
