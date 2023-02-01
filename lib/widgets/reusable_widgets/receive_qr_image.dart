import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as path;
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:zenon_syrius_wallet_flutter/utils/color_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/context_menu_region.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class ReceiveQrImage extends StatelessWidget {
  final String data;
  final double size;
  final TokenStandard tokenStandard;
  final BuildContext context;

  final ScreenshotController screenshotController = ScreenshotController();

  ReceiveQrImage({
    required this.data,
    required this.size,
    required this.tokenStandard,
    required this.context,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Screenshot(
        controller: screenshotController,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(
            15.0,
          ),
          child: Container(
            padding: const EdgeInsets.all(
              10.0,
            ),
            color: Theme.of(context).colorScheme.background,
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
                                color:
                                    Theme.of(context).colorScheme.onBackground,
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
                                          label: 'Share QR', onPressed: () {})),
                                  style:
                                      Theme.of(context).textTheme.bodyMedium),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          flex: 1,
                          child: Directionality(
                            textDirection: TextDirection.rtl,
                            child: TextButton.icon(
                              icon: Icon(
                                Icons.save_alt,
                                color:
                                    Theme.of(context).colorScheme.onBackground,
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
                                          label: 'Save QR', onPressed: () {})),
                                  style:
                                      Theme.of(context).textTheme.bodyMedium),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
              child: PrettyQr(
                data: data,
                size: size,
                elementColor: ColorUtils.getTokenColor(tokenStandard),
                image: const AssetImage(
                    'assets/images/qr_code_child_image_znn.png'),
                typeNumber: 7,
                errorCorrectLevel: QrErrorCorrectLevel.M,
                roundEdges: true,
              ),
            ),
          ),
        ));
  }

  void _saveQR() async {
    Uint8List? capture = await screenshotController.capture(
        delay: const Duration(milliseconds: 20));
    if (capture != null) {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final imagePath = await File(
              '${znnDefaultPaths.cache.path}${path.separator}$fileName.png')
          .create();
      await imagePath.writeAsBytes(capture);
      await OpenFilex.open(imagePath.path);
    }
  }

  void _shareQR() async {
    Uint8List? capture = await screenshotController.capture(
        delay: const Duration(milliseconds: 20));
    if (capture != null) {
      String fileName = DateTime.now().millisecondsSinceEpoch.toString();
      final imagePath = await File(
              '${znnDefaultPaths.cache.path}${path.separator}$fileName.png')
          .create();
      await imagePath.writeAsBytes(capture);
      await Share.shareXFiles([XFile(imagePath.path)]);
    }
  }
}
