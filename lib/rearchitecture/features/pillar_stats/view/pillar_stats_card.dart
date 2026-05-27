import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/screens/screens.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class PillarStatsCard extends StatefulWidget {
  const PillarStatsCard({
    required this.onStepperNotificationSeeMorePressed,
    super.key,
  });

  final VoidCallback onStepperNotificationSeeMorePressed;

  @override
  State<PillarStatsCard> createState() => _PillarStatsCardState();
}

class _PillarStatsCardState extends State<PillarStatsCard> {
  @override
  Widget build(BuildContext context) {
    return NewCardScaffold(
      body: _buildBody(context),
      data: _buildCardData(context: context),
      onRefreshPressed: () async {
        context.read<GetPillarsByOwnerBloc>().add(
          FetchRequestData(
            address: Address.parse(kSelectedAddress!),
          ),
        );
      },
    );
  }

  CardData _buildCardData({required BuildContext context}) {
    return CardData(
      // TODO(maznnwell): to update
      description: context.l10n.createPillarDescription,
      title: context.l10n.pillarStats,
    );
  }

  Widget _buildBody(BuildContext context) {
    return Row(
      children: [
        Lottie.asset('assets/lottie/ic_anim_pillar.json', repeat: false),
        BlocBuilder<GetPillarsByOwnerBloc, FetchState<List<PillarInfo>>>(
          builder: (_, FetchState<List<PillarInfo>> state) {
            return switch (state) {
              FetchFailure<List<PillarInfo>>() => SyriusErrorWidget(
                state.exception,
              ),
              FetchInitial<List<PillarInfo>>() => const SyriusLoadingWidget(),
              FetchPopulated<List<PillarInfo>>() =>
                state.data.isNotEmpty
                    ? _getUpdatePillarWidgetBody(context, state.data.first)
                    : _getCreatePillarWidgetBody(context),
            };
          },
        ),
      ],
    );
  }

  Widget _getCreatePillarWidgetBody(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () {
        unawaited(
          Navigator.push(
            context,
            MaterialPageRoute<void>(
              builder: (BuildContext context) => StepperScreen(
                stepper: const CreatePillarStepperPage(),
                onStepperNotificationSeeMorePressed:
                    widget.onStepperNotificationSeeMorePressed,
              ),
            ),
          ),
        );
      },
      label: Text(context.l10n.spawn),
      icon: const Icon(Icons.add),
    );
  }

  Widget _getUpdatePillarWidgetBody(
    BuildContext context,
    PillarInfo pillarInfo,
  ) {
    return Column(
      mainAxisAlignment: .center,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(
            right: 15,
          ),
          child: ElevatedButton.icon(
            onPressed: () {
              unawaited(
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (BuildContext context) => StepperScreen(
                      stepper: UpdatePillarStepperPage(
                        pillarInfo: pillarInfo,
                      ),
                      onStepperNotificationSeeMorePressed:
                          widget.onStepperNotificationSeeMorePressed,
                    ),
                  ),
                ),
              );
            },
            label: Text(context.l10n.updatePillar),
            icon: const Icon(Icons.edit),
          ),
        ),
        kVerticalSpacing,
        _buildRevokeTimer(pillarInfo),
      ],
    );
  }

  Widget _buildRevokeTimer(
    PillarInfo pillarInfo,
  ) {
    final bool isRevocable = pillarInfo.isRevocable;

    return Column(
      children: <Widget>[
        Visibility(
          visible: isRevocable,
          child: _buildRevokePillarBlocConsumer(
            pillarInfo,
          ),
        ),
        Row(
          children: <Widget>[
            CancelTimer(
              Duration(
                seconds: pillarInfo.revokeCooldown,
              ),
              isRevocable ? AppColors.znnColor : AppColors.errorColor,
              onTimeFinishedCallback: () {
                context.read<PillarsBloc>().add(
                  const InfiniteListRefreshRequested(address: null),
                );
              },
            ),
            StandardTooltipIcon(
              isRevocable
                  ? context.l10n.revocationWindowOpen
                  : context.l10n.untilRevocationWindowOpens,
              Icons.help,
              iconColor: isRevocable
                  ? AppColors.znnColor
                  : AppColors.errorColor,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRevokePillarBlocConsumer(
    PillarInfo pillarInfo,
  ) {
    return BlocConsumer<RevokePillarBloc, RevokePillarState>(
      listener: (_, RevokePillarState state) {
        if (state is RevokePillarDone) {
          context.read<PillarsBloc>().add(
            const InfiniteListRefreshRequested(address: null),
          );
        } else if (state is RevokePillarFailure) {
          unawaited(
            NotificationUtils.sendNotificationError(
              state.exception,
              context.l10n.errorDisassemblingPillar,
            ),
          );
        }
      },
      builder: (_, RevokePillarState state) => switch (state) {
        RevokePillarInitial() => _buildDisassembleButton(pillarInfo),
        RevokePillarFailure() => _buildDisassembleButton(pillarInfo),
        RevokePillarDone() => _buildDisassembleButton(pillarInfo),
        RevokePillarLoading() => const SyriusLoadingWidget(size: 25),
      },
    );
  }

  Widget _buildDisassembleButton(
    PillarInfo pillarItem,
  ) {
    return Column(
      children: <Widget>[
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            iconColor: AppColors.errorColor,
            side: const BorderSide(
              color: AppColors.errorColor,
            ),
          ),
          // TODO(maznnwell): add confirmation dialog
          onPressed: () {
            context.read<RevokePillarBloc>().add(
              RevokePillarRequested(pillarName: pillarItem.name),
            );
          },
          icon: const Icon(Icons.close),
          iconAlignment: .end,
          label: Text(
            context.l10n.disassemble,
            style: TextStyle(
              color: context.newThemeData.textTheme.titleSmall!.color,
            ),
          ),
        ),
        kVerticalSpacing,
      ],
    );
  }
}
