import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

class WalletConnectCard extends StatefulWidget {
  const WalletConnectCard({Key? key}) : super(key: key);

  @override
  State<WalletConnectCard> createState() => _WalletConnectCardState();
}

class _WalletConnectCardState extends State<WalletConnectCard> {
  final TextEditingController _uriController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return CardScaffold(
      title: 'WalletConnect URI',
      // TODO: to be changed
      description: 'Description',
      childBuilder: () => _getCardBody(context),
    );
  }

  Widget _getCardBody(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(15.0),
      child: Column(
        children: [
          InputField(
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
            hintText: 'WalletConnect URI',
          ),
          kVerticalSpacing,
          MyOutlinedButton(
            text: 'Connect',
            onPressed: _createConnection,
            minimumSize: kLoadingButtonMinSize,
          ),
        ],
      ),
    );
  }

  Future<void> _createConnection() async {
    var shouldConnect = true;
    if (shouldConnect) {
      //TODO: init Wallet Connect connection
    } else {
      showWarningDialog(
        buttonText: 'Ok',
        context: context,
        title: 'Pairing through WalletConnect',
        description:
            //TODO: to add real dApp name
        'You are already paired with dummy-name-of-dApp',
        onActionButtonPressed: () {
          Navigator.pop(context);
        },
      );
    }
  }
}
