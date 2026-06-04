import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/account_block_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/utils/extensions.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:zenon_syrius_wallet_flutter/utils/notification_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/zts_utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// A card that displays and collects pending staking rewards.
class StakeCollect extends StatefulWidget {
  /// Creates a widget that displays and collects staking rewards.
  const StakeCollect({super.key});

  @override
  State<StakeCollect> createState() => _StakeCollectState();
}

class _StakeCollectState extends State<StakeCollect> {
  final GlobalKey<LoadingButtonState> _collectButtonKey = GlobalKey();

  final StakingUncollectedRewardsBloc _stakingUncollectedRewardsBloc =
      StakingUncollectedRewardsBloc();

  @override
  Widget build(BuildContext context) {
    return CardScaffold<void>(
      title: context.l10n.stakeCollectTitle,
      description: context.l10n.stakeCollectDescription,
      childBuilder: _buildChild,
    );
  }

  Widget _buildChild() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: _getFutureBuilder(),
    );
  }

  Widget _getFutureBuilder() {
    return StreamBuilder<UncollectedReward?>(
      stream: _stakingUncollectedRewardsBloc.stream,
      builder: (_, AsyncSnapshot<UncollectedReward?> snapshot) {
        if (snapshot.hasError) {
          return SyriusErrorWidget(snapshot.error!);
        } else if (snapshot.hasData) {
          if (snapshot.data!.qsrAmount > BigInt.zero) {
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
          end: uncollectedReward.qsrAmount.addDecimals(coinDecimals).toNum(),
          after: ' ${kQsrCoin.symbol}',
          style: Theme.of(context).textTheme.headlineLarge!.copyWith(
            color: AppColors.qsrColor,
            fontSize: 30,
          ),
        ),
        kVerticalSpacing,
        Visibility(
          visible: uncollectedReward.qsrAmount > BigInt.zero,
          child: LoadingButton.stepper(
            key: _collectButtonKey,
            text: context.l10n.collect,
            outlineColor: AppColors.qsrColor,
            onPressed: uncollectedReward.qsrAmount > BigInt.zero
                ? _onCollectPressed
                : null,
          ),
        ),
      ],
    );
  }

  Future<void> _onCollectPressed() async {
    final StakingRewardsHistoryBloc stakingRewardsHistoryBloc = context
        .read<StakingRewardsHistoryBloc>();
    final String collectStakingRewards = context.l10n.collectStakingRewards;
    final String errorCollectingStakingRewards =
        context.l10n.errorCollectingStakingRewards;

    try {
      _collectButtonKey.currentState?.animateForward();
      await AccountBlockUtils().createAccountBlock(
        zenon!.embedded.stake.collectReward(),
        collectStakingRewards,
        waitForRequiredPlasma: true,
      );
      await Future<void>.delayed(kDelayAfterAccountBlockCreationCall);

      if (mounted) {
        unawaited(_stakingUncollectedRewardsBloc.updateStream());
        stakingRewardsHistoryBloc.add(
          FetchRequestData(address: Address.parse(kSelectedAddress!)),
        );
      }
    } on Object catch (e) {
      await NotificationUtils.sendNotificationError(
        e,
        errorCollectingStakingRewards,
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
