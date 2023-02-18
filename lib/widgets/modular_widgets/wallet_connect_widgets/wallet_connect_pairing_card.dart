import 'package:flutter/material.dart';
import 'package:walletconnect_flutter_v2/apis/core/pairing/utils/pairing_models.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/model/database/notification_type.dart';
import 'package:zenon_syrius_wallet_flutter/model/database/wallet_notification.dart';
import 'package:zenon_syrius_wallet_flutter/services/wallet_connect_service.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

class WalletConnectPairingCard extends StatefulWidget {
  const WalletConnectPairingCard({Key? key}) : super(key: key);

  @override
  State<WalletConnectPairingCard> createState() =>
      _WalletConnectPairingCardState();
}

class _WalletConnectPairingCardState extends State<WalletConnectPairingCard> {
  final TextEditingController _uriController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return CardScaffold(
      title: 'WalletConnect Pairing',
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
            hintText: 'dApp URI',
          ),
          kVerticalSpacing,
          MyOutlinedButton(
            text: 'Connect',
            onPressed: () {
              _showPairingDialog(Uri.parse(_uriController.text));
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
      final pairingInfo = await sl.get<WalletConnectService>().pair(uri);
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
            title: 'Successfully paired with ${pairingInfo.peerMetadata?.name ?? 'dApp'}',
            timestamp: DateTime.now().millisecondsSinceEpoch,
            details:
                'Successfully paired with ${pairingInfo.peerMetadata?.name ?? 'dApp'} '
                'through WalletConnect',
            type: NotificationType.paymentSent,
          ),
        );
  }
}
