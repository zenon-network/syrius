import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/create_pillar_stepper/view/widgets/pillar_reward_sliders.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// Deploy step for registering a pillar.
class DeployPillarStep extends StatefulWidget {
  /// Creates a [DeployPillarStep].
  const DeployPillarStep({
    required this.onDeployDone,
    super.key,
  });

  /// Called when deployment completes.
  final VoidCallback onDeployDone;

  @override
  State<DeployPillarStep> createState() => _DeployPillarStepState();
}

class _DeployPillarStepState extends State<DeployPillarStep> {
  final GlobalKey<LoadingButtonState> _registerButtonKey = GlobalKey();

  final TextEditingController _pillarNameController = TextEditingController();
  final TextEditingController _pillarRewardAddressController =
      TextEditingController();
  final TextEditingController _pillarMomentumController =
      TextEditingController();

  String? get _pillarNameError =>
      Validations.pillarName(_pillarNameController.text);

  String? get _pillarRewardAddressError =>
      InputValidators.checkAddress(_pillarRewardAddressController.text);

  String? get _pillarMomentumError =>
      InputValidators.validatePillarMomentumAddress(
        _pillarMomentumController.text,
      );

  final ValueNotifier<double> _momentumRewardPercentage = .new(0);
  final ValueNotifier<double> _delegateRewardPercentage = .new(0);

  @override
  void initState() {
    super.initState();
    _pillarRewardAddressController.text = kSelectedAddress!;
  }

  @override
  void dispose() {
    _pillarNameController.dispose();
    _pillarRewardAddressController.dispose();
    _pillarMomentumController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<DeployPillarBloc, DeployPillarState>(
      listener: (_, DeployPillarState state) => _onDeployStateChanged(state),
      child: ListenableBuilder(
        listenable: Listenable.merge(<Listenable>[
          _pillarNameController,
          _pillarMomentumController,
          _pillarRewardAddressController,
        ]),
        builder: (_, _) => _buildBody(context),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _buildTextFields(context),
        kVerticalSpacing,
        PillarRewardSliders(
          delegateRewardPercentage: _delegateRewardPercentage,
          momentumRewardPercentage: _momentumRewardPercentage,
        ),
        kVerticalGap25,
        LoadingButton(
          text: context.l10n.register,
          onPressed: _isInputValid() ? _onDeployPressed : null,
          key: _registerButtonKey,
        ),
        kVerticalGap25,
      ],
    );
  }

  Column _buildTextFields(BuildContext context) {
    return Column(
      children: [
        Row(
          children: <Widget>[
            Expanded(
              child: TextField(
                controller: _pillarNameController,
                decoration: InputDecoration(
                  errorText: _pillarNameController.text.isNotEmpty
                      ? _pillarNameError
                      : null,
                  hintText: context.l10n.pillarName,
                ),
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
                controller: _pillarRewardAddressController,
                decoration: InputDecoration(
                  errorText: _pillarRewardAddressController.text.isNotEmpty
                      ? _pillarRewardAddressError
                      : null,
                  hintText: context.l10n.pillarRewardAddress,
                  suffixIcon: FieldSuffixButtons(
                    controller: _pillarRewardAddressController,
                  ),
                ),
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
                controller: _pillarMomentumController,
                decoration: InputDecoration(
                  errorText: _pillarMomentumController.text.isNotEmpty
                      ? _pillarMomentumError
                      : null,
                  hintText: context.l10n.pillarProducerAddress,
                  suffixIcon: FieldSuffixButtons(
                    controller: _pillarMomentumController,
                  ),
                ),
              ),
            ),
            StandardTooltipIcon(
              context.l10n.addressToProduceMomentums,
              Icons.help,
            ),
          ],
        ),
      ],
    );
  }

  void _onDeployStateChanged(DeployPillarState state) {
    if (state is DeployPillarDone) {
      _registerButtonKey.currentState?.animateReverse();
      _pillarNameController.clear();
      _pillarRewardAddressController.clear();
      _pillarMomentumController.clear();
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

  bool _isInputValid() =>
      _pillarNameError == null &&
      _pillarRewardAddressError == null &&
      _pillarMomentumError == null;

  void _onDeployPressed() {
    context.read<DeployPillarBloc>().add(
      DeployPillarRequested(
        pillarName: _pillarNameController.text,
        rewardAddress: Address.parse(_pillarRewardAddressController.text),
        blockProducingAddress: Address.parse(
          _pillarMomentumController.text,
        ),
        giveBlockRewardPercentage: _momentumRewardPercentage.value.toInt(),
        giveDelegateRewardPercentage: _delegateRewardPercentage.value.toInt(),
      ),
    );
  }
}
