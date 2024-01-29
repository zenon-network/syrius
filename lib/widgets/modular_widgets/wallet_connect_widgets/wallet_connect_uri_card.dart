import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:wallet_connect_uri_validator/wallet_connect_uri_validator.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/services/wallet_connect_service.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

const String _kWidgetTitle = 'WalletConnect Link';
const String _kWidgetDescription = 'Paste the WalletConnect link here';

class WalletConnectUriCard extends StatefulWidget {
  const WalletConnectUriCard({Key? key}) : super(key: key);

  @override
  State<WalletConnectUriCard> createState() => _WalletConnectUriCardState();
}

class _WalletConnectUriCardState extends State<WalletConnectUriCard> {
  TextEditingController _uriController = TextEditingController(
    text: kLastWalletConnectUriNotifier.value,
  );

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
      child: ValueListenableBuilder<String?>(
        builder: (_, value, child) {
          if (value != null) {
            _uriController.text = value;
            kLastWalletConnectUriNotifier.value = null;
          }
          return Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              SizedBox(
                height: 120.0,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const CircleAvatar(
                      backgroundColor: Colors.white12,
                      child: Icon(
                        Icons.link,
                        color: AppColors.znnColor,
                      ),
                    ),
                    Form(
                      key: _uriKey,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      child: InputField(
                        validator: (value) {
                          if (WalletConnectUri.tryParse(value ?? '') != null) {
                            return null;
                          } else {
                            return 'URI invalid';
                          }
                        },
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
                  ],
                ),
              ),
              MyOutlinedButton(
                text: 'Connect',
                onPressed:
                    WalletConnectUri.tryParse(_uriController.text) != null
                        ? () {
                            _pairWithDapp(
                              Uri.parse(_uriController.text),
                            );
                          }
                        : null,
                minimumSize: kLoadingButtonMinSize,
              ),
            ],
          );
        },
        valueListenable: kLastWalletConnectUriNotifier,
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
}
