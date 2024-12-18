import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/extensions/buildcontext_extension.dart';
import 'package:zenon_syrius_wallet_flutter/utils/account_block_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/utils/extensions.dart';
import 'package:zenon_syrius_wallet_flutter/utils/notification_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/zts_utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class PillarCollect extends StatefulWidget {

  const PillarCollect({
    required this.pillarRewardsHistoryBloc,
    super.key,
  });
  final PillarRewardsHistoryBloc pillarRewardsHistoryBloc;

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
      title: context.l10n.pillarCollectTitle,
      description:context.l10n.pillarCollectDescription,
      childBuilder: () => Padding(
        padding: const EdgeInsets.all(16),
        child: _getFutureBuilder(),
      ),
    );
  }

  Widget _getFutureBuilder() {
    return StreamBuilder<UncollectedReward?>(
      stream: _pillarCollectRewardsBloc.stream,
      builder: (_, AsyncSnapshot<UncollectedReward?> snapshot) {
        if (snapshot.hasError) {
          return SyriusErrorWidget(snapshot.error!);
        } else if (snapshot.hasData) {
          if (snapshot.data!.znnAmount > BigInt.zero) {
            return _getWidgetBody(snapshot.data!);
          }
          return SyriusErrorWidget(context.l10n.noRewardsCollect);
        }
        return const SyriusLoadingWidget();
      },
    );
  }

  Widget _getWidgetBody(UncollectedReward uncollectedReward) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        NumberAnimation(
          end: uncollectedReward.znnAmount
              .addDecimals(
                coinDecimals,
              )
              .toNum(),
          after: ' ${kZnnCoin.symbol}',
          style: Theme.of(context).textTheme.headlineLarge!.copyWith(
                color: AppColors.znnColor,
                fontSize: 30,
              ),
        ),
        kVerticalSpacing,
        Visibility(
          visible: uncollectedReward.znnAmount > BigInt.zero,
          child: LoadingButton.stepper(
            key: _collectButtonKey,
            text: context.l10n.collect,
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
        context.l10n.collectPillarRewards,
        waitForRequiredPlasma: true,
      ).then(
        (AccountBlockTemplate response) async {
          await Future.delayed(kDelayAfterAccountBlockCreationCall);
          if (mounted) {
            _pillarCollectRewardsBloc.updateStream();
          }
          widget.pillarRewardsHistoryBloc.updateStream();
        },
      );
    } catch (e) {
      await NotificationUtils.sendNotificationError(
          e, context.l10n.errorCollectingPillarRewards,);
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
