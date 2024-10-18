import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:lottie/lottie.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as path;
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:share_plus/share_plus.dart';
import 'package:zenon_syrius_wallet_flutter/utils/color_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/context_menu_region.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class ReceiveQrImage extends StatelessWidget {

  const ReceiveQrImage({
    required this.data,
    required this.size,
    required this.tokenStandard,
    required this.context,
    super.key,
  });
  final String data;
  final int size;
  final TokenStandard tokenStandard;
  final BuildContext context;

  static const decorationImage = PrettyQrDecorationImage(
    scale: 0.3,
    padding: EdgeInsets.only(top: 10, bottom: 10),
    image: AssetImage('assets/images/qr_code_child_image_znn.png'),
  );

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(
        15,
      ),
      child: Container(
        height: size + 20,
        width: size + 20,
        padding: const EdgeInsets.all(
          10,
        ),
        color: Theme.of(context).colorScheme.surface,
        child: ContextMenuRegion(
            contextMenuBuilder: (context, offset) {
              return AdaptiveTextSelectionToolbar(
                anchors: TextSelectionToolbarAnchors(
                  primaryAnchor: offset,
                ),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Directionality(
                          textDirection: TextDirection.rtl,
                          child: TextButton.icon(
                            icon: Icon(
                              MaterialCommunityIcons.share,
                              color: Theme.of(context).colorScheme.onSurface,
                              size: 14,
                            ),
                            onPressed: () {
                              ContextMenuController.removeAny();
                              _shareQR();
                            },
                            style: TextButton.styleFrom(
                              shape: const RoundedRectangleBorder(),
                            ),
                            label: Text(
                                AdaptiveTextSelectionToolbar.getButtonLabel(
                                    context,
                                    ContextMenuButtonItem(
                                        label: 'Share QR', onPressed: () {},),),
                                style: Theme.of(context).textTheme.bodyMedium,),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Directionality(
                          textDirection: TextDirection.rtl,
                          child: TextButton.icon(
                            icon: Icon(
                              Icons.save_alt,
                              color: Theme.of(context).colorScheme.onSurface,
                              size: 14,
                            ),
                            onPressed: () {
                              ContextMenuController.removeAny();
                              _saveQR();
                            },
                            style: TextButton.styleFrom(
                              shape: const RoundedRectangleBorder(),
                            ),
                            label: Text(
                                AdaptiveTextSelectionToolbar.getButtonLabel(
                                    context,
                                    ContextMenuButtonItem(
                                        label: 'Save QR', onPressed: () {},),),
                                style: Theme.of(context).textTheme.bodyMedium,),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
            child: PrettyQrView.data(
                data: data,
                decoration: PrettyQrDecoration(
                    shape: PrettyQrSmoothSymbol(
                      roundFactor: 0,
                      color: ColorUtils.getTokenColor(tokenStandard),
                    ),
                    image: decorationImage,),
                errorCorrectLevel: QrErrorCorrectLevel.M,
                errorBuilder: (context, error, stack) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(5),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Lottie.asset(
                              'assets/lottie/ic_anim_no_data.json',
                              width: 32,
                              height: 32,
                            ),
                            Tooltip(
                                message: error.toString(),
                                child: Text(
                                  'Failed to create QR code',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),),
                          ],
                        ),
                      ),
                    ),),),
      ),
    );
  }

  Future<Uint8List?> _getQRImageData() async {
    final qr = QrImage(QrCode.fromData(
      data: data,
      errorCorrectLevel: QrErrorCorrectLevel.M,
    ),);

    final b = await qr.toImageAsBytes(
        size: size,
        decoration: PrettyQrDecoration(
            shape: PrettyQrSmoothSymbol(
              roundFactor: 0,
              color: ColorUtils.getTokenColor(tokenStandard),
            ),
            image: decorationImage,),);

    if (b != null) return b.buffer.asUint8List();
    return null;
  }

  Future<void> _saveQR() async {
    final imageData = await _getQRImageData();
    if (imageData != null) {
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final imagePath = await File(
              '${znnDefaultPaths.cache.path}${path.separator}$fileName.png',)
          .create();
      await imagePath.writeAsBytes(imageData);
      await OpenFilex.open(imagePath.path);
    }
  }

  Future<void> _shareQR() async {
    final imageData = await _getQRImageData();
    if (imageData != null) {
      final fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final imagePath = await File(
              '${znnDefaultPaths.cache.path}${path.separator}$fileName.png',)
          .create();
      await imagePath.writeAsBytes(imageData);
      await Share.shareXFiles([XFile(imagePath.path)]);
    }
  }
}
