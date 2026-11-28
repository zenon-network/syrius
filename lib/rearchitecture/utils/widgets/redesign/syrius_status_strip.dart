import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:lottie/lottie.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// Persistent bottom telemetry strip displaying node sync status, momentum
/// height, node URL, chain ID, active PoW plasma generation, and pending tx.
class SyriusStatusStrip extends StatefulWidget {
  /// Creates a [SyriusStatusStrip].
  const SyriusStatusStrip({
    required this.onNodePressed,
    required this.onQuickNavPressed,
    this.onUpdatePressed,
    super.key,
  });

  /// Navigates to Settings -> Node when the node telemetry cluster is clicked.
  final VoidCallback onNodePressed;

  /// Opens the Ctrl+K quick navigation modal.
  final VoidCallback onQuickNavPressed;

  /// Optional callback when an update action is tapped.
  final VoidCallback? onUpdatePressed;

  @override
  State<SyriusStatusStrip> createState() => _SyriusStatusStripState();
}

class _SyriusStatusStripState extends State<SyriusStatusStrip> {
  static final NumberFormat _intFormat = NumberFormat.decimalPattern();
  Timer? _powTicker;
  DateTime? _powStartedAt;
  int _powElapsedSeconds = 0;

  @override
  void dispose() {
    _powTicker?.cancel();
    super.dispose();
  }

  void _syncPowTimer(bool isGenerating) {
    if (isGenerating) {
      if (_powStartedAt == null) {
        _powStartedAt = DateTime.now();
        _powElapsedSeconds = 0;
        _powTicker?.cancel();
        _powTicker = Timer.periodic(const Duration(seconds: 1), (_) {
          if (!mounted || _powStartedAt == null) {
            return;
          }
          setState(() {
            _powElapsedSeconds = DateTime.now()
                .difference(_powStartedAt!)
                .inSeconds;
          });
        });
      }
    } else if (_powStartedAt != null) {
      _powStartedAt = null;
      _powElapsedSeconds = 0;
      _powTicker?.cancel();
      _powTicker = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final SyriusThemeTokens tokens = context.syriusTheme;
    final PowGeneratingStatusBloc? powBloc =
        sl.isRegistered<PowGeneratingStatusBloc>()
        ? sl<PowGeneratingStatusBloc>()
        : null;

    return SyriusCard(
      borderRadius: 10,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      child: Row(
        children: <Widget>[
          _buildNodeTelemetry(context, tokens),
          const SizedBox(width: 16),
          Expanded(child: _buildLiveActivityStatus(context, tokens, powBloc)),
          const SizedBox(width: 12),
          _buildRightActions(context, tokens),
        ],
      ),
    );
  }

  Widget _buildNodeTelemetry(BuildContext context, SyriusThemeTokens tokens) {
    return BlocBuilder<NodeSyncStatusCubit, NodeSyncStatusState>(
      builder: (BuildContext context, NodeSyncStatusState state) {
        final SyncInfo? info = state.data?.second;
        final SyncState syncState = info?.state ?? SyncState.unknown;
        final int height = info?.currentHeight ?? 0;

        final Color dotColor = switch (state.status) {
          TimerStatus.failure => tokens.error,
          TimerStatus.success when syncState == SyncState.syncDone =>
            tokens.znnGreen,
          TimerStatus.success when syncState == SyncState.syncing =>
            tokens.warning,
          TimerStatus.success when height > 0 => tokens.znnGreen,
          _ => tokens.textMuted,
        };

        final String nodeDisplay =
            kCurrentNode == kEmbeddedNode || kCurrentNode == null
            ? kLocalhostDefaultNodeUrl
            : kCurrentNode!;
        final int chainId = kNodeChainId ?? getChainIdentifier();

        return MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: widget.onNodePressed,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  height > 0 ? '#${_intFormat.format(height)}' : '—',
                  style: tokens.monoStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: tokens.textPrimary,
                  ),
                ),
                const SizedBox(width: 14),
                Text(
                  '${context.l10n.node} $nodeDisplay',
                  style: tokens.monoStyle(
                    fontSize: 11.5,
                    color: tokens.textSecondary,
                  ),
                ),
                const SizedBox(width: 14),
                Text(
                  'Chain $chainId',
                  style: tokens.monoStyle(
                    fontSize: 11.5,
                    color: tokens.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLiveActivityStatus(
    BuildContext context,
    SyriusThemeTokens tokens,
    PowGeneratingStatusBloc? powBloc,
  ) {
    if (powBloc == null) {
      return const SizedBox.shrink();
    }
    return BlocConsumer<PowGeneratingStatusBloc, PowGeneratingStatusState>(
      bloc: powBloc,
      listener: (_, PowGeneratingStatusState state) =>
          _syncPowTimer(state.isGenerating),
      builder: (BuildContext context, PowGeneratingStatusState powState) {
        if (powState.isGenerating) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              SizedBox.square(
                dimension: 16,
                child: Lottie.asset(
                  'assets/lottie/ic_anim_plasma_generation.json',
                  repeat: true,
                  errorBuilder: (_, _, _) =>
                      Icon(Icons.bolt, size: 14, color: tokens.znnGreen),
                ),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  '${context.l10n.generatingPlasma} ${_powElapsedSeconds}s',
                  overflow: TextOverflow.ellipsis,
                  style: tokens.monoStyle(
                    fontSize: 11.5,
                    color: tokens.textPrimary,
                  ),
                ),
              ),
            ],
          );
        }

        return BlocBuilder<
          PendingTransactionsBloc,
          InfiniteListState<AccountBlock>
        >(
          builder:
              (BuildContext context, InfiniteListState<AccountBlock> pending) {
                final List<AccountBlock> items =
                    pending.data ?? const <AccountBlock>[];
                if (items.isEmpty) {
                  return const SizedBox.shrink();
                }
                final AccountBlock first = items.first;
                final String symbol = first.token?.symbol ?? kZnnCoin.symbol;
                final int decimals = first.token?.decimals ?? kZnnCoin.decimals;
                final String amount = first.amount.addDecimals(decimals);
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: tokens.qsrBlue,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 7),
                    Flexible(
                      child: Text(
                        '${context.l10n.pending}: $amount $symbol',
                        overflow: TextOverflow.ellipsis,
                        style: tokens.monoStyle(
                          fontSize: 11.5,
                          color: tokens.textSecondary,
                        ),
                      ),
                    ),
                  ],
                );
              },
        );
      },
    );
  }

  Widget _buildRightActions(BuildContext context, SyriusThemeTokens tokens) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        InkWell(
          onTap: widget.onQuickNavPressed,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: tokens.surfaceSubtle,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: tokens.border),
            ),
            child: Text(
              'Ctrl K',
              style: tokens.monoStyle(fontSize: 10.5, color: tokens.textMuted),
            ),
          ),
        ),
        if (widget.onUpdatePressed != null) ...<Widget>[
          const SizedBox(width: 8),
          SyriusPillButton(
            label: context.l10n.update,
            compact: true,
            height: 24,
            onPressed: widget.onUpdatePressed,
          ),
        ],
      ],
    );
  }
}
