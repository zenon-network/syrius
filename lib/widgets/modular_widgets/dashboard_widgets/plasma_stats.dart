import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:zenon_syrius_wallet_flutter/utils/notifiers/plasma_beneficiary_address_notifier.dart';
import 'package:zenon_syrius_wallet_flutter/utils/zts_utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

const String kPlasmaStatsWidgetTitle = 'Plasma Stats';
final String _kWidgetDescription = 'This card displays information about '
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

class PlasmaStats extends StatefulWidget {

  const PlasmaStats({
    this.version = PlasmaStatsWidgetVersion.dashboardTab,
    super.key,
  });
  final PlasmaStatsWidgetVersion version;

  @override
  State<PlasmaStats> createState() => _PlasmaStatsState();
}

class _PlasmaStatsState extends State<PlasmaStats> {
  final List<String> _addresses = [];

  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    sl.get<PlasmaStatsBloc>().getPlasmas();
    _addresses.addAll(kDefaultAddressList.cast());
  }

  @override
  Widget build(BuildContext context) {
    return CardScaffold<List<PlasmaInfoWrapper>>(
      title: kPlasmaStatsWidgetTitle,
      description: _kWidgetDescription,
      childStream: sl.get<PlasmaStatsBloc>().stream,
      onCompletedStatusCallback: _getTable,
      onRefreshPressed: widget.version == PlasmaStatsWidgetVersion.plasmaTab
          ? () => sl.get<PlasmaStatsBloc>().getPlasmas()
          : null,
    );
  }

  Widget _getTable(List<PlasmaInfoWrapper> plasmaInfoStats) {
    return CustomTable<PlasmaInfoWrapper>(
      onRowTappedCallback: widget.version == PlasmaStatsWidgetVersion.plasmaTab
          ? _getChangeBeneficiaryAddressCallback
          : null,
      items: plasmaInfoStats,
      headerColumns: widget.version == PlasmaStatsWidgetVersion.plasmaTab
          ? [
              CustomHeaderColumn(
                columnName: 'Address',
                onSortArrowsPressed: _onSortArrowsPressed,
                flex: 2,
              ),
              CustomHeaderColumn(
                columnName: 'Current plasma',
                onSortArrowsPressed: _onSortArrowsPressed,
              ),
            ]
          : null,
      generateRowCells: (plasmaStatsWrapper, isSelected) {
        return [
          if (widget.version == PlasmaStatsWidgetVersion.plasmaTab) isSelected
                  ? CustomTableCell.tooltipWithMarquee(
                      Address.parse(plasmaStatsWrapper.address),
                    )
                  : CustomTableCell.tooltipWithText(
                      context,
                      Address.parse(plasmaStatsWrapper.address),
                    ) else isSelected
                  ? CustomTableCell.tooltipWithMarquee(
                      Address.parse(plasmaStatsWrapper.address),
                      flex: 2,
                    )
                  : CustomTableCell.tooltipWithText(
                      context,
                      Address.parse(plasmaStatsWrapper.address),
                      flex: 2,
                    ),
          CustomTableCell(
            PlasmaIcon(
              plasmaStatsWrapper.plasmaInfo,
            ),
          ),
        ];
      },
    );
  }

  void _getChangeBeneficiaryAddressCallback(int rowIndex) {
    Provider.of<PlasmaBeneficiaryAddressNotifier>(context, listen: false)
        .changePlasmaBeneficiaryAddress(
      _addresses[rowIndex],
    );
  }

  void _onSortArrowsPressed(String columnName) {
    switch (columnName) {
      case 'Address':
        _sortAscending
            ? _addresses.sort((a, b) => a.compareTo(b))
            : _addresses.sort((a, b) => b.compareTo(a));

      default:
        _sortAscending
            ? _addresses.sort((a, b) => a.compareTo(b))
            : _addresses.sort((a, b) => b.compareTo(a));
        break;
    }

    setState(() {
      _sortAscending = !_sortAscending;
    });
  }
}
