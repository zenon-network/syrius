import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:walletconnect_flutter_v2/walletconnect_flutter_v2.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/wallet_connect/wallet_connect_pairings_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

const String _kWidgetTitle = 'WalletConnect Pairings';
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
    return Expanded(
      child: _buildPairingsTable(),
    );
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
        ),
        InfiniteScrollTableHeaderColumn(
          columnName: 'Expiration',
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
          ),
          InfiniteScrollTableCell.withText(
            context,
            _formatExpiryDateTime(pairingInfo.expiry).toString(),
          ),
        ];
      },
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
}
