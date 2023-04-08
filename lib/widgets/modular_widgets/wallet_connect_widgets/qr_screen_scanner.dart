import 'dart:io';

import 'package:bot_toast/bot_toast.dart';
import 'package:clipboard_watcher/clipboard_watcher.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:preference_list/preference_list.dart';
import 'package:screen_capturer/screen_capturer.dart';
import 'package:path_provider/path_provider.dart';
import 'package:zxing2/qrcode.dart';
import 'package:image/image.dart' as img;

final screenCapturer = ScreenCapturer.instance;

class qr_screen_scanner extends StatefulWidget {
  const qr_screen_scanner({Key? key}) : super(key: key);

  @override
  _qr_screen_scannerState createState() => _qr_screen_scannerState();
}

class _qr_screen_scannerState extends State<qr_screen_scanner> with ClipboardListener {
  bool _isAccessAllowed = false;

  CapturedData? _lastCapturedData;
  // RecognizeTextResponse? _recognizeTextResponse;
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
    // bool hasStrings = await Clipboard.hasStrings();
    ClipboardData? newClipboardData =
    await Clipboard.getData(Clipboard.kTextPlain);
    BotToast.showText(text: newClipboardData?.text ?? "");
    print(newClipboardData?.text ?? "");
  }

  void _handleClickCapture(CaptureMode mode) async {
    Directory directory = await getApplicationDocumentsDirectory();
    String imageName =
        'Screenshot-${DateTime.now().millisecondsSinceEpoch}.png';
    String imagePath =
        '${directory.path}/text_recognizer/Screenshots/$imageName';
    _lastCapturedData = await screenCapturer.capture(
      mode: mode,
      imagePath: imagePath,
      silent: true,
    );
    if (_lastCapturedData != null) {
      var image = img.decodePng(File(imagePath).readAsBytesSync())!;

      LuminanceSource source = RGBLuminanceSource(
          image.width, image.height, image.getBytes().buffer.asInt32List());
      var bitmap = BinaryBitmap(HybridBinarizer(source));

      var reader = QRCodeReader();
      var result = reader.decode(bitmap);
      _qrCode = reader.decode(bitmap).text;
      // _recognizeTextResponse = await ocrClient
      //     .use(kBuiltInOcrEngine)
      //     .recognizeText(RecognizeTextRequest(
      //       imagePath: imagePath,
      //     ));
      BotToast.showText(text: _qrCode ?? 'null');
    } else {
      BotToast.showText(text: 'User canceled capture');
      print('User canceled capture');
    }
    setState(() {});
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
                  BotToast.showText(text: 'allowed: $allowed');
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
                    BotToast.showText(
                        text:
                        'Please allow this application to process QR codes from your screen');
                    await ScreenCapturer.instance.requestAccess();
                  }
                },
              ),
            ],
          ),
        Center(
            child: Column(
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
            )),
        PreferenceListSection(
          title: const Text('METHODS'),
          children: [
            PreferenceListItem(
              title: const Text('capture'),
              accessoryView: Row(children: [
                CupertinoButton(
                  child: const Text('region'),
                  onPressed: () {
                    _handleClickCapture(CaptureMode.region);
                  },
                ),
                CupertinoButton(
                  child: const Text('screen'),
                  onPressed: () {
                    _handleClickCapture(CaptureMode.screen);
                  },
                ),
                CupertinoButton(
                  child: const Text('window'),
                  onPressed: () {
                    _handleClickCapture(CaptureMode.window);
                  },
                ),
              ]),
            ),
          ],
        ),
        if (_qrCode != null) Text(_qrCode ?? ''),
        // if (_recognizeTextResponse != null)
        //   Text(_recognizeTextResponse?.text ?? ''),
        if (_lastCapturedData != null && _lastCapturedData?.imagePath != null)
          Container(
            margin: const EdgeInsets.only(top: 20),
            width: 400,
            height: 400,
            child: Image.file(
              File(_lastCapturedData!.imagePath!),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return _buildBody(context);
  }
}
