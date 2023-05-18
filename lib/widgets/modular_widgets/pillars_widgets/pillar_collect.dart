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

class PillarCollect extends StatefulWidget {
  final PillarRewardsHistoryBloc pillarRewardsHistoryBloc;

  const PillarCollect({
    required this.pillarRewardsHistoryBloc,
    Key? key,
  }) : super(key: key);

  @override
  State<PillarCollect> createState() => _PillarCollectState();
}

class _PillarCollectState extends State<PillarCollect> {
  final GlobalKey<LoadingButtonState> _collectButtonKey = GlobalKey();

  final PillarUncollectedRewardsBloc _pillarCollectRewardsBloc =
      PillarUncollectedRewardsBloc();

  @override
  Widget build(BuildContext context) {
    return CardScaffold(
      title: 'Pillar Collect',
      description:
          'This card displays your current Pillar rewards (either from your '
          'Pillar Node or from your delegation) that are ready to be collected. '
          'If there are any rewards available, you will be able to collect them. '
          'In order to receive rewards, the Pillar Node needs to be not only '
          'registered in the network, but also deployed (use znn-controller for '
          'this operation) and it must produce momentums',
      childBuilder: () => Padding(
        padding: const EdgeInsets.all(16.0),
        child: _getFutureBuilder(),
      ),
    );
  }

  Widget _getFutureBuilder() {
    return StreamBuilder<UncollectedReward?>(
      stream: _pillarCollectRewardsBloc.stream,
      builder: (_, snapshot) {
        if (snapshot.hasError) {
          return SyriusErrorWidget(snapshot.error!);
        } else if (snapshot.hasData) {
          if (snapshot.data!.znnAmount > BigInt.zero) {
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
          end: uncollectedReward.znnAmount
              .addDecimals(
                coinDecimals,
              )
              .toNum(),
          isInt: false,
          after: ' ${kZnnCoin.symbol}',
          style: Theme.of(context).textTheme.headlineLarge!.copyWith(
                color: AppColors.znnColor,
                fontSize: 30.0,
              ),
        ),
        kVerticalSpacing,
        Visibility(
          visible: uncollectedReward.znnAmount > BigInt.zero,
          child: LoadingButton.stepper(
            key: _collectButtonKey,
            text: 'Collect',
            onPressed: uncollectedReward.znnAmount > BigInt.zero
                ? _onCollectPressed
                : null,
          ),
        ),
      ],
    );
  }

  _onCollectPressed() async {
    try {
      _collectButtonKey.currentState?.animateForward();
      await AccountBlockUtils.createAccountBlock(
        zenon!.embedded.pillar.collectReward(),
        'collect Pillar rewards',
        waitForRequiredPlasma: true,
      ).then(
        (response) async {
          await Future.delayed(kDelayAfterAccountBlockCreationCall);
          if (mounted) {
            _pillarCollectRewardsBloc.updateStream();
          }
          widget.pillarRewardsHistoryBloc.updateStream();
        },
      );
    } catch (e) {
      NotificationUtils.sendNotificationError(
          e, 'Error while collecting rewards');
    } finally {
      _collectButtonKey.currentState?.animateReverse();
    }
  }

  @override
  void dispose() {
    _pillarCollectRewardsBloc.dispose();
    super.dispose();
  }
}
