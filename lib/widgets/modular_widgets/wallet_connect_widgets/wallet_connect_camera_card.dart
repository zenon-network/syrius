import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

const String _kWidgetTitle = 'Camera QR Scanner';
// TODO: change description
const String _kWidgetDescription = 'Description';

class WalletConnectCameraCard extends StatefulWidget {
  const WalletConnectCameraCard({Key? key}) : super(key: key);

  @override
  State<WalletConnectCameraCard> createState() =>
      _WalletConnectCameraCardState();
}

class _WalletConnectCameraCardState extends State<WalletConnectCameraCard> {
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
        children: const [
          CircleAvatar(
            radius: 60.0,
            backgroundColor: Colors.white12,
            child: Icon(
              Icons.camera_alt_outlined,
              color: AppColors.znnColor,
              size: 60.0,
            ),
          ),
          MyOutlinedButton(
            text: 'Scan QR',
            onPressed: null,
            minimumSize: kLoadingButtonMinSize,
          ),
        ],
      ),
    );
  }
}
