import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screen_capturer/screen_capturer.dart';
import 'package:walletconnect_flutter_v2/walletconnect_flutter_v2.dart';
import 'package:window_manager/window_manager.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/model/database/notification_type.dart';
import 'package:zenon_syrius_wallet_flutter/model/database/wallet_notification.dart';
import 'package:zenon_syrius_wallet_flutter/services/wallet_connect_service.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:zxing2/qrcode.dart';

final screenCapturer = ScreenCapturer.instance;

const String _kWidgetTitle = 'WalletConnect Pairing';
// TODO: change description
const String _kWidgetDescription = 'Description';

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
          ValueListenableBuilder<String?>(
            builder: (_, value, child) {
              if (value != null) {
                _uriController.text = value;
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
                  ClipboardUtils.pasteToClipboard(context, (String value) {
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
              hintText: 'dApp URI',
            ),
          ),
          kVerticalSpacing,
          MyOutlinedButton(
            text: 'Connect',
            // TODO: add validator for WC URI
            onPressed: () {
              _showPairingDialog(Uri.parse(_uriController.text));
            },
            minimumSize: kLoadingButtonMinSize,
          ),
          kVerticalSpacing,
          MyOutlinedButton(
            text: 'Scan QR code',
            onPressed: () {
              windowManager.minimize().then(
                    (value) => _handleClickCapture(CaptureMode.region),
                  );
            },
            minimumSize: kLoadingButtonMinSize,
          ),
        ],
      ),
    );
  }

  Future<void> _showPairingDialog(Uri uri) async {
    showDialogWithNoAndYesOptions(
      context: context,
      title: 'Pairing through WalletConnect',
      // TODO: check if we can get the dApp name at this stage
      description: 'Are you sure you want to pair with this dApp?',
      onYesButtonPressed: () => _pairWithDapp(uri),
    );
  }

  Future<void> _pairWithDapp(Uri uri) async {
    try {
      final wcService = sl.get<WalletConnectService>();
      final pairingInfo = await wcService.pair(uri);
      print('Pairing info: ${pairingInfo.toJson()}');
      wcService.activatePairing(topic: pairingInfo.topic);
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
      if (Platform.isMacOS) {
        await _requestAccessForMacOs();
      }
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
        setState(() {
          _uriController.text = result.text;
        });
      }
    } on Exception catch (e) {
      sl<NotificationsBloc>().addErrorNotification(e, 'Could not scan screen');
    }
  }

  Future<void> _requestAccessForMacOs() async {
    bool isAccessAllowed = await ScreenCapturer.instance.isAccessAllowed();
    if (!isAccessAllowed) {
      await ScreenCapturer.instance.requestAccess();
      isAccessAllowed = await ScreenCapturer.instance.isAccessAllowed();
      if (!isAccessAllowed) {
        throw 'Access denied';
      }
    }
  }
}
