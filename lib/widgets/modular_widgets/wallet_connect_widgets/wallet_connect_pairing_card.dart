import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:logging/logging.dart';
import 'package:path/path.dart' as path;
import 'package:screen_capturer/screen_capturer.dart';
import 'package:wallet_connect_uri_validator/wallet_connect_uri_validator.dart';
import 'package:walletconnect_flutter_v2/walletconnect_flutter_v2.dart';
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

final screenCapturer = ScreenCapturer.instance;

const String _kWidgetTitle = 'WalletConnect Pairing';
// TODO: change description
const String _kWidgetDescription = 'Description';
const walletConnect = 'walletconnect';

class WalletConnectPairingCard extends StatefulWidget {
  const WalletConnectPairingCard({Key? key}) : super(key: key);

  @override
  State<WalletConnectPairingCard> createState() =>
      _WalletConnectPairingCardState();
}

class _WalletConnectPairingCardState extends State<WalletConnectPairingCard> {
  final TextEditingController _uriController = TextEditingController(
    text: kLastWalletConnectUriNotifier.value,
  );
  CapturedData? _lastCapturedData;

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
        children: [
          kVerticalSpacing,
          Row(
            children: [
              Expanded(
                child: ValueListenableBuilder<String?>(
                  builder: (_, value, child) {
                    if (value != null) {
                      _uriController.text = value;
                      kLastWalletConnectUriNotifier.value = null;
                    }
                    return child!;
                  },
                  valueListenable: kLastWalletConnectUriNotifier,
                  child: InputField(
                    onChanged: (value) {
                      setState(() {});
                    },
                    controller: _uriController,
                    suffixIcon: RawMaterialButton(
                      shape: const CircleBorder(),
                      onPressed: () {
                        ClipboardUtils.pasteToClipboard(context,
                                (String value) {
                              _uriController.text = value;
                              setState(() {});
                            });
                      },
                      child: const Icon(
                        Icons.content_paste,
                        color: AppColors.darkHintTextColor,
                        size: 15.0,
                      ),
                    ),
                    suffixIconConstraints: const BoxConstraints(
                      maxWidth: 45.0,
                      maxHeight: 20.0,
                    ),
                    hintText: 'WalletConnect URI',
                  ),
                ),
              ),
              const SizedBox(
                width: 15.0,
              ),
              MyOutlinedButton(
                text: 'Connect',
                onPressed:
                WalletConnectUri.tryParse(_uriController.text) != null
                    ? () {
                  _pairWithDapp(Uri.parse(_uriController.text));
                }
                    : null,
                minimumSize: kLoadingButtonMinSize,
              ),
            ],
          ),
          kVerticalSpacing,
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                MyOutlinedButton(
                  text: 'Scan QR code',
                  onPressed: () {
                    checkPermissionForMacOS().then((value) {
                      if (value) {
                        windowManager.minimize().then(
                              (value) =>
                              _handleClickCapture(CaptureMode.region),
                        );
                      }
                    });
                  },
                  minimumSize: kLoadingButtonMinSize,
                ),
              ],
            ),
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
      await wcService.activatePairing(topic: pairingInfo.topic);
      _uriController.clear();
      _sendSuccessfullyPairedNotification(pairingInfo);
    } catch (e) {
      NotificationUtils.sendNotificationError(e, 'Pairing failed');
    } finally {
      Navigator.pop(context);
    }
  }

  void _sendSuccessfullyPairedNotification(PairingInfo pairingInfo) {
    sl.get<NotificationsBloc>().addNotification(
      WalletNotification(
        title:
        'Successfully paired with ${pairingInfo.peerMetadata?.name ?? 'dApp'}',
        timestamp: DateTime.now().millisecondsSinceEpoch,
        details:
        'Successfully paired with ${pairingInfo.peerMetadata?.name ?? 'dApp'} '
            'through WalletConnect',
        type: NotificationType.paymentSent,
      ),
    );
  }

  void _handleClickCapture(CaptureMode mode) async {
    try {
      Directory walletConnectDirectory =
      Directory(path.join(znnDefaultPaths.cache.path, walletConnect));

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
        setState(() {
          _uriController.text = result.text;
        });
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
