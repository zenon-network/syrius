import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/peers/peers.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// Displays the table of peers currently connected to the node.
class PeersCard extends StatelessWidget {
  /// Creates a [PeersCard].
  const PeersCard({super.key, this._peersBloc});

  final PeersBloc? _peersBloc;

  @override
  Widget build(BuildContext context) {
    final PeersBloc? injected = _peersBloc;
    if (injected != null) {
      return BlocProvider<PeersBloc>.value(
        value: injected,
        child: const _View(),
      );
    }

    return BlocProvider<PeersBloc>(
      create: (_) => PeersBloc(zenon: zenon!)..add(const PeersRequested()),
      child: const _View(),
    );
  }
}

class _View extends StatelessWidget {
  const _View();

  @override
  Widget build(BuildContext context) {
    return NewCardScaffold(
      data: _buildCardData(context: context),
      onRefreshPressed: () {
        context.read<PeersBloc>().add(const PeersRequested());
      },
      body: BlocBuilder<PeersBloc, PeersState>(
        builder: (BuildContext context, PeersState state) {
          return switch (state) {
            PeersInitial() || PeersLoading() => const SyriusLoadingWidget(),
            PeersFailure(:final SyriusException exception) => SyriusErrorWidget(
              exception,
            ),
            PeersPopulated(:final List<Peer> peers) => _Populated(peers: peers),
          };
        },
      ),
    );
  }

  CardData _buildCardData({required BuildContext context}) => CardData(
    title: context.l10n.peers,
    description: context.l10n.displaysConnectedNetworkPeers,
  );
}

class _Populated extends StatelessWidget {
  const _Populated({required this._peers});

  final List<Peer> _peers;

  @override
  Widget build(BuildContext context) {
    return CustomTable<Peer>(
      items: _peers,
      headerColumns: _buildHeaderColumns(context),
      generateRowCells: (Peer peer, bool isSelected, {Object? model}) {
        return <Widget>[
          CustomTableCell.withText(context, peer.ip),
          CustomTableCell.withMarquee(
            peer.publicKey,
            showCopyToClipboardIcon: false,
          ),
        ];
      },
    );
  }

  List<CustomHeaderColumn> _buildHeaderColumns(BuildContext context) {
    final String ipColumn = context.l10n.ip;
    final String publicKeyColumn = context.l10n.publicKey;
    return <CustomHeaderColumn>[
      CustomHeaderColumn(
        columnName: ipColumn,
        onSortArrowsPressed: (_) {
          context.read<PeersBloc>().add(
            const PeersSortToggled(column: PeersSortColumn.ip),
          );
        },
        contentAlign: MainAxisAlignment.center,
      ),
      CustomHeaderColumn(
        columnName: publicKeyColumn,
        onSortArrowsPressed: (_) {
          context.read<PeersBloc>().add(
            const PeersSortToggled(column: PeersSortColumn.publicKey),
          );
        },
        contentAlign: MainAxisAlignment.center,
      ),
    ];
  }
}
