import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// Final step that submits the pillar update transaction.
class SubmitPillarUpdateStep extends StatefulWidget {
  /// Creates a [SubmitPillarUpdateStep].
  const SubmitPillarUpdateStep({
    required this.delegateRewardPercentage,
    required this.momentumRewardPercentage,
    required this.onBackPressed,
    required this.onUpdateDone,
    required this.pillarNameController,
    required this.pillarProducerController,
    required this.pillarRewardController,
    super.key,
  });

  /// Percentage of delegation rewards given to delegators.
  final ValueNotifier<double> delegateRewardPercentage;

  /// Percentage of momentum rewards given to delegators.
  final ValueNotifier<double> momentumRewardPercentage;

  /// Called when the user returns to the previous step.
  final VoidCallback onBackPressed;

  /// Called when the update operation completes successfully.
  final VoidCallback onUpdateDone;

  /// Controller containing the pillar name.
  final TextEditingController pillarNameController;

  /// Controller containing the reward address.
  final TextEditingController pillarRewardController;

  /// Controller containing the producer address.
  final TextEditingController pillarProducerController;

  @override
  State<SubmitPillarUpdateStep> createState() => _SubmitPillarUpdateStepState();
}

class _SubmitPillarUpdateStepState extends State<SubmitPillarUpdateStep> {
  final GlobalKey<LoadingButtonState> _updateButtonKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return BlocListener<UpdatePillarBloc, UpdatePillarState>(
      listener: (_, UpdatePillarState state) {
        _onUpdatePillarStateChanged(state);
      },
      child: Row(
        children: <Widget>[
          OutlinedButton(
            onPressed: widget.onBackPressed,
            child: Text(context.l10n.goBack),
          ),
          kHorizontalGap25,
          LoadingButton.stepper(
            onPressed: _onUpdatePressed,
            text: context.l10n.update,
            key: _updateButtonKey,
          ),
        ],
      ),
    );
  }

  void _onUpdatePillarStateChanged(UpdatePillarState state) {
    if (state is UpdatePillarDone) {
      _updateButtonKey.currentState?.animateReverse();
      widget.onUpdateDone();
    } else if (state is UpdatePillarFailure) {
      _updateButtonKey.currentState?.animateReverse();
      unawaited(
        NotificationUtils.sendNotificationError(
          state.exception,
          context.l10n.errorUpdatingPillar,
        ),
      );
    } else if (state is UpdatePillarLoading) {
      _updateButtonKey.currentState?.animateForward();
    }
  }

  void _onUpdatePressed() {
    context.read<UpdatePillarBloc>().add(
      UpdatePillarRequested(
        pillarName: widget.pillarNameController.text,
        blockProducingAddress: Address.parse(
          widget.pillarProducerController.text,
        ),
        rewardAddress: Address.parse(widget.pillarRewardController.text),
        giveBlockRewardPercentage: widget.momentumRewardPercentage.value
            .toInt(),
        giveDelegateRewardPercentage: widget.delegateRewardPercentage.value
            .toInt(),
      ),
    );
  }
}
