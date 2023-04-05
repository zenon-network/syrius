import 'package:flutter/material.dart';
import 'package:stacked/stacked.dart';
import 'package:walletconnect_flutter_v2/walletconnect_flutter_v2.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/wallet_connect/wallet_connect_pairings_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/model/database/notification_type.dart';
import 'package:zenon_syrius_wallet_flutter/model/database/wallet_notification.dart';
import 'package:zenon_syrius_wallet_flutter/services/wallet_connect_service.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

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
  final TextEditingController _uriController = TextEditingController();

  late WalletConnectPairingsBloc _pairingsBloc;

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
          kVerticalSpacing,
          MyOutlinedButton(
            text: 'Refresh pairings',
            onPressed: () {
              _pairingsBloc.getPairings();
            },
            minimumSize: kLoadingButtonMinSize,
          ),
          kVerticalSpacing,
          Expanded(
            child: ViewModelBuilder<WalletConnectPairingsBloc>.reactive(
              viewModelBuilder: () => WalletConnectPairingsBloc(),
              onViewModelReady: (model) {
                _pairingsBloc = model;
                model.getPairings();
              },
              builder: (_, model, __) => StreamBuilder<List<PairingInfo>?>(
                stream: model.stream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return SyriusErrorWidget(snapshot.error!);
                  } else if (snapshot.hasData) {
                    return _showPairings(snapshot.data!);
                  }
                  return const SyriusLoadingWidget();
                },
              ),
            ),
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
      print('Pairing info: ${pairingInfo.toJson()}');
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

  Widget _showPairings(List<PairingInfo> pairings) {
    return ListView.builder(
      itemCount: pairings.length,
      itemBuilder: (_, index) {
        debugPrint('Pairings length: ${pairings.length}');
        debugPrint('Index: $index');
        return Text(pairings.elementAt(index).toJson().toString());
      },
    );
  }
}
