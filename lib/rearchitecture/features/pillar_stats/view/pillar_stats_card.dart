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

/// A widget that shows some information depending on the pillar status
///
/// If the current selected address is not registered as a owner for a pillar,
/// then it shows a button to create one
///
/// If it is registered, then the widgets show:
/// 1. button to update the pillar
/// 2. a timer which clocks the time until revocation window opens; afterwards,
/// it changes to show the time until revocation window closes
/// 3. revocation button when the time condition is meet
class PillarStatsCard extends StatelessWidget {
  /// {@macro default_constructor}
  const PillarStatsCard({
    required VoidCallback onStepperNotificationSeeMorePressed,
    super.key,
  }) : _onStepperNotificationSeeMorePressed =
           onStepperNotificationSeeMorePressed;

  final VoidCallback _onStepperNotificationSeeMorePressed;

  @override
  Widget build(BuildContext context) {
    return _PillarStatsView(
      onStepperNotificationSeeMorePressed: _onStepperNotificationSeeMorePressed,
    );
  }
}

class _PillarStatsView extends StatelessWidget {
  const _PillarStatsView({
    required this.onStepperNotificationSeeMorePressed,
  });

  final VoidCallback onStepperNotificationSeeMorePressed;

  @override
  Widget build(BuildContext context) {
    return NewCardScaffold(
      body: _buildBody(context),
      data: _buildCardData(context: context),
      onRefreshPressed: () {
        context.read<PillarsByOwnerBloc>().add(
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
      children: <Widget>[
        Lottie.asset('assets/lottie/ic_anim_pillar.json', repeat: false),
        BlocBuilder<PillarsByOwnerBloc, FetchState<List<PillarInfo>>>(
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
                    onStepperNotificationSeeMorePressed,
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
                          onStepperNotificationSeeMorePressed,
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
        _buildRevokeTimer(context: context, pillarInfo: pillarInfo),
      ],
    );
  }

  Widget _buildRevokeTimer({
    required BuildContext context,
    required PillarInfo pillarInfo,
  }) {
    final bool isRevocable = pillarInfo.isRevocable;

    return Column(
      children: <Widget>[
        Visibility(
          visible: isRevocable,
          child: Column(
            children: <Widget>[
              RevokePillarButton(
                pillarName: pillarInfo.name,
                onRevoked: () {
                  context.read<PillarsBloc>().add(
                    const InfiniteListRefreshRequested(address: null),
                  );
                },
              ),
              kVerticalSpacing,
            ],
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
}
