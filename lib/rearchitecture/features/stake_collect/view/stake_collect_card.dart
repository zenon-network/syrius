import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/single_child_widget.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// A card that displays and collects pending staking rewards.
class StakeCollectCard extends StatelessWidget {
  /// Creates a widget that displays and collects staking rewards.
  const StakeCollectCard({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: <SingleChildWidget>[
        BlocProvider<UncollectedStakingRewardsBloc>(
          create: (_) => UncollectedStakingRewardsBloc(zenon: zenon!)
            ..add(
              FetchRequestData(
                address: Address.parse(kSelectedAddress!),
              ),
            ),
        ),
        BlocProvider<SendTransactionBloc>(
          create: (_) => SendTransactionBloc(),
        ),
      ],
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
        context.read<UncollectedStakingRewardsBloc>().add(
          FetchRequestData(address: Address.parse(kSelectedAddress!)),
        );
      },
      body:
          BlocBuilder<
            UncollectedStakingRewardsBloc,
            FetchState<UncollectedReward>
          >(
            builder: (_, FetchState<UncollectedReward> state) =>
                switch (state) {
                  FetchFailure<UncollectedReward>() => SyriusErrorWidget(
                    state.exception,
                  ),
                  FetchInitial<UncollectedReward>() =>
                    const SyriusLoadingWidget(),
                  FetchPopulated<UncollectedReward>() => _Populated(
                    uncollectedReward: state.data,
                  ),
                },
          ),
    );
  }

  CardData _buildCardData({required BuildContext context}) => CardData(
    description: context.l10n.stakeCollectDescription,
    title: context.l10n.stakeCollectTitle,
  );
}

class _Populated extends StatelessWidget {
  const _Populated({required this.uncollectedReward});

  final UncollectedReward uncollectedReward;

  @override
  Widget build(BuildContext context) {
    if (uncollectedReward.qsrAmount == BigInt.zero) {
      return SyriusErrorWidget(context.l10n.noRewardsCollect);
    }

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
        const _CollectButton(),
      ],
    );
  }
}

class _CollectButton extends StatefulWidget {
  const _CollectButton();

  @override
  State<_CollectButton> createState() => _CollectButtonState();
}

class _CollectButtonState extends State<_CollectButton> {
  final GlobalKey<LoadingButtonState> _collectButtonKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return BlocListener<SendTransactionBloc, SendTransactionState>(
      listener: (_, SendTransactionState state) =>
          _onTransactionStateChanged(state),
      child: LoadingButton.stepper(
        key: _collectButtonKey,
        text: context.l10n.collect,
        outlineColor: AppColors.qsrColor,
        onPressed: () => _onCollectPressed(
          bloc: context.read<SendTransactionBloc>(),
        ),
      ),
    );
  }

  void _onTransactionStateChanged(SendTransactionState state) {
    if (state.status == SendTransactionStatus.loading) {
      _collectButtonKey.currentState?.animateForward();
    } else if (state.status == SendTransactionStatus.success) {
      _collectButtonKey.currentState?.animateReverse();
      _sendConfirmationNotification(block: state.data!);
      _refreshRewardsAfterDelay();
    } else if (state.status == SendTransactionStatus.failure) {
      _collectButtonKey.currentState?.animateReverse();
      unawaited(
        NotificationUtils.sendNotificationError(
          state.error!,
          context.l10n.errorCollectingStakingRewards,
        ),
      );
    }
  }

  void _refreshRewardsAfterDelay() {
    Future<void>.delayed(
      kDelayAfterAccountBlockCreationCall,
      () {
        if (mounted) {
          final Address address = Address.parse(kSelectedAddress!);
          context.read<UncollectedStakingRewardsBloc>().add(
            FetchRequestData(address: address),
          );
          context.read<StakingRewardsHistoryBloc>().add(
            FetchRequestData(address: address),
          );
        }
      },
    );
  }

  void _onCollectPressed({required SendTransactionBloc bloc}) {
    bloc.add(
      SendTransactionInitiateFromBlock(
        block: zenon!.embedded.stake.collectReward(),
        fromAddress: kSelectedAddress!,
        reasonForGeneratingPlasma: context.l10n.collectStakingRewards,
      ),
    );
  }

  void _sendConfirmationNotification({required AccountBlockTemplate block}) {
    unawaited(
      sl.get<NotificationsBloc>().addNotification(
        WalletNotification(
          title: context.l10n.stakingRewardsBlockCreated,
          timestamp: DateTime.now().millisecondsSinceEpoch,
          details: context.l10n.hashValue(block.hash.toString()),
          type: NotificationType.paymentSent,
        ),
      ),
    );
  }
}
