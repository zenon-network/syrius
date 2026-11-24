import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart'
    hide InfiniteScrollTable, InfiniteScrollTableCell;
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// Displays the P2P swaps conducted with this wallet.
class P2pSwapsCard extends StatelessWidget {
  /// Creates a [P2pSwapsCard].
  const P2pSwapsCard({super.key});

  @override
  Widget build(BuildContext context) {
    final P2pSwapRepository<HtlcSwap> swapRepository = sl<HtlcSwapRepository>();

    return BlocProvider<P2pSwapsCubit>(
      create: (_) => P2pSwapsCubit(
        swapRepository: swapRepository,
      ),
      child: const _View(),
    );
  }
}

class _View extends StatelessWidget {
  const _View();

  @override
  Widget build(BuildContext context) {
    return NewCardScaffold(
      data: CardData(
        title: context.l10n.p2pSwaps,
        description: context.l10n.p2pSwapsConductedWithWallet,
      ),
      body: BlocBuilder<P2pSwapsCubit, P2pSwapsState>(
        builder: (BuildContext context, P2pSwapsState state) {
          return switch (state) {
            P2pSwapsLoading() => const SyriusLoadingWidget(),
            P2pSwapsFailure(:final SyriusException exception) =>
              SyriusErrorWidget(exception),
            P2pSwapsPopulated(:final List<P2pSwap> swaps) => _Populated(
              swaps: swaps,
            ),
          };
        },
      ),
    );
  }
}

class _Populated extends StatelessWidget {
  const _Populated({
    required this._swaps,
  });

  final List<P2pSwap> _swaps;

  @override
  Widget build(BuildContext context) {
    return InfiniteScrollTable<P2pSwap>(
      onItemTap: (int index) {
        unawaited(
          showCustomDialog(
            context: context,
            content: P2pSwapModal(swapId: _swaps[index].id),
          ),
        );
      },
      items: _swaps,
      hasReachedMax: true,
      generateRowCells: _buildRowCells,
      onScrollReachedBottom: () {},
      columns: const <InfiniteScrollTableColumnType>[
        .status,
        .from,
        .to,
        .started,
        .blank,
      ],
    );
  }

  List<Widget> _buildRowCells(P2pSwap swap) {
    final BigInt? toAmount = swap.toAmount;
    final Token? toToken = swap.toToken;

    return <Widget>[
      InfiniteScrollTableCell(child: _Status(swap: swap)),
      InfiniteScrollTableCell(
        child: _Amount(
          amount: swap.fromAmount,
          token: swap.fromToken,
        ),
      ),
      if (swap.state == P2pSwapState.completed &&
          toAmount != null &&
          toToken != null)
        InfiniteScrollTableCell(
          child: _Amount(
            amount: toAmount,
            token: toToken,
          ),
        )
      else
        InfiniteScrollTableCell.withText(content: '-'),
      DateCell(timestampMs: swap.startTime * 1000),
      InfiniteScrollTableCell(
        child: SizedBox.square(
          dimension: 36,
          child: Align(
            child: _buildDeleteButton(swap),
          ),
        ),
      ),
    ];
  }

  Widget _buildDeleteButton(P2pSwap swap) {
    return switch (swap.state) {
      P2pSwapState.completed ||
      P2pSwapState.unsuccessful ||
      P2pSwapState.error => DeleteP2pSwapButton(swapId: swap.id),
      _ => const SizedBox.shrink(),
    };
  }
}

class _Status extends StatelessWidget {
  const _Status({required this._swap});

  final P2pSwap _swap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        _buildStatusIcon(),
        kHorizontalGap8,
        Text(_swap.state.statusText(context)),
      ],
    );
  }

  Widget _buildStatusIcon() {
    return switch (_swap.state) {
      P2pSwapState.pending || P2pSwapState.active => const SyriusLoadingWidget(
        size: 18,
        strokeWidth: 2,
        padding: 2,
      ),
      P2pSwapState.completed => const Icon(
        Icons.check_circle_outline,
        color: AppColors.znnColor,
      ),
      P2pSwapState.reclaimable => Icon(
        Icons.call_received_rounded,
        color: ColorUtils.getTokenColor(_swap.fromToken.tokenStandard),
      ),
      P2pSwapState.unsuccessful || P2pSwapState.error => const Icon(
        Icons.cancel_outlined,
        color: AppColors.errorColor,
      ),
    };
  }
}

class _Amount extends StatelessWidget {
  const _Amount({required this._amount, required this._token});

  final BigInt _amount;
  final Token _token;

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: TextSpan(
        text: _amount.addDecimals(_token.decimals),
        children: <InlineSpan>[
          const TextSpan(text: ' '),
          TextSpan(
            text: _token.symbol,
            style: TextStyle(
              color: ColorUtils.getTokenColor(_token.tokenStandard),
            ),
          ),
        ],
      ),
    );
  }
}
