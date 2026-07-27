import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/notifiers/plasma_beneficiary_address_cubit.dart';
import 'package:zenon_syrius_wallet_flutter/utils/zts_utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart'
    hide
        InfiniteScrollTable,
        InfiniteScrollTableCell,
        InfiniteScrollTableHeaderColumn;
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// Display variants for [PlasmaStatsCard].
enum PlasmaStatsWidgetVersion {
  /// Compact variant used on the dashboard tab.
  dashboardTab,

  /// Interactive variant used on the Plasma tab.
  plasmaTab,
}

/// This widget shows the plasma level for each user address, in the form of a
/// table.
///
/// Personal note: because fetching the plasma level has to be done
/// individually, for each address, that means that ten addresses equals ten
/// API calls.
///
/// Ways to optimize this widget should be found
class PlasmaStatsCard extends StatefulWidget {
  /// Creates a Plasma stats card.
  const PlasmaStatsCard({
    this.version = PlasmaStatsWidgetVersion.dashboardTab,
    super.key,
  });

  /// Controls where the card is rendered and which interactions are enabled.
  final PlasmaStatsWidgetVersion version;

  @override
  State<PlasmaStatsCard> createState() => _PlasmaStatsCardState();
}

class _PlasmaStatsCardState extends State<PlasmaStatsCard> {
  @override
  Widget build(BuildContext context) {
    return NewCardScaffold(
      data: _buildCard(),
      body: BlocBuilder<PlasmaStatsBloc, InfiniteListState<PlasmaInfoWrapper>>(
        builder: (_, InfiniteListState<PlasmaInfoWrapper> state) {
          final InfiniteListStatus status = state.status;

          return switch (status) {
            InfiniteListStatus.initial => const SyriusLoadingWidget(),
            InfiniteListStatus.failure => SyriusErrorWidget(
              state.error!,
            ),
            InfiniteListStatus.success => _Populated(
              hasReachedMax: state.hasReachedMax,
              plasmaInfoStats: state.data!,
              version: widget.version,
            ),
          };
        },
      ),
      onRefreshPressed: () {
        context.read<PlasmaStatsBloc>().add(
          const InfiniteListRefreshRequested(),
        );
      },
    );
  }

  CardData _buildCard() => CardData(
    description: context.l10n.plasmaStatsDescription(kQsrCoin.symbol),
    title: context.l10n.plasmaStatsTitle,
  );
}

class _Populated extends StatelessWidget {
  const _Populated({
    required this.hasReachedMax,
    required this.version,
    required this.plasmaInfoStats,
  });

  final bool hasReachedMax;
  final PlasmaStatsWidgetVersion version;
  final List<PlasmaInfoWrapper> plasmaInfoStats;

  @override
  Widget build(BuildContext context) {
    return InfiniteScrollTable<PlasmaInfoWrapper>(
      onItemTap: version == PlasmaStatsWidgetVersion.plasmaTab
          ? (int index) => _changeBeneficiaryAddress(index, context)
          : null,
      onScrollReachedBottom: () {
        context.read<PlasmaStatsBloc>().add(
          const InfiniteListMoreRequested(),
        );
      },
      hasReachedMax: hasReachedMax,
      items: plasmaInfoStats,
      columns: const <InfiniteScrollTableColumnType>[
        .address,
        .level,
      ],
      generateRowCells: (PlasmaInfoWrapper plasmaStatsWrapper) {
        return <Widget>[
          InfiniteScrollTableCell.textFromAddress(
            address: Address.parse(plasmaStatsWrapper.address),
          ),
          InfiniteScrollTableCell(
            child: PlasmaIcon(
              plasmaStatsWrapper.plasmaInfo,
            ),
          ),
        ];
      },
    );
  }

  void _changeBeneficiaryAddress(
    int rowIndex,
    BuildContext context,
  ) {
    context.read<PlasmaBeneficiaryAddressCubit>().changeAddress(
      plasmaInfoStats[rowIndex].address,
    );
  }
}
