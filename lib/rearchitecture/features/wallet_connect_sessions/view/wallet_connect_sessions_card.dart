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

/// Displays active WalletConnect sessions and allows disconnecting them.
class WalletConnectSessionsCard extends StatelessWidget {
  /// Creates a [WalletConnectSessionsCard].
  const WalletConnectSessionsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<WalletConnectSessionsBloc>(
      create: (_) => WalletConnectSessionsBloc(
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
    return BlocListener<WalletConnectSessionsBloc, WalletConnectSessionsState>(
      listenWhen:
          (
            WalletConnectSessionsState previous,
            WalletConnectSessionsState current,
          ) =>
              current.error != null &&
              previous.errorCount != current.errorCount,
      listener: (BuildContext context, WalletConnectSessionsState state) {
        final Object? error = state.error;
        if (error != null) {
          unawaited(
            NotificationUtils.sendNotificationError(
              error,
              context.l10n.errorWhileDisconnectingSession,
            ),
          );
        }
      },
      child: NewCardScaffold(
        data: CardData(
          title: context.l10n.walletConnectSessionsList,
          description: context.l10n.walletConnectSessionDescription,
        ),
        onRefreshPressed: () {
          context.read<WalletConnectSessionsBloc>().add(
            const WalletConnectSessionsRefreshRequested(),
          );
        },
        body:
            BlocBuilder<WalletConnectSessionsBloc, WalletConnectSessionsState>(
              builder:
                  (BuildContext context, WalletConnectSessionsState state) {
                    return _Populated(
                      sessions: state.sessions,
                      disconnectingTopics: state.disconnectingTopics,
                    );
                  },
            ),
      ),
    );
  }
}

class _Populated extends StatelessWidget {
  const _Populated({
    required this._sessions,
    required this._disconnectingTopics,
  });

  final List<SessionData> _sessions;
  final Set<String> _disconnectingTopics;

  @override
  Widget build(BuildContext context) {
    return InfiniteScrollTable<SessionData>(
      itemKeyGenerator: (SessionData session) =>
          ValueKey<String>(session.topic),
      items: _sessions,
      hasReachedMax: true,
      onScrollReachedBottom: () {},
      columns: const <InfiniteScrollTableColumnType>[
        .name,
        .url,
        .pairingTopic,
        .sessionTopic,
        .expiration,
        .acknowledged,
        .blank,
      ],
      generateRowCells: (SessionData session) =>
          _buildRowCells(context: context, session: session),
    );
  }

  List<Widget> _buildRowCells({
    required BuildContext context,
    required SessionData session,
  }) {
    final String name = walletConnectDisplayValue(
      session.peer.metadata.name,
      context.l10n.empty,
    );

    return <Widget>[
      InfiniteScrollTableCell.withText(content: name),
      InfiniteScrollTableCell(
        flex: 2,
        child: _buildUrlCell(
          context: context,
          rawUrl: session.peer.metadata.url,
        ),
      ),
      InfiniteScrollTableCell.withText(
        content: session.pairingTopic.short,
        tooltipMessage: session.pairingTopic,
        textToBeCopied: session.pairingTopic,
      ),
      InfiniteScrollTableCell.withText(
        content: session.topic.short,
        tooltipMessage: session.topic,
        textToBeCopied: session.topic,
      ),
      InfiniteScrollTableCell(
        child: Center(
          child: Text(
            formatWalletConnectExpiry(session.expiry),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ),
      InfiniteScrollTableCell.withText(
        content: session.acknowledged
            ? context.l10n.yes.capitalize()
            : context.l10n.no.capitalize(),
      ),
      InfiniteScrollTableCell(
        child: _buildDisconnectCell(context: context, session: session),
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

  Widget _buildDisconnectCell({
    required BuildContext context,
    required SessionData session,
  }) {
    if (_disconnectingTopics.contains(session.topic)) {
      return const Center(
        child: SyriusLoadingWidget(size: 18, strokeWidth: 2, padding: 2),
      );
    }

    return ClearIcon(
      onPressed: () {
        context.read<WalletConnectSessionsBloc>().add(
          WalletConnectSessionDisconnectRequested(topic: session.topic),
        );
      },
      context: context,
    );
  }
}
