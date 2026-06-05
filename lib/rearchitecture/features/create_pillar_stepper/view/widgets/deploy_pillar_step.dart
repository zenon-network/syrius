import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/create_pillar_stepper/view/widgets/pillar_reward_sliders.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

/// Deploy step for registering a pillar.
class DeployPillarStep extends StatefulWidget {
  /// Creates a [DeployPillarStep].
  const DeployPillarStep({
    required this.canDeployPillar,
    required this.delegateRewardPercentage,
    required this.momentumRewardPercentage,
    required this.onDeployDone,
    required this.onDeployPressed,
    required this.onDelegateRewardChanged,
    required this.onMomentumRewardChanged,
    required this.pillarMomentumController,
    required this.pillarMomentumError,
    required this.pillarMomentumNode,
    required this.pillarNameController,
    required this.pillarNameError,
    required this.pillarNameNode,
    required this.pillarRewardAddressController,
    required this.pillarRewardAddressError,
    required this.pillarRewardNode,
    super.key,
  });

  /// Returns whether the deploy button can be enabled.
  final bool Function() canDeployPillar;

  /// Percentage of delegation rewards given to delegators.
  final double delegateRewardPercentage;

  /// Percentage of momentum rewards given to delegators.
  final double momentumRewardPercentage;

  /// Called when deployment completes.
  final VoidCallback onDeployDone;

  /// Called when the deploy button is pressed.
  final VoidCallback onDeployPressed;

  /// Called when delegation reward percentage changes.
  final ValueChanged<double> onDelegateRewardChanged;

  /// Called when momentum reward percentage changes.
  final ValueChanged<double> onMomentumRewardChanged;

  /// Pillar momentum address controller.
  final TextEditingController pillarMomentumController;

  /// Current pillar momentum validation error.
  final String? Function() pillarMomentumError;

  /// Pillar momentum focus node.
  final FocusNode pillarMomentumNode;

  /// Pillar name controller.
  final TextEditingController pillarNameController;

  /// Current pillar name validation error.
  final String? Function() pillarNameError;

  /// Pillar name focus node.
  final FocusNode pillarNameNode;

  /// Pillar reward address controller.
  final TextEditingController pillarRewardAddressController;

  /// Current pillar reward address validation error.
  final String? Function() pillarRewardAddressError;

  /// Pillar reward focus node.
  final FocusNode pillarRewardNode;

  @override
  State<DeployPillarStep> createState() => _DeployPillarStepState();
}

class _DeployPillarStepState extends State<DeployPillarStep> {
  final GlobalKey<LoadingButtonState> _registerButtonKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return BlocListener<DeployPillarBloc, DeployPillarState>(
      listener: (_, DeployPillarState state) => _onDeployStateChanged(state),
      child: ListenableBuilder(
        listenable: Listenable.merge(<Listenable>[
          widget.pillarNameController,
          widget.pillarMomentumController,
          widget.pillarRewardAddressController,
        ]),
        builder: (_, _) => _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: TextField(
                controller: widget.pillarNameController,
                decoration: InputDecoration(
                  errorText: widget.pillarNameController.text.isNotEmpty
                      ? widget.pillarNameError()
                      : null,
                  hintText: context.l10n.pillarName,
                ),
                focusNode: widget.pillarNameNode,
              ),
            ),
            const SizedBox(width: 23),
          ],
        ),
        kVerticalSpacing,
        Row(
          children: <Widget>[
            Expanded(
              child: TextField(
                controller: widget.pillarRewardAddressController,
                decoration: InputDecoration(
                  errorText:
                      widget.pillarRewardAddressController.text.isNotEmpty
                      ? widget.pillarRewardAddressError()
                      : null,
                  hintText: context.l10n.pillarRewardAddress,
                  suffixIcon: FieldSuffixButtons(
                    controller: widget.pillarRewardAddressController,
                  ),
                ),
                focusNode: widget.pillarRewardNode,
              ),
            ),
            StandardTooltipIcon(
              context.l10n.addressToCollectRewards,
              Icons.help,
            ),
          ],
        ),
        kVerticalSpacing,
        Row(
          children: <Widget>[
            Expanded(
              child: TextField(
                controller: widget.pillarMomentumController,
                decoration: InputDecoration(
                  errorText: widget.pillarMomentumController.text.isNotEmpty
                      ? widget.pillarMomentumError()
                      : null,
                  hintText: context.l10n.pillarProducerAddress,
                  suffixIcon: FieldSuffixButtons(
                    controller: widget.pillarMomentumController,
                  ),
                ),
                focusNode: widget.pillarMomentumNode,
              ),
            ),
            StandardTooltipIcon(
              context.l10n.addressToProduceMomentums,
              Icons.help,
            ),
          ],
        ),
        kVerticalSpacing,
        PillarRewardSliders(
          delegateRewardPercentage: widget.delegateRewardPercentage,
          momentumRewardPercentage: widget.momentumRewardPercentage,
          onDelegateRewardChanged: widget.onDelegateRewardChanged,
          onMomentumRewardChanged: widget.onMomentumRewardChanged,
        ),
        kVerticalGap25,
        LoadingButton(
          text: context.l10n.register,
          onPressed: widget.canDeployPillar() ? widget.onDeployPressed : null,
          key: _registerButtonKey,
        ),
        kVerticalGap25,
      ],
    );
  }

  void _onDeployStateChanged(DeployPillarState state) {
    if (state is DeployPillarDone) {
      _registerButtonKey.currentState?.animateReverse();
      widget.onDeployDone();
    } else if (state is DeployPillarFailure) {
      _registerButtonKey.currentState?.animateReverse();
      unawaited(
        NotificationUtils.sendNotificationError(
          state.exception,
          context.l10n.errorDeployingPillar,
        ),
      );
    } else if (state is DeployPillarLoading) {
      _registerButtonKey.currentState?.animateForward();
    }
  }
}
