import 'package:flutter/material.dart';
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:zenon_syrius_wallet_flutter/utils/color_utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class ReceiveQrImage extends StatelessWidget {
  final String data;
  final double size;
  final TokenStandard tokenStandard;
  final BuildContext context;

  const ReceiveQrImage({
    required this.data,
    required this.size,
    required this.tokenStandard,
    required this.context,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(
        15.0,
      ),
      child: Container(
        padding: const EdgeInsets.all(
          10.0,
        ),
        color: Theme.of(context).colorScheme.background,
        child: PrettyQr(
          data: data,
          size: size,
          elementColor: ColorUtils.getTokenColor(tokenStandard),
          image: const AssetImage('assets/images/qr_code_child_image_znn.png'),
          typeNumber: 7,
          errorCorrectLevel: QrErrorCorrectLevel.M,
          roundEdges: true,
        ),
      ),
    );
  }
}
