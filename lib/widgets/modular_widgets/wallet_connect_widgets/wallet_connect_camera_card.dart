import 'dart:async';
import 'dart:io';

import 'package:ai_barcode_scanner/ai_barcode_scanner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:logging/logging.dart';
import 'package:wallet_connect_uri_validator/wallet_connect_uri_validator.dart';
import 'package:walletconnect_flutter_v2/apis/core/pairing/utils/pairing_models.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/services/i_web3wallet_service.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

const String _kWidgetTitle = 'Camera QR Scanner';
const String _kWidgetDescription =
    'Scan a WalletConnect QR code using the built-in camera of this device';

class WalletConnectCameraCard extends StatefulWidget {
  const WalletConnectCameraCard({super.key});

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
      childBuilder: _getCardBody,
    );
  }

  Widget _getCardBody() {
    return Padding(
      padding: const EdgeInsets.all(15),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          const CircleAvatar(
            radius: 60,
            backgroundColor: Colors.white12,
            child: Icon(
              Icons.camera_alt_outlined,
              color: AppColors.znnColor,
              size: 60,
            ),
          ),
          if (Platform.isMacOS) MyOutlinedButton(
                  text: 'Scan QR',
                  onPressed: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (BuildContext context) => AiBarcodeScanner(
                          validator: (BarcodeCapture capture) => _filterBarcodes(capture) != null,
                          onDetect: (BarcodeCapture value) async {
                            Logger('WalletConnectCameraCard').log(
                              Level.INFO,
                              'onDetect',
                              value.toString(),
                            );
                            final IWeb3WalletService wcService = sl.get<IWeb3WalletService>();
                            final Barcode? barcode = _filterBarcodes(value);
                            if (barcode != null) {
                              final PairingInfo pairingInfo = await wcService.pair(
                                Uri.parse(value.barcodes.first.displayValue!),
                              );
                              Logger('WalletConnectCameraCard').log(
                                Level.INFO,
                                'pairing info',
                                pairingInfo.toJson(),
                              );
                              setState(() {});
                            }
                          },
                          onDispose: () {
                            Logger('WalletConnectCameraCard')
                                .log(Level.INFO, 'onDispose');
                          },
                          controller: MobileScannerController(
                            facing: CameraFacing.front,
                            detectionSpeed: DetectionSpeed.noDuplicates,
                          ),
                          errorBuilder: (BuildContext p0, MobileScannerException p1, Widget? p2) {
                            // Pop navigator and close camera after 10 seconds
                            Timer(const Duration(seconds: 10), () {
                              Navigator.pop(context);
                            });
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  Text('${p1.errorCode}',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium,),
                                  Container(height: 16),
                                  const Icon(
                                    MaterialCommunityIcons.camera_off,
                                    size: 32,
                                    color: AppColors.errorColor,
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  },
                  minimumSize: kLoadingButtonMinSize,
                ) else Text(
                  'Only MacOS is supported at the moment',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  bool canParseWalletConnectUri(String wcUri) {
    WalletConnectUri? walletConnectUri;
    walletConnectUri = WalletConnectUri.tryParse(wcUri);
    if (walletConnectUri != null) {
      return true;
    }
    return false;
  }

  /// A BarcodeCapture can contain multiple barcodes. This function returns
  /// the first valid WC barcode
  Barcode? _filterBarcodes(BarcodeCapture capture) {
    for (final Barcode barcode in capture.barcodes) {
      final String? uri = barcode.displayValue;
      if (uri != null) {
        if (!canParseWalletConnectUri(uri)) {
          return barcode;
        }
      }
    }
    return null;
  }
}
