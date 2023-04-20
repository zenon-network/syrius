import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:walletconnect_flutter_v2/walletconnect_flutter_v2.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/wallet_connect/wallet_connect_pairings_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/services/wallet_connect_service.dart';
import 'package:zenon_syrius_wallet_flutter/utils/extensions.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/icons/clear_icon.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

const String _kWidgetTitle = 'WalletConnect Pairing List';
// TODO: change description
const String _kWidgetDescription = 'Description';

class WalletConnectPairingsCard extends StatefulWidget {
  const WalletConnectPairingsCard({Key? key}) : super(key: key);

  @override
  State<WalletConnectPairingsCard> createState() =>
      _WalletConnectPairingsCardState();
}

class _WalletConnectPairingsCardState extends State<WalletConnectPairingsCard> {
  final WalletConnectPairingsBloc _pairingsBloc = WalletConnectPairingsBloc();

  @override
  Widget build(BuildContext context) {
    return CardScaffold(
      title: _kWidgetTitle,
      description: _kWidgetDescription,
      childBuilder: () => _getCardBody(),
      onRefreshPressed: () => _pairingsBloc.refreshResults(),
    );
  }

  Widget _getCardBody() {
    return _buildPairingsTable();
  }

  Widget _buildPairingsTable() {
    return InfiniteScrollTable<PairingInfo>(
      disposeBloc: true,
      bloc: _pairingsBloc,
      headerColumns: const [
        InfiniteScrollTableHeaderColumn(
          columnName: 'Name',
        ),
        InfiniteScrollTableHeaderColumn(
          columnName: 'URL',
          flex: 2,
        ),
        InfiniteScrollTableHeaderColumn(
          columnName: 'Topic',
        ),
        InfiniteScrollTableHeaderColumn(
          columnName: 'Expiration',
        ),
        InfiniteScrollTableHeaderColumn(
          columnName: 'Active',
        ),
        InfiniteScrollTableHeaderColumn(
          columnName: '',
        ),
      ],
      generateRowCells: (pairingInfo, bool isSelected) {
        return [
          InfiniteScrollTableCell.withText(
            context,
            pairingInfo.peerMetadata?.name ?? 'Empty',
          ),
          InfiniteScrollTableCell(
            _buildTableUrlWidget(pairingInfo),
            flex: 2,
          ),
          isSelected
              ? InfiniteScrollTableCell.withMarquee(
            pairingInfo.topic,
          )
              : InfiniteScrollTableCell.withText(
            context,
            pairingInfo.topic.short,
          ),
          InfiniteScrollTableCell.withText(
            context,
            _formatExpiryDateTime(pairingInfo.expiry).toString(),
          ),
          InfiniteScrollTableCell.withText(
            context,
            pairingInfo.active ? 'Yes' : 'No',
          ),
          InfiniteScrollTableCell(
            _buildDeactivatePairingIcon(pairingInfo),
          ),
        ];
      },
    );
  }

  ClearIcon _buildDeactivatePairingIcon(PairingInfo pairingInfo) {
    return ClearIcon(
      onPressed: () => _onDeactivatePairingIconPressed(pairingInfo),
      context: context,
    );
  }

  Row _buildTableUrlWidget(PairingInfo pairingInfo) {
    return Row(
      children: [
        Text(pairingInfo.peerMetadata?.url ?? 'Empty'),
        Visibility(
          visible: pairingInfo.peerMetadata?.url != null,
          child: LinkIcon(
            url: pairingInfo.peerMetadata?.url ?? 'Empty',
            context: context,
          ),
        ),
      ],
    );
  }

  String _formatExpiryDateTime(int expirySeconds) {
    final expiryDateTime =
    DateTime.fromMillisecondsSinceEpoch(expirySeconds * 1000);

    return DateFormat('MMM dd, y HH:mm:ss').format(expiryDateTime);
  }

  Future<void> _onDeactivatePairingIconPressed(PairingInfo pairingInfo) async {
    try {
      await sl<WalletConnectService>().deactivatePairing(
        topic: pairingInfo.topic,
      );
      _pairingsBloc.refreshResults();
    } catch (e) {
      sl<NotificationsBloc>().addErrorNotification(
        e,
        'Error while deactivating pair',
      );
    }
  }
}
