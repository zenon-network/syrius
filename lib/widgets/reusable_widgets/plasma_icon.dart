import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/utils/color_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/widget_utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class PlasmaIcon extends StatelessWidget {

  const PlasmaIcon(
    this.plasmaInfo, {
    super.key,
  });
  final PlasmaInfo? plasmaInfo;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: WidgetUtils.getPlasmaToolTipMessage(plasmaInfo!),
      child: Container(
        height: 20,
        width: 20,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            width: 3,
            color: ColorUtils.getPlasmaColor(plasmaInfo!),
          ),
        ),
      ),
    );
  }
}
