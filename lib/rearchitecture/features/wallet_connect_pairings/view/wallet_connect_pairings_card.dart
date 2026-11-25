import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:reown_walletkit/reown_walletkit.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/services/i_web3wallet_service.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/icons/clear_icon.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart'
    hide
        InfiniteScrollTable,
        InfiniteScrollTableCell,
        InfiniteScrollTableHeaderColumn;

/// Displays WalletConnect pairings and allows deactivating individual pairings.
class WalletConnectPairingsCard extends StatelessWidget {
  /// Creates a [WalletConnectPairingsCard].
  const WalletConnectPairingsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<WalletConnectPairingsBloc>(
      create: (_) => WalletConnectPairingsBloc(
        web3WalletService: sl<IWeb3WalletService>(),
      ),
      child: const _View(),
    );
  }
}

class _View extends StatelessWidget {
  const _View();

  @override
  Widget build(BuildContext context) {
    return BlocListener<WalletConnectPairingsBloc, WalletConnectPairingsState>(
      listenWhen:
          (
            WalletConnectPairingsState previous,
            WalletConnectPairingsState current,
          ) =>
              current.error != null &&
              previous.errorCount != current.errorCount,
      listener: (BuildContext context, WalletConnectPairingsState state) {
        final Object? error = state.error;
        if (error != null) {
          unawaited(
            NotificationUtils.sendNotificationError(
              error,
              context.l10n.errorWhileDeactivatingPairing,
            ),
          );
        }
      },
      child: NewCardScaffold(
        data: CardData(
          title: context.l10n.walletConnectPairingList,
          description: context.l10n.walletConnectPairingDescription,
        ),
        onRefreshPressed: () {
          context.read<WalletConnectPairingsBloc>().add(
            const WalletConnectPairingsRefreshRequested(),
          );
        },
        body:
            BlocBuilder<WalletConnectPairingsBloc, WalletConnectPairingsState>(
              builder:
                  (BuildContext context, WalletConnectPairingsState state) {
                    return _Populated(
                      pairings: state.pairings,
                      deactivatingTopics: state.deactivatingTopics,
                    );
                  },
            ),
      ),
    );
  }
}

class _Populated extends StatelessWidget {
  const _Populated({
    required this._pairings,
    required this._deactivatingTopics,
  });

  final List<PairingInfo> _pairings;
  final Set<String> _deactivatingTopics;

  @override
  Widget build(BuildContext context) {
    return InfiniteScrollTable<PairingInfo>(
      itemKeyGenerator: (PairingInfo pairing) =>
          ValueKey<String>(pairing.topic),
      items: _pairings,
      hasReachedMax: true,
      onScrollReachedBottom: () {},
      columns: const <InfiniteScrollTableColumnType>[
        .name,
        .url,
        .topic,
        .expiration,
        .active,
        .blank,
      ],
      generateRowCells: (PairingInfo pairing) =>
          _buildRowCells(context: context, pairing: pairing),
    );
  }

  List<Widget> _buildRowCells({
    required BuildContext context,
    required PairingInfo pairing,
  }) {
    final String name = walletConnectDisplayValue(
      pairing.peerMetadata?.name,
      context.l10n.empty,
    );

    return <Widget>[
      InfiniteScrollTableCell.withText(content: name),
      InfiniteScrollTableCell(
        flex: 2,
        child: _buildUrlCell(
          context: context,
          rawUrl: pairing.peerMetadata?.url,
        ),
      ),
      InfiniteScrollTableCell.withText(
        content: pairing.topic.short,
        tooltipMessage: pairing.topic,
        textToBeCopied: pairing.topic,
      ),
      InfiniteScrollTableCell(
        child: Center(
          child: Text(
            formatWalletConnectExpiry(pairing.expiry),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ),
      InfiniteScrollTableCell.withText(
        content: pairing.active
            ? context.l10n.yes.capitalize()
            : context.l10n.no.capitalize(),
      ),
      InfiniteScrollTableCell(
        child: _buildDeactivateCell(context: context, pairing: pairing),
      ),
    ];
  }

  Widget _buildUrlCell({
    required BuildContext context,
    required String? rawUrl,
  }) {
    final String? safeUrl = sanitizeWalletConnectHttpUrl(rawUrl);
    final String label = walletConnectDisplayValue(rawUrl, context.l10n.empty);

    return Row(
      children: <Widget>[
        Flexible(
          child: Text(label, overflow: TextOverflow.ellipsis, maxLines: 1),
        ),
        if (safeUrl != null) LinkIcon(url: safeUrl),
      ],
    );
  }

  Widget _buildDeactivateCell({
    required BuildContext context,
    required PairingInfo pairing,
  }) {
    if (_deactivatingTopics.contains(pairing.topic)) {
      return const Center(
        child: SyriusLoadingWidget(size: 18, strokeWidth: 2, padding: 2),
      );
    }

    return ClearIcon(
      onPressed: () {
        context.read<WalletConnectPairingsBloc>().add(
          WalletConnectPairingDeactivateRequested(topic: pairing.topic),
        );
      },
      context: context,
    );
  }
}
