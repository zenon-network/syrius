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

const String _kWidgetTitle = 'WalletConnect Pairing List';
const String _kWidgetDescription =
    'A pairing refers to the initial process of establishing a secure connection between a wallet and the dApp.'
    'Once the pairing is complete, a session is established, which allows the dApp to communicate with the wallet '
    'securely over the Internet';

class WalletConnectPairingsCard extends StatefulWidget {
  const WalletConnectPairingsCard({Key? key}) : super(key: key);

  @override
  State<WalletConnectPairingsCard> createState() =>
      _WalletConnectPairingsCardState();
}

class _WalletConnectPairingsCardState extends State<WalletConnectPairingsCard> {
  final WalletConnectPairingsBloc _pairingsBloc =
      sl.get<WalletConnectPairingsBloc>();

  @override
  void initState() {
    // Initialize WalletConnect client
    sl.get<WalletConnectService>().initClient();
    super.initState();
  }

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
      disposeBloc: false,
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
      sl<WalletConnectSessionsBloc>().refreshResults();
    } catch (e) {
      sl<NotificationsBloc>().addErrorNotification(
        e,
        'Error while deactivating pair',
      );
    }
  }
}
