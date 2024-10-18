import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class PeersWidget extends StatefulWidget {
  const PeersWidget({super.key});

  @override
  State<PeersWidget> createState() => _PeersWidget();
}

class _PeersWidget extends State<PeersWidget> {
  bool _sortAscending = true;

  PeersBloc? _peersBloc;

  List<Peer>? _peers;

  @override
  void initState() {
    _peersBloc = PeersBloc();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return CardScaffold(
      title: 'Peers',
      description:
          'This card displays information about connected network peers',
      childBuilder: _getStreamBuilder,
    );
  }

  Widget _getTable() {
    return CustomTable<Peer>(
      items: _peers,
      headerColumns: [
        CustomHeaderColumn(
          columnName: 'IP',
          onSortArrowsPressed: _onSortArrowsPressed,
          contentAlign: MainAxisAlignment.center,
        ),
        CustomHeaderColumn(
          columnName: 'Public Key',
          onSortArrowsPressed: _onSortArrowsPressed,
          contentAlign: MainAxisAlignment.center,
        ),
      ],
      generateRowCells: (peer, isSelected, {SentinelsListBloc? model}) {
        return [
          CustomTableCell.withText(context, peer.ip),
          CustomTableCell.withMarquee(
            peer.publicKey,
            showCopyToClipboardIcon: false,
          ),
        ];
      },
    );
  }

  Widget _getStreamBuilder() {
    return StreamBuilder<NetworkInfo>(
      stream: _peersBloc!.stream,
      builder: (_, snapshot) {
        if (snapshot.hasData) {
          _peers = snapshot.data!.peers;
          return _getTable();
        } else if (snapshot.hasError) {
          return SyriusErrorWidget(snapshot.error!);
        }
        return const SyriusLoadingWidget();
      },
    );
  }

  void _onSortArrowsPressed(String columnName) {
    switch (columnName) {
      case 'IP':
        _sortAscending
            ? _peers!.sort((a, b) => a.ip.compareTo(b.ip))
            : _peers!.sort((a, b) => b.ip.compareTo(a.ip));
      case 'Public Key':
        _sortAscending
            ? _peers!.sort((a, b) => a.publicKey.compareTo(b.publicKey))
            : _peers!.sort((a, b) => b.publicKey.compareTo(a.publicKey));
      default:
        _sortAscending
            ? _peers!.sort((a, b) => a.ip.compareTo(b.ip))
            : _peers!.sort((a, b) => b.ip.compareTo(a.ip));
        break;
    }
    setState(() {
      _sortAscending = !_sortAscending;
    });
  }

  @override
  void dispose() {
    _peersBloc!.dispose();
    super.dispose();
  }
}
