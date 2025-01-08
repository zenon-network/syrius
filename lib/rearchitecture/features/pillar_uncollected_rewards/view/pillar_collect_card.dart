import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class PillarCollectCard extends StatelessWidget {
  const PillarCollectCard({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return NewCardScaffold(
      data: _buildCardData(context: context),
      onRefreshPressed: () async {
        await context.read<PillarUncollectedRewardsCubit>().updateStream(
              address: Address.parse(kSelectedAddress!),
            );
      },
      body: BlocBuilder<PillarUncollectedRewardsCubit,
          PillarUncollectedRewardsState>(
        builder: (_, PillarUncollectedRewardsState state) {
          final CubitWithRefreshOptionStatus status = state.status;

          return switch (status) {
            CubitWithRefreshOptionStatus.failure => SyriusErrorWidget(
                state.error!,
              ),
            CubitWithRefreshOptionStatus.loading => const SyriusLoadingWidget(),
            CubitWithRefreshOptionStatus.success => _PillarCollectPopulated(
                uncollectedReward: state.data!,
              ),
          };
        },
      ),
    );
  }

  CardData _buildCardData({required BuildContext context}) => CardData(
        description: context.l10n.pillarCollectDescription,
        title: context.l10n.pillarCollectTitle,
      );
}

class _PillarCollectPopulated extends StatefulWidget {
  const _PillarCollectPopulated({required this.uncollectedReward});

  final UncollectedReward uncollectedReward;

  @override
  State<_PillarCollectPopulated> createState() =>
      _PillarCollectPopulatedState();
}

class _PillarCollectPopulatedState extends State<_PillarCollectPopulated> {
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
                    context
                        .read<PillarUncollectedRewardsCubit>()
                        .updateStream(
                          address: Address.parse(kSelectedAddress!),
                        );
                  }
                },
              );
            } else if (state.status == SendTransactionStatus.failure) {
              _collectButtonKey.currentState?.animateReverse();
              NotificationUtils.sendNotificationError(
                state.error!,
                context.l10n.errorCollectingPillarRewards,
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
