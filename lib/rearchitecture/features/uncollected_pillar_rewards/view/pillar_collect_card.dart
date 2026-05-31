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

/// A widget that display the amount of uncollected pillar rewards
///
/// If it's higher than zero, then a button to trigger their collection is
/// displayed
class PillarCollectCard extends StatelessWidget {
  /// {@macro default_constructor}
  const PillarCollectCard({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: <SingleChildWidget>[
        BlocProvider<UncollectedPillarRewards>(
          create: (_) => UncollectedPillarRewards(zenon: zenon!)
            ..add(
              FetchRequestData(
                address: Address.parse(
                  kSelectedAddress!,
                ),
              ),
            ),
        ),
        BlocProvider<SendTransactionBloc>(
          create: (_) => SendTransactionBloc(),
        ),
      ],
      child: const _PillarCollectView(),
    );
  }
}

class _PillarCollectView extends StatelessWidget {
  const _PillarCollectView();

  @override
  Widget build(BuildContext context) {
    return NewCardScaffold(
      data: _buildCardData(context: context),
      onRefreshPressed: () {
        context.read<UncollectedPillarRewards>().add(
          FetchRequestData(address: Address.parse(kSelectedAddress!)),
        );
      },
      body:
          BlocBuilder<UncollectedPillarRewards, FetchState<UncollectedReward>>(
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
    description: context.l10n.pillarCollectDescription,
    title: context.l10n.pillarCollectTitle,
  );
}

class _Populated extends StatefulWidget {
  const _Populated({required this.uncollectedReward});

  final UncollectedReward uncollectedReward;

  @override
  State<_Populated> createState() => _PopulatedState();
}

class _PopulatedState extends State<_Populated> {
  final GlobalKey<LoadingButtonState> _collectButtonKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    if (widget.uncollectedReward.znnAmount == BigInt.zero) {
      return SyriusErrorWidget(context.l10n.noRewardsCollect);
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        NumberAnimation(
          end: widget.uncollectedReward.znnAmount
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
        kVerticalGap16,
        BlocListener<SendTransactionBloc, SendTransactionState>(
          listener: (_, SendTransactionState state) {
            if (state.status == SendTransactionStatus.loading) {
              _collectButtonKey.currentState?.animateForward();
            } else if (state.status == SendTransactionStatus.success) {
              _collectButtonKey.currentState?.animateReverse();
              _sendConfirmationNotification(block: state.data!);
              Future<void>.delayed(
                kDelayAfterAccountBlockCreationCall,
                () {
                  if (context.mounted) {
                    context.read<UncollectedPillarRewards>().add(
                      FetchRequestData(
                        address: Address.parse(kSelectedAddress!),
                      ),
                    );
                  }
                },
              );
            } else if (state.status == SendTransactionStatus.failure) {
              _collectButtonKey.currentState?.animateReverse();
              unawaited(
                NotificationUtils.sendNotificationError(
                  state.error!,
                  context.l10n.errorCollectingPillarRewards,
                ),
              );
            }
          },
          child: LoadingButton.stepper(
            key: _collectButtonKey,
            text: context.l10n.collect,
            onPressed: widget.uncollectedReward.znnAmount > BigInt.zero
                ? () => _onCollectPressed(
                    bloc: context.read<SendTransactionBloc>(),
                  )
                : null,
          ),
        ),
      ],
    );
  }

  void _onCollectPressed({required SendTransactionBloc bloc}) {
    bloc.add(
      SendTransactionInitiateFromBlock(
        block: zenon!.embedded.pillar.collectReward(),
        fromAddress: kSelectedAddress!,
        reasonForGeneratingPlasma: context.l10n.collectPillarRewards,
      ),
    );
  }

  void _sendConfirmationNotification({
    required AccountBlockTemplate block,
  }) {
    final String title = context.l10n.pillarRewardsBlockCreated;

    unawaited(
      sl.get<NotificationsBloc>().addNotification(
        WalletNotification(
          title: title,
          timestamp: DateTime.now().millisecondsSinceEpoch,
          details: context.l10n.hashValue(block.hash.toString()),
          type: NotificationType.paymentSent,
        ),
      ),
    );
  }
}
