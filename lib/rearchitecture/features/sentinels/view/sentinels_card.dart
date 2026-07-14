import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart'
    hide
        InfiniteScrollTable,
        InfiniteScrollTableCell,
        InfiniteScrollTableHeaderColumn;
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// A widget that displays active sentinels found on the network.
class SentinelsCard extends StatelessWidget {
  /// {@macro default_constructor}
  const SentinelsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SentinelsBloc>(
      create: (_) =>
          SentinelsBloc(zenon: zenon!)..add(const InfiniteListRequested()),
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
        context.read<SentinelsBloc>().add(
          const InfiniteListRefreshRequested(),
        );
      },
      body: BlocBuilder<SentinelsBloc, InfiniteListState<SentinelInfo>>(
        builder: (_, InfiniteListState<SentinelInfo> state) {
          final InfiniteListStatus status = state.status;

          return switch (status) {
            InfiniteListStatus.initial => const SyriusLoadingWidget(),
            InfiniteListStatus.failure => SyriusErrorWidget(state.error!),
            InfiniteListStatus.success => _Populated(
              hasReachedMax: state.hasReachedMax,
              sentinels: state.data!,
            ),
          };
        },
      ),
    );
  }

  CardData _buildCardData({required BuildContext context}) {
    return CardData(
      description: context.l10n.sentinelsListDescription,
      title: context.l10n.sentinels,
    );
  }
}

class _Populated extends StatelessWidget {
  const _Populated({
    required this.hasReachedMax,
    required this.sentinels,
  });

  final bool hasReachedMax;
  final List<SentinelInfo> sentinels;

  @override
  Widget build(BuildContext context) {
    return InfiniteScrollTable<SentinelInfo>(
      itemKeyGenerator: (SentinelInfo sentinelInfo) =>
          ValueKey<String>(sentinelInfo.owner.toString()),
      items: sentinels,
      hasReachedMax: hasReachedMax,
      columns: _buildHeaderColumns(),
      generateRowCells: (SentinelInfo sentinelInfo) => _buildRowCells(
        context: context,
        sentinelInfo: sentinelInfo,
      ),
      onScrollReachedBottom: () {
        context.read<SentinelsBloc>().add(
          const InfiniteListMoreRequested(),
        );
      },
    );
  }

  List<InfiniteScrollTableCell> _buildRowCells({
    required BuildContext context,
    required SentinelInfo sentinelInfo,
  }) {
    final bool isOwnerAddressSelected = _isOwnerAddressSelected(sentinelInfo);

    return <InfiniteScrollTableCell>[
      InfiniteScrollTableCell.textFromAddress(
        address: sentinelInfo.owner,
        flex: 3,
        isStakeAddress: isOwnerAddressSelected,
      ),
      InfiniteScrollTableCell(
        child: _buildSentinelRevokeTimer(
          context: context,
          sentinelInfo: sentinelInfo,
        ),
      ),
      InfiniteScrollTableCell(
        child: isOwnerAddressSelected && sentinelInfo.isRevocable
            ? RevokeSentinelButton(
                onRevoked: () {
                  context.read<SentinelsBloc>().add(
                    const InfiniteListRefreshRequested(),
                  );
                },
              )
            : const SizedBox.shrink(),
      ),
    ];
  }

  Widget _buildSentinelRevokeTimer({
    required BuildContext context,
    required SentinelInfo sentinelInfo,
  }) {
    if (!_isOwnerAddressSelected(sentinelInfo)) {
      return const SizedBox.shrink();
    }

    final bool isRevocable = sentinelInfo.isRevocable;

    return Row(
      children: <Widget>[
        CancelTimer(
          Duration(seconds: sentinelInfo.revokeCooldown),
          isRevocable ? AppColors.znnColor : AppColors.errorColor,
          onTimeFinishedCallback: () {
            context.read<SentinelsBloc>().add(
              const InfiniteListRefreshRequested(),
            );
          },
        ),
        const SizedBox(width: 5),
        StandardTooltipIcon(
          isRevocable
              ? context.l10n.revocationWindowOpen
              : context.l10n.untilRevocationWindowOpens,
          Icons.help,
          iconColor: isRevocable ? AppColors.znnColor : AppColors.errorColor,
        ),
      ],
    );
  }

  bool _isOwnerAddressSelected(SentinelInfo sentinelInfo) {
    return sentinelInfo.owner.toString() == kSelectedAddress;
  }

  List<InfiniteScrollTableColumnType> _buildHeaderColumns() =>
      <InfiniteScrollTableColumnType>[
        .sentinelAddress,
        .blank,
        .blank,
      ];
}
