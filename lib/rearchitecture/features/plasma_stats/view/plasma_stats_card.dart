import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:zenon_syrius_wallet_flutter/utils/notifiers/plasma_beneficiary_address_notifier.dart';
import 'package:zenon_syrius_wallet_flutter/utils/zts_utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart'
    hide
    InfiniteScrollTable,
    InfiniteScrollTableCell,
    InfiniteScrollTableHeaderColumn;
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

const String kPlasmaStatsWidgetTitle = 'Plasma Stats';
final String _kWidgetDescription =
    'This card displays information about '
    'current Plasma level for each wallet address. Plasma is used as an anti-spam '
    'mechanism. More Plasma you have per address, more transactions you will be '
    'able to send or receive on that address. Low or insufficient Plasma '
    'will require proof-of-work for generation. Fuse 10 ${kQsrCoin.symbol} or more in order '
    'to obtain Plasma for any given address\n\nInsufficient Plasma: Proof-of-work '
    'for Plasma generation; limited to 1 transaction per momentum\nLow Plasma: '
    'between 10 and 50 ${kQsrCoin.symbol}\nAverage Plasma: between 50 and 119 '
    '${kQsrCoin.symbol}\nHigh Plasma: over 120 ${kQsrCoin.symbol}; recommended to '
    'make complex transactions (deploy Pillars, Sentinels, staking and issuing '
    'ZTS tokens)';

enum PlasmaStatsWidgetVersion { dashboardTab, plasmaTab }

/// This widget shows the plasma level for each user address, in the form of a
/// table.
///
/// Personal note: because fetching the plasma level has to be done
/// individually, for each address, that means that ten addresses equals ten
/// API calls.
///
/// Ways to optimize this widget should be found
class PlasmaStatsCard extends StatefulWidget {
  const PlasmaStatsCard({
    this.version = PlasmaStatsWidgetVersion.dashboardTab,
    super.key,
  });

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

  // TODO(by AI): localize description and title strings
  CardData _buildCard() => CardData(
    description: _kWidgetDescription,
    title: kPlasmaStatsWidgetTitle,
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
          ? (int index) => _getChangeBeneficiaryAddressCallback(index, context)
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
        .plasma,
      ],
      generateRowCells:
          (PlasmaInfoWrapper plasmaStatsWrapper) {
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

  void _getChangeBeneficiaryAddressCallback(
    int rowIndex,
    BuildContext context,
  ) {
    Provider.of<PlasmaBeneficiaryAddressNotifier>(
      context,
      listen: false,
    ).changePlasmaBeneficiaryAddress(
      kDefaultAddressList[rowIndex],
    );
  }
}
