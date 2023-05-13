import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:walletconnect_flutter_v2/walletconnect_flutter_v2.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/wallet_connect/wallet_connect_pairings_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/wallet_connect/wallet_connect_sessions_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/services/wallet_connect_service.dart';
import 'package:zenon_syrius_wallet_flutter/utils/extensions.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/icons/clear_icon.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

const String _kWidgetTitle = 'WalletConnect Sessions List';
// TODO: change description
const String _kWidgetDescription = 'Description';

class WalletConnectSessionsCard extends StatefulWidget {
  const WalletConnectSessionsCard({Key? key}) : super(key: key);

  @override
  State<WalletConnectSessionsCard> createState() =>
      _WalletConnectSessionsCardState();
}

class _WalletConnectSessionsCardState extends State<WalletConnectSessionsCard> {
  final WalletConnectSessionsBloc _sessionsBloc = WalletConnectSessionsBloc();

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
      disposeBloc: true,
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
        InfiniteScrollTableHeaderColumn(
          columnName: '',
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
          InfiniteScrollTableCell(
            _buildDeactivatePairingIcon(sessionData),
          ),
        ];
      },
    );
  }

  ClearIcon _buildDeactivatePairingIcon(SessionData sessionData) {
    return ClearIcon(
      onPressed: () => _onDeactivatePairingIconPressed(sessionData),
      context: context,
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

  Future<void> _onDeactivatePairingIconPressed(SessionData sessionData) async {
    try {
      await sl<WalletConnectService>().disconnectSession(
        topic: sessionData.topic,
      );
      _sessionsBloc.refreshResults();
    } catch (e) {
      sl<NotificationsBloc>().addErrorNotification(
        e,
        'Error while deactivating pair',
      );
    }
  }
}
