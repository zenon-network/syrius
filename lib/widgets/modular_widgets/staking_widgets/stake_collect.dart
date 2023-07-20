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

class StakeCollect extends StatefulWidget {
  final StakingRewardsHistoryBloc stakingRewardsHistoryBloc;

  const StakeCollect({
    required this.stakingRewardsHistoryBloc,
    Key? key,
  }) : super(key: key);

  @override
  State<StakeCollect> createState() => _StakeCollectState();
}

class _StakeCollectState extends State<StakeCollect> {
  final GlobalKey<LoadingButtonState> _collectButtonKey = GlobalKey();

  final StakingUncollectedRewardsBloc _stakingUncollectedRewardsBloc =
      StakingUncollectedRewardsBloc();

  @override
  Widget build(BuildContext context) {
    return CardScaffold(
      title: 'Stake Collect',
      description: 'This card displays your current staking rewards that are '
          'ready to be collected. If there are any rewards available, you '
          'will be able to collect them',
      childBuilder: () => Padding(
        padding: const EdgeInsets.all(16.0),
        child: _getFutureBuilder(),
      ),
    );
  }

  Widget _getFutureBuilder() {
    return StreamBuilder<UncollectedReward?>(
      stream: _stakingUncollectedRewardsBloc.stream,
      builder: (_, snapshot) {
        if (snapshot.hasError) {
          return SyriusErrorWidget(snapshot.error!);
        } else if (snapshot.hasData) {
          if (snapshot.data!.qsrAmount > BigInt.zero) {
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
          visible: uncollectedReward.qsrAmount > BigInt.zero,
          child: LoadingButton.stepper(
            key: _collectButtonKey,
            text: 'Collect',
            outlineColor: AppColors.qsrColor,
            onPressed: uncollectedReward.qsrAmount > BigInt.zero
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
        zenon!.embedded.stake.collectReward(),
        'collect staking rewards',
        waitForRequiredPlasma: true,
      ).then(
        (response) async {
          await Future.delayed(kDelayAfterAccountBlockCreationCall);
          if (mounted) {
            _stakingUncollectedRewardsBloc.updateStream();
          }
          widget.stakingRewardsHistoryBloc.updateStream();
        },
      );
    } catch (e) {
      NotificationUtils.sendNotificationError(
        e,
        'Error while collecting staking rewards',
      );
    } finally {
      _collectButtonKey.currentState?.animateReverse();
    }
  }

  @override
  void dispose() {
    _stakingUncollectedRewardsBloc.dispose();
    super.dispose();
  }
}
