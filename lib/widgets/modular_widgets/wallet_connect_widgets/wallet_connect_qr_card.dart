import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;
import 'package:pretty_qr_code/pretty_qr_code.dart';
import 'package:screen_capturer/screen_capturer.dart';
import 'package:wallet_connect_uri_validator/wallet_connect_uri_validator.dart';
import 'package:window_manager/window_manager.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/model/database/notification_type.dart';
import 'package:zenon_syrius_wallet_flutter/model/database/wallet_notification.dart';
import 'package:zenon_syrius_wallet_flutter/services/wallet_connect_service.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';
import 'package:zxing2/qrcode.dart';

const String _kWidgetTitle = 'On-screen QR Scanner';
const String _kWidgetDescription =
    'Scan the WalletConnect QR code using an on-screen QR scanner. '
    'This requires the screen recording permission';

final screenCapturer = ScreenCapturer.instance;

class WalletConnectQrCard extends StatefulWidget {
  const WalletConnectQrCard({Key? key}) : super(key: key);

  @override
  State<WalletConnectQrCard> createState() => _WalletConnectQrCardState();
}

class _WalletConnectQrCardState extends State<WalletConnectQrCard> {
  TextEditingController _uriController = TextEditingController(
    text: kLastWalletConnectUriNotifier.value,
  );
  CapturedData? _lastCapturedData;

  final _uriKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return CardScaffold(
      title: _kWidgetTitle,
      description: _kWidgetDescription,
      childBuilder: () => _getCardBody(),
    );
  }

  Widget _getCardBody() {
    return Padding(
      padding: const EdgeInsets.all(15.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Container(
            padding: const EdgeInsets.all(10.0),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.background,
              borderRadius: BorderRadius.circular(15.0),
            ),
            child: PrettyQr(
              data: 'Scan the WalletConnect QR from the dApp',
              size: 100.0,
              elementColor: AppColors.znnColor,
              image:
                  const AssetImage('assets/images/qr_code_child_image_znn.png'),
              typeNumber: 7,
              errorCorrectLevel: QrErrorCorrectLevel.M,
              roundEdges: true,
            ),
          ),
          MyOutlinedButton(
            text: 'Scan QR',
            onPressed: () {
              checkPermissionForMacOS().then((value) {
                if (value) {
                  windowManager.minimize().then(
                        (value) => _handleClickCapture(CaptureMode.region),
                      );
                }
              });
            },
            minimumSize: kLoadingButtonMinSize,
          ),
        ],
      ),
    );
  }

  Future<void> _pairWithDapp(Uri uri) async {
    try {
      final wcService = sl.get<WalletConnectService>();
      final pairingInfo = await wcService.pair(uri);
      Logger('WalletConnectPairingCard')
          .log(Level.INFO, 'pairing info', pairingInfo.toJson());
      _uriController = TextEditingController();
      _uriKey.currentState?.reset();
      setState(() {});
    } catch (e) {
      NotificationUtils.sendNotificationError(e, 'Pairing failed');
    }
  }

  void _handleClickCapture(CaptureMode mode) async {
    try {
      Directory walletConnectDirectory = Directory(
          path.join(znnDefaultPaths.cache.path, walletConnectDirName));

      if (!walletConnectDirectory.existsSync()) {
        walletConnectDirectory.createSync(recursive: true);
      }

      String screenshotName =
          'screenshot-${DateTime.now().millisecondsSinceEpoch}';

      final imagePath = await File(
              '${walletConnectDirectory.absolute.path}${path.separator}$screenshotName.png')
          .create();

      _lastCapturedData = await screenCapturer.capture(
        mode: mode,
        imagePath: imagePath.absolute.path,
        silent: true,
      );

      if (_lastCapturedData != null) {
        var image = img.decodePng(imagePath.readAsBytesSync())!;

        LuminanceSource source = RGBLuminanceSource(
            image.width, image.height, image.getBytes().buffer.asInt32List());
        var bitmap = BinaryBitmap(HybridBinarizer(source));

        var reader = QRCodeReader();
        var result = reader.decode(bitmap);

        if (result.rawBytes!.isNotEmpty) {
          if (result.text.isNotEmpty &&
              WalletConnectUri.tryParse(result.text) != null) {
            windowManager.show();
            _uriController.text = result.text;
          } else {
            windowManager.show();
            sl<NotificationsBloc>().addNotification(WalletNotification(
                title: 'Invalid QR code',
                timestamp: DateTime.now().millisecondsSinceEpoch,
                details: 'Please scan a valid WalletConnect QR code',
                type: NotificationType.error));
          }
        } else {
          windowManager.show();
          sl<NotificationsBloc>().addNotification(WalletNotification(
              title: 'QR code scan failed',
              timestamp: DateTime.now().millisecondsSinceEpoch,
              details: 'Please scan a valid WalletConnect QR code',
              type: NotificationType.error));
        }
        _pairWithDapp(Uri.parse(result.text));
      } else {
        windowManager.show();
        sl<NotificationsBloc>().addErrorNotification(
          'User canceled the QR scanning operation',
          'User QR scan canceled',
        );
      }
    } on Exception catch (e) {
      windowManager.show();
      sl<NotificationsBloc>()
          .addErrorNotification(e, 'Invalid QR code exception');
    }
  }

  Future<bool> checkPermissionForMacOS() async {
    if (Platform.isMacOS) {
      if (!await _requestAccessForMacOS()) {
        sl<NotificationsBloc>().addNotification(WalletNotification(
            title: 'Permission required',
            timestamp: DateTime.now().millisecondsSinceEpoch,
            details:
                'Screen Recording permission is required to scan and process the on-screen WalletConnect QR code',
            type: NotificationType.generatingPlasma));
        return false;
      }
      return true;
    }
    return true;
  }

  Future<bool> _requestAccessForMacOS() async {
    bool isAccessAllowed = await ScreenCapturer.instance.isAccessAllowed();
    if (!isAccessAllowed) {
      await ScreenCapturer.instance.requestAccess();
    }
    return isAccessAllowed;
  }
}
