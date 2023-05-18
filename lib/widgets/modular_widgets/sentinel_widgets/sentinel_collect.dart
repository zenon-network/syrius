import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/utils/account_block_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/utils/extensions.dart';
import 'package:zenon_syrius_wallet_flutter/utils/notification_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/zts_utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class SentinelCollect extends StatefulWidget {
  final SentinelRewardsHistoryBloc sentinelRewardsHistoryBloc;

  const SentinelCollect({
    required this.sentinelRewardsHistoryBloc,
    Key? key,
  }) : super(key: key);

  @override
  State<SentinelCollect> createState() => _SentinelCollectState();
}

class _SentinelCollectState extends State<SentinelCollect> {
  final GlobalKey<LoadingButtonState> _collectButtonKey = GlobalKey();

  final SentinelUncollectedRewardsBloc _sentinelCollectRewardsBloc =
      SentinelUncollectedRewardsBloc();

  @override
  Widget build(BuildContext context) {
    return CardScaffold(
      title: 'Sentinel Collect',
      description: 'This card displays your current Sentinel rewards that are '
          'ready to be collected. If there are any rewards available, you will '
          'be able to collect them. In order to receive rewards, the Sentinel '
          'Node needs to be not only registered in the network, but also '
          'deployed (use znn-controller for this operation) and it must have >90% '
          'daily uptime',
      childBuilder: () => Padding(
        padding: const EdgeInsets.all(16.0),
        child: _getFutureBuilder(),
      ),
    );
  }

  Widget _getFutureBuilder() {
    return StreamBuilder<UncollectedReward?>(
      stream: _sentinelCollectRewardsBloc.stream,
      builder: (_, snapshot) {
        if (snapshot.hasError) {
          return SyriusErrorWidget(snapshot.error!);
        } else if (snapshot.hasData) {
          if (snapshot.data!.znnAmount > BigInt.zero ||
              snapshot.data!.qsrAmount > BigInt.zero) {
            return _getWidgetBody(snapshot.data!);
          }
          return const SyriusErrorWidget('No rewards to collect');
        }
        return const SyriusLoadingWidget();
      },
    );
  }

  Widget _getWidgetBody(UncollectedReward uncollectedReward) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        NumberAnimation(
          end: uncollectedReward.znnAmount.addDecimals(coinDecimals).toNum(),
          isInt: false,
          after: ' ${kZnnCoin.symbol}',
          style: Theme.of(context).textTheme.headlineLarge!.copyWith(
                color: AppColors.znnColor,
                fontSize: 30.0,
              ),
        ),
        kVerticalSpacing,
        NumberAnimation(
          end: uncollectedReward.qsrAmount.addDecimals(coinDecimals).toNum(),
          isInt: false,
          after: ' ${kQsrCoin.symbol}',
          style: Theme.of(context).textTheme.headlineLarge!.copyWith(
                color: AppColors.qsrColor,
                fontSize: 30.0,
              ),
        ),
        kVerticalSpacing,
        Visibility(
          visible: uncollectedReward.qsrAmount > BigInt.zero ||
              uncollectedReward.znnAmount > BigInt.zero,
          child: LoadingButton.stepper(
            key: _collectButtonKey,
            text: 'Collect',
            onPressed: uncollectedReward.qsrAmount > BigInt.zero ||
                    uncollectedReward.znnAmount > BigInt.zero
                ? _onCollectPressed
                : null,
          ),
        ),
      ],
    );
  }

  void _onCollectPressed() async {
    try {
      _collectButtonKey.currentState?.animateForward();
      await AccountBlockUtils.createAccountBlock(
        zenon!.embedded.sentinel.collectReward(),
        'collect Sentinel rewards',
        waitForRequiredPlasma: true,
      ).then(
        (response) async {
          await Future.delayed(kDelayAfterAccountBlockCreationCall);
          if (mounted) {
            _sentinelCollectRewardsBloc.updateStream();
          }
          widget.sentinelRewardsHistoryBloc.updateStream();
        },
      );
    } catch (e) {
      NotificationUtils.sendNotificationError(
        e,
        'Error while collecting Sentinel rewards',
      );
    } finally {
      _collectButtonKey.currentState?.animateReverse();
    }
  }

  @override
  void dispose() {
    _sentinelCollectRewardsBloc.dispose();
    super.dispose();
  }
}
