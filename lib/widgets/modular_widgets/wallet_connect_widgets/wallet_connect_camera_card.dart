import 'dart:io';

import 'package:ai_barcode_scanner/ai_barcode_scanner.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:wallet_connect_uri_validator/wallet_connect_uri_validator.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/services/wallet_connect_service.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

const String _kWidgetTitle = 'Camera QR Scanner';
const String _kWidgetDescription =
    'Scan a WalletConnect QR code using the built-in camera of this device';

class WalletConnectCameraCard extends StatefulWidget {
  const WalletConnectCameraCard({Key? key}) : super(key: key);

  @override
  State<WalletConnectCameraCard> createState() =>
      _WalletConnectCameraCardState();
}

class _WalletConnectCameraCardState extends State<WalletConnectCameraCard> {
  @override
  void initState() {
    super.initState();
  }

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
          const CircleAvatar(
            radius: 60.0,
            backgroundColor: Colors.white12,
            child: Icon(
              Icons.camera_alt_outlined,
              color: AppColors.znnColor,
              size: 60.0,
            ),
          ),
          Platform.isMacOS
              ? MyOutlinedButton(
                  text: 'Scan QR',
                  onPressed: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => AiBarcodeScanner(
                          validator: (value) {
                            return canParseWalletConnectUri(value);
                          },
                          canPop: true,
                          onScan: (String value) async {
                            final wcService = sl.get<WalletConnectService>();
                            final pairingInfo =
                                await wcService.pair(Uri.parse(value));
                            Logger('WalletConnectCameraCard').log(Level.INFO,
                                'pairing info', pairingInfo.toJson());
                            setState(() {});
                          },
                          onDetect: (p0) {},
                          onDispose: () {},
                          controller: MobileScannerController(
                            detectionSpeed: DetectionSpeed.noDuplicates,
                          ),
                        ),
                      ),
                    );
                  },
                  minimumSize: kLoadingButtonMinSize,
                )
              : Text(
                  'Only MacOS is supported at the moment',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
        ],
      ),
    );
  }

  bool canParseWalletConnectUri(String wcUri) {
    WalletConnectUri? walletConnectUri;
    walletConnectUri = WalletConnectUri.tryParse(wcUri);
    if (walletConnectUri != null) {
      return true;
    }
    return false;
  }
}
