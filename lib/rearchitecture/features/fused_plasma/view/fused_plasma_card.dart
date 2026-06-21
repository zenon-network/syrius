import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart'
    hide
        InfiniteScrollTable,
        InfiniteScrollTableCell,
        InfiniteScrollTableHeaderColumn;
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// A card that displays Plasma fusions for the selected address.
class FusedPlasmaCard extends StatelessWidget {
  /// Creates a fused Plasma list card.
  const FusedPlasmaCard({super.key});

  @override
  Widget build(BuildContext context) {
    return const _View();
  }
}

class _View extends StatelessWidget {
  const _View();

  @override
  Widget build(BuildContext context) {
    return NewCardScaffold(
      data: _buildCardData(context: context),
      onRefreshPressed: () => _refreshFusedPlasma(context),
      body: BlocBuilder<FusedPlasmaBloc, InfiniteListState<FusionEntry>>(
        builder: (_, InfiniteListState<FusionEntry> state) {
          return switch (state.status) {
            InfiniteListStatus.initial => const SyriusLoadingWidget(),
            InfiniteListStatus.failure => SyriusErrorWidget(state.error!),
            InfiniteListStatus.success => _Populated(
              hasReachedMax: state.hasReachedMax,
              fusionEntries: state.data!,
            ),
          };
        },
      ),
    );
  }

  CardData _buildCardData({required BuildContext context}) => CardData(
    description: context.l10n.fusedPlasmaDescription(kQsrCoin.symbol),
    title: context.l10n.fusedPlasmaTitle,
  );
}

class _Populated extends StatelessWidget {
  const _Populated({
    required this.hasReachedMax,
    required this.fusionEntries,
  });

  final bool hasReachedMax;
  final List<FusionEntry> fusionEntries;

  @override
  Widget build(BuildContext context) {
    return InfiniteScrollTable<FusionEntry>(
      itemKeyGenerator: (FusionEntry fusionEntry) =>
          ValueKey<String>(fusionEntry.id.toString()),
      items: fusionEntries,
      hasReachedMax: hasReachedMax,
      columns: _buildHeaderColumns(),
      generateRowCells: (FusionEntry fusionEntry) => _buildRowCells(
        context: context,
        fusionEntry: fusionEntry,
      ),
      onScrollReachedBottom: () {
        context.read<FusedPlasmaBloc>().add(
          InfiniteListMoreRequested(address: Address.parse(kSelectedAddress!)),
        );
      },
    );
  }

  List<InfiniteScrollTableCell> _buildRowCells({
    required BuildContext context,
    required FusionEntry fusionEntry,
  }) {
    return <InfiniteScrollTableCell>[
      InfiniteScrollTableCell(
        child: FormattedAmountWithTooltip(
          amount: fusionEntry.qsrAmount.addDecimals(kQsrCoin.decimals),
          tokenSymbol: kQsrCoin.symbol,
          builder: (String formattedAmount, String tokenSymbol) => Text(
            '$formattedAmount $tokenSymbol',
            style: Theme.of(context).textTheme.titleMedium!.copyWith(
              color: AppColors.subtitleColor,
            ),
          ),
        ),
      ),
      InfiniteScrollTableCell.textFromAddress(
        address: fusionEntry.beneficiary,
        flex: 3,
      ),
      InfiniteScrollTableCell(
        child: _buildExpirationCell(
          context: context,
          fusionEntry: fusionEntry,
        ),
      ),
    ];
  }

  Widget _buildExpirationCell({
    required BuildContext context,
    required FusionEntry fusionEntry,
  }) {
    if (fusionEntry.isRevocable!) {
      return CancelPlasmaButton(
        plasmaHash: fusionEntry.id,
        onCancelled: () => _refreshFusedPlasma(context),
      );
    }

    return Row(
      mainAxisAlignment: .center,
      children: <Widget>[
        _buildCancelCountdownTimer(
          context: context,
          fusionEntry: fusionEntry,
        ),
      ],
    );
  }

  Widget _buildCancelCountdownTimer({
    required BuildContext context,
    required FusionEntry fusionEntry,
  }) {
    final int lastMomentumHeight =
        context.read<FusedPlasmaBloc>().lastMomentumHeight ?? 0;
    final int heightUntilCancellation =
        fusionEntry.expirationHeight - lastMomentumHeight;

    final Duration durationUntilCancellation =
        kIntervalBetweenMomentums * heightUntilCancellation;

    return Tooltip(
      message: context.l10n.untilRevocationWindowOpens,
      child: CancelTimer(
        durationUntilCancellation,
        AppColors.errorColor,
        onTimeFinishedCallback: () => _refreshFusedPlasma(context),
      ),
    );
  }

  List<InfiniteScrollTableColumnType> _buildHeaderColumns() =>
      <InfiniteScrollTableColumnType>[
        .amount,
        .beneficiaryAddress,
        .expiration,
      ];
}

void _refreshFusedPlasma(BuildContext context) {
  context.read<FusedPlasmaBloc>().add(
    InfiniteListRefreshRequested(address: Address.parse(kSelectedAddress!)),
  );
}
