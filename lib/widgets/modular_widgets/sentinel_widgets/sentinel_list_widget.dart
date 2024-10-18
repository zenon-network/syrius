import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:stacked/stacked.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:zenon_syrius_wallet_flutter/utils/notification_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/widget_utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class SentinelListWidget extends StatefulWidget {
  const SentinelListWidget({super.key});

  @override
  State<SentinelListWidget> createState() => _SentinelListWidgetState();
}

class _SentinelListWidgetState extends State<SentinelListWidget> {
  late SentinelsListBloc _bloc;

  final List<SentinelInfo> _sentinels = [];
  bool _sortAscending = true;

  @override
  Widget build(BuildContext context) {
    return CardScaffold(
      title: 'Sentinel List',
      description:
          'This card displays information about the Sentinels that are '
          'currently active in the network',
      childBuilder: () {
        _bloc = SentinelsListBloc();
        return _getTable(_bloc);
      },
      onRefreshPressed: () => _bloc.refreshResults(),
    );
  }

  Widget _getTable(SentinelsListBloc bloc) {
    return InfiniteScrollTable<SentinelInfo>(
      bloc: _bloc,
      headerColumns: [
        InfiniteScrollTableHeaderColumn(
          columnName: 'Sentinel Address',
          onSortArrowsPressed: _onSortArrowsPressed,
        ),
        const InfiniteScrollTableHeaderColumn(
          columnName: '',
        ),
        const InfiniteScrollTableHeaderColumn(
          columnName: '',
        ),
      ],
      generateRowCells: (sentinelInfo, isSelected) {
        return [
          WidgetUtils.getTextAddressTableCell(
            sentinelInfo.owner,
            context,
            checkIfStakeAddress: true,
            isShortVersion: false,
            showCopyToClipboardIcon: isSelected ? true : false,
          ),
          InfiniteScrollTableCell(
            _getSentinelRevokeTimer(sentinelInfo, bloc),
          ),
          if (isStakeAddressDefault(sentinelInfo)) InfiniteScrollTableCell(
                  _getCancelContainer(isSelected, sentinelInfo, bloc),
                ) else const Spacer(),
        ];
      },
    );
  }

  Widget _getSentinelRevokeTimer(
    SentinelInfo sentinelInfo,
    SentinelsListBloc model,
  ) {
    return Visibility(
      visible: isStakeAddressDefault(sentinelInfo),
      child: Stack(
        children: [
          Row(
            children: [
              if (sentinelInfo.isRevocable) CancelTimer(
                      Duration(
                        seconds: sentinelInfo.revokeCooldown,
                      ),
                      AppColors.znnColor,
                      onTimeFinishedCallback: () {
                        model.refreshResults();
                      },
                    ) else CancelTimer(
                      Duration(
                        seconds: sentinelInfo.revokeCooldown,
                      ),
                      AppColors.errorColor,
                      onTimeFinishedCallback: () {
                        model.refreshResults();
                      },
                    ),
              const SizedBox(
                width: 5,
              ),
              StandardTooltipIcon(
                sentinelInfo.isRevocable
                    ? 'Revocation window is open'
                    : 'Until revocation window opens',
                Icons.help,
                iconColor: sentinelInfo.isRevocable
                    ? AppColors.znnColor
                    : AppColors.errorColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  bool isStakeAddressDefault(SentinelInfo activeFullSentinel) {
    return activeFullSentinel.owner.toString() == kSelectedAddress;
  }

  Widget _getCancelContainer(
    bool isSelected,
    SentinelInfo sentinelInfo,
    SentinelsListBloc model,
  ) {
    return Visibility(
      visible: sentinelInfo.isRevocable,
      child: Stack(
        alignment: Alignment.center,
        children: [
          _getDisassembleButtonViewModel(isSelected, model, sentinelInfo),
        ],
      ),
    );
  }

  MyOutlinedButton _getDisassembleButton(
    bool isSelected,
    DisassembleButtonBloc model,
    SentinelInfo sentinelInfo,
  ) {
    return MyOutlinedButton(
      minimumSize: const Size(55, 25),
      outlineColor: isSelected
          ? AppColors.errorColor
          : Theme.of(context).textTheme.titleSmall!.color,
      onPressed: isSelected
          ? () {
              model.disassembleSentinel(context);
            }
          : null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'DISASSEMBLE',
            style: isSelected
                ? Theme.of(context).textTheme.titleSmall!.copyWith(
                      color: Theme.of(context).textTheme.bodyLarge!.color,
                    )
                : Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(
            width: 20,
          ),
          Icon(
            SimpleLineIcons.close,
            size: 11,
            color: isSelected
                ? AppColors.errorColor
                : Theme.of(context).textTheme.titleSmall!.color,
          ),
        ],
      ),
    );
  }

  void _onSortArrowsPressed(String columnName) {
    switch (columnName) {
      case 'Sentinel Owner':
        _sortAscending
            ? _sentinels.sort((a, b) => a.owner.compareTo(b.owner))
            : _sentinels.sort((a, b) => b.owner.compareTo(a.owner));
      case 'Registration time':
        _sortAscending
            ? _sentinels.sort((a, b) =>
                a.registrationTimestamp.compareTo(b.registrationTimestamp),)
            : _sentinels.sort((a, b) =>
                b.registrationTimestamp.compareTo(a.registrationTimestamp),);
      case 'Reward Address':
      default:
        break;
    }

    setState(() {
      _sortAscending = !_sortAscending;
    });
  }

  Widget _getDisassembleButtonViewModel(
    bool isSelected,
    SentinelsListBloc sentinelsModel,
    SentinelInfo sentinelInfo,
  ) {
    return ViewModelBuilder<DisassembleButtonBloc>.reactive(
      onViewModelReady: (model) {
        model.stream.listen(
          (event) {
            if (event != null) {
              sentinelsModel.refreshResults();
            }
          },
          onError: (error) async {
            await NotificationUtils.sendNotificationError(
              error,
              'Error while disassembling Sentinel',
            );
          },
        );
      },
      builder: (_, model, __) => StreamBuilder<AccountBlockTemplate?>(
        stream: model.stream,
        builder: (_, snapshot) {
          if (snapshot.hasError) {
            return _getDisassembleButton(isSelected, model, sentinelInfo);
          }
          if (snapshot.connectionState == ConnectionState.active) {
            if (snapshot.hasData) {
              return _getDisassembleButton(isSelected, model, sentinelInfo);
            }
            return const SyriusLoadingWidget(size: 25);
          }
          return _getDisassembleButton(isSelected, model, sentinelInfo);
        },
      ),
      viewModelBuilder: DisassembleButtonBloc.new,
    );
  }
}
