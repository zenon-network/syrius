import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:walletconnect_flutter_v2/walletconnect_flutter_v2.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/wallet_connect/wallet_connect_sessions_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/utils/extensions.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

const String _kWidgetTitle = 'WalletConnect Sessions List';
const String _kWidgetDescription =
    'A session refers to a live connection between a user\'s wallet and a dApp '
    'A session allows the dApp to communicate with the wallet '
    'securely over the Internet';

class WalletConnectSessionsCard extends StatefulWidget {
  const WalletConnectSessionsCard({Key? key}) : super(key: key);

  @override
  State<WalletConnectSessionsCard> createState() =>
      _WalletConnectSessionsCardState();
}

class _WalletConnectSessionsCardState extends State<WalletConnectSessionsCard> {
  final WalletConnectSessionsBloc _sessionsBloc =
      sl.get<WalletConnectSessionsBloc>();

  @override
  Widget build(BuildContext context) {
    return CardScaffold(
      title: _kWidgetTitle,
      description: _kWidgetDescription,
      childBuilder: () => _getCardBody(),
      onRefreshPressed: () => _sessionsBloc.refreshResults(),
    );
  }

  Widget _getCardBody() {
    return _buildPairingsTable();
  }

  Widget _buildPairingsTable() {
    return InfiniteScrollTable<SessionData>(
      disposeBloc: false,
      bloc: _sessionsBloc,
      headerColumns: const [
        InfiniteScrollTableHeaderColumn(
          columnName: 'Name',
        ),
        InfiniteScrollTableHeaderColumn(
          columnName: 'URL',
          flex: 2,
        ),
        InfiniteScrollTableHeaderColumn(
          columnName: 'Pairing Topic',
        ),
        InfiniteScrollTableHeaderColumn(
          columnName: 'Session Topic',
        ),
        InfiniteScrollTableHeaderColumn(
          columnName: 'Expiration',
        ),
        InfiniteScrollTableHeaderColumn(
          columnName: 'Acknowledged',
        ),
      ],
      generateRowCells: (sessionData, bool isSelected) {
        return [
          InfiniteScrollTableCell.withText(
            context,
            sessionData.peer.metadata.name,
          ),
          InfiniteScrollTableCell(
            _buildTableUrlWidget(sessionData.peer.metadata.url),
            flex: 2,
          ),
          isSelected
              ? InfiniteScrollTableCell.withMarquee(
                  sessionData.pairingTopic,
                )
              : InfiniteScrollTableCell.withText(
                  context,
                  sessionData.pairingTopic.short,
                ),
          isSelected
              ? InfiniteScrollTableCell.withMarquee(
                  sessionData.topic,
                )
              : InfiniteScrollTableCell.withText(
                  context,
                  sessionData.topic.short,
                ),
          InfiniteScrollTableCell.withText(
            context,
            _formatExpiryDateTime(sessionData.expiry).toString(),
          ),
          InfiniteScrollTableCell.withText(
            context,
            sessionData.acknowledged ? 'Yes' : 'No',
          ),
        ];
      },
    );
  }

  Row _buildTableUrlWidget(String? peerUrl) {
    return Row(
      children: [
        Text(peerUrl ?? 'Empty'),
        Visibility(
          visible: peerUrl != null,
          child: LinkIcon(
            url: peerUrl!,
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
