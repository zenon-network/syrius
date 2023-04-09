import 'dart:io';
import 'package:clipboard_watcher/clipboard_watcher.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:preference_list/preference_list.dart';
import 'package:screen_capturer/screen_capturer.dart';
import 'package:path_provider/path_provider.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/buttons/buttons.dart';
import 'package:zxing2/qrcode.dart';
import 'package:image/image.dart' as img;

final screenCapturer = ScreenCapturer.instance;

class QrScreenScanner extends StatefulWidget {
  const QrScreenScanner({Key? key}) : super(key: key);

  @override
  _QrScreenScannerState createState() => _QrScreenScannerState();
}

class _QrScreenScannerState extends State<QrScreenScanner>
    with ClipboardListener {
  bool _isAccessAllowed = false;

  CapturedData? _lastCapturedData;
  String? _qrCode;

  @override
  void initState() {
    clipboardWatcher.addListener(this);
    super.initState();
    _init();
  }

  void _init() async {
    _isAccessAllowed = await screenCapturer.isAccessAllowed();

    setState(() {});
  }

  @override
  void onClipboardChanged() async {
    ClipboardData? newClipboardData =
        await Clipboard.getData(Clipboard.kTextPlain);
    print(newClipboardData?.text ?? "");
  }

  void _handleClickCapture(CaptureMode mode) async {
    // Directory directory = await getApplicationDocumentsDirectory();
    // String imageName =
    //     'Screenshot-${DateTime.now().millisecondsSinceEpoch}.png';
    // String imagePath =
    //     '${directory.path}/text_recognizer/Screenshots/$imageName';
    // _lastCapturedData = await screenCapturer.capture(
    //   mode: mode,
    //   imagePath: imagePath,
    //   silent: true,
    // );
    // if (_lastCapturedData != null) {
    //   var image = img.decodePng(File(imagePath).readAsBytesSync())!;
    //
    //   LuminanceSource source = RGBLuminanceSource(
    //       image.width, image.height, image.getBytes().buffer.asInt32List());
    //   var bitmap = BinaryBitmap(HybridBinarizer(source));
    //
    //   var reader = QRCodeReader();
    //   var result = reader.decode(bitmap);
    //   _qrCode = reader.decode(bitmap).text;
    //   print('QR code: $_qrCode');
    // } else {
    //   print('User canceled capture');
    // }
    // setState(() {});
  }

  Widget _buildBody(BuildContext context) {
    return PreferenceList(
      children: <Widget>[
        if (Platform.isMacOS)
          PreferenceListSection(
            children: [
              PreferenceListItem(
                title: const Text('isAccessAllowed'),
                accessoryView: Text('$_isAccessAllowed'),
                onTap: () async {
                  bool allowed =
                      await ScreenCapturer.instance.isAccessAllowed();
                  print('allowed: $allowed');
                  setState(() {
                    _isAccessAllowed = allowed;
                  });
                },
              ),
              PreferenceListItem(
                title: const Text('requestAccess'),
                onTap: () async {
                  print('requestingAccess');
                  if (!await ScreenCapturer.instance.isAccessAllowed()) {
                    await ScreenCapturer.instance.requestAccess();
                  }
                },
              ),
            ],
          ),
        Column(
          children: [
        ElevatedButton(
          child: const Text('Start recording clipboard'),
          onPressed: () {
            clipboardWatcher.start();
          },
        ),
        Container(
          height: 20,
        ),
        ElevatedButton(
          child: const Text('Stop recording clipboard'),
          onPressed: () {
            clipboardWatcher.stop();
          },
        ),
          ],
        ),
        Row(
          children: [
            MyOutlinedButton(
              text: 'Scan QR code',
              onPressed: () {
                _handleClickCapture(CaptureMode.region);
              },
              minimumSize: kLoadingButtonMinSize,
            ),
          ],
        ),
        if (_qrCode != null) Text(_qrCode ?? ''),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildBody(context);
  }
}
