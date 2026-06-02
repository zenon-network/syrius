import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/custom_material_stepper.dart'
    as custom_material_stepper;
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

enum _PillarUpdateStep {
  pillarDetails,
  pillarMomentumReward,
  pillarUpdate,
}

/// A stepper that aids the user in the process of updating pillar details
class UpdatePillarStepperView extends StatefulWidget {
  /// {@macro default_constructor}
  const UpdatePillarStepperView({required this._pillarInfo, super.key});

  final PillarInfo _pillarInfo;

  @override
  State<UpdatePillarStepperView> createState() =>
      _UpdatePillarStepperViewState();
}

class _UpdatePillarStepperViewState extends State<UpdatePillarStepperView> {
  _PillarUpdateStep? _lastCompletedStep;
  _PillarUpdateStep _currentStep = _PillarUpdateStep.values.first;

  final TextEditingController _pillarNameController = TextEditingController();
  final TextEditingController _pillarRewardController = TextEditingController();
  final TextEditingController _pillarProducerController =
      TextEditingController();

  final GlobalKey<LoadingButtonState> _updateButtonKey = GlobalKey();

  late double _momentumRewardPercentageGiven;

  late double _delegateRewardPercentageGiven;

  @override
  void initState() {
    super.initState();
    _pillarNameController.text = widget._pillarInfo.name;
    _pillarRewardController.text = widget._pillarInfo.withdrawAddress
        .toString();
    _pillarProducerController.text = widget._pillarInfo.producerAddress
        .toString();
    _momentumRewardPercentageGiven = widget
        ._pillarInfo
        .giveMomentumRewardPercentage
        .toDouble();
    _delegateRewardPercentageGiven = widget
        ._pillarInfo
        .giveDelegateRewardPercentage
        .toDouble();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        ListView(
          children: <Widget>[
            _getMaterialStepper(),
          ],
        ),
        Visibility(
          visible: _lastCompletedStep == _PillarUpdateStep.pillarUpdate,
          child: Positioned(
            bottom: 20,
            right: 0,
            left: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                StepperButton(
                  text: context.l10n.viewPillars,
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        ),
        Visibility(
          visible: _lastCompletedStep == _PillarUpdateStep.pillarUpdate,
          child: Positioned(
            right: 50,
            child: SizedBox(
              width: 400,
              height: 400,
              child: Center(
                child: Lottie.asset(
                  'assets/lottie/ic_anim_pillar.json',
                  repeat: false,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _getMaterialStepper() {
    return custom_material_stepper.Stepper(
      currentStep: _currentStep.index,
      onStepTapped: (int index) {},
      steps: <custom_material_stepper.Step>[
        StepperUtils.getMaterialStep(
          stepTitle: context.l10n.pillarDetails,
          stepContent: _buildPillarDetailsStepContent(),
          stepSubtitle: _pillarNameController.text,
          stepState: StepperUtils.getStepState(
            _PillarUpdateStep.pillarDetails.index,
            _lastCompletedStep?.index,
          ),
          context: context,
        ),
        StepperUtils.getMaterialStep(
          stepTitle: context.l10n.pillarMomentumAddress,
          stepContent: _buildPillarMomentumRewardsStepContent(),
          stepSubtitle:
              '${context.l10n.momentumPercentageGiven(
                _momentumRewardPercentageGiven,
              )}'
              '\n '
              '${context.l10n.delegationPercentageGiven(
                _delegateRewardPercentageGiven,
              )}',
          stepState: StepperUtils.getStepState(
            _PillarUpdateStep.pillarMomentumReward.index,
            _lastCompletedStep?.index,
          ),
          context: context,
        ),
        StepperUtils.getMaterialStep(
          stepTitle: context.l10n.pillarUpdate,
          stepContent: _buildPillarUpdateStepContent(),
          stepSubtitle: context.l10n.pillarUpdated,
          stepState: StepperUtils.getStepState(
            _PillarUpdateStep.pillarUpdate.index,
            _lastCompletedStep?.index,
          ),
          context: context,
        ),
      ],
    );
  }

  Widget _buildPillarDetailsStepContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          context.l10n.pillarName,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        kVerticalSpacing,
        TextField(
          controller: _pillarNameController,
          enabled: false,
          style: const TextStyle(
            color: AppColors.znnColor,
          ),
        ),
        kVerticalSpacing,
        Text(
          context.l10n.pillarRewardAddress,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        kVerticalSpacing,
        TextFormField(
          autovalidateMode: AutovalidateMode.onUserInteraction,
          decoration: InputDecoration(
            hintText: context.l10n.pillarRewardAddress,
            suffixIcon: FieldSuffixButtons(controller: _pillarRewardController),
          ),
          controller: _pillarRewardController,
          validator: InputValidators.checkAddress,
          style: const TextStyle(
            color: AppColors.znnColor,
          ),
        ),
        kVerticalSpacing,
        Text(
          context.l10n.pillarProducerAddress,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        kVerticalSpacing,
        TextFormField(
          autovalidateMode: AutovalidateMode.onUserInteraction,
          controller: _pillarProducerController,
          decoration: InputDecoration(
            hintText: context.l10n.pillarProducerAddress,
            suffixIcon: FieldSuffixButtons(
              controller: _pillarProducerController,
            ),
          ),
          style: const TextStyle(
            color: AppColors.znnColor,
          ),
          validator: InputValidators.validatePillarMomentumAddress,
        ),
        kVerticalSpacing,
        Row(
          children: <Widget>[
            OutlinedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text(context.l10n.cancel),
            ),
            kHorizontalGap25,
            ListenableBuilder(
              listenable: Listenable.merge(<Listenable?>[
                _pillarRewardController,
                _pillarProducerController,
              ]),
              builder: (_, _) => OutlinedButton(
                onPressed: _arePillarDetailsValid()
                    ? () {
                        setState(() {
                          _lastCompletedStep = _PillarUpdateStep.pillarDetails;
                          _currentStep = _PillarUpdateStep.pillarMomentumReward;
                        });
                      }
                    : null,
                child: Text(context.l10n.next),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPillarMomentumRewardsStepContent() {
    return Column(
      children: <Widget>[
        CustomSlider(
          description: context.l10n.percentageOfMomentumRewards,
          descriptionPosition: .top,
          startValue: widget._pillarInfo.giveMomentumRewardPercentage
              .toDouble(),
          min: 0,
          maxValue: 100,
          callback: (double value) {
            setState(() {
              _momentumRewardPercentageGiven = value;
            });
          },
        ),
        DefaultTextStyle(
          style: context.newThemeData.textTheme.titleSmall!,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                context.l10n.pillarsWithNumber(
                  100 - _momentumRewardPercentageGiven.toInt(),
                ),
              ),
              Text(
                context.l10n.delegators(_momentumRewardPercentageGiven.toInt()),
              ),
            ],
          ),
        ),
        kVerticalSpacing,
        CustomSlider(
          description: context.l10n.percentageDelegationRewardsGiven,
          descriptionPosition: .top,
          startValue: widget._pillarInfo.giveDelegateRewardPercentage
              .toDouble(),
          min: 0,
          maxValue: 100,
          callback: (double value) {
            setState(() {
              _delegateRewardPercentageGiven = value;
            });
          },
        ),
        DefaultTextStyle(
          style: context.newThemeData.textTheme.titleSmall!,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Text(
                context.l10n.pillarsWithNumber(
                  100 - _delegateRewardPercentageGiven.toInt(),
                ),
              ),
              Text(
                context.l10n.delegators(_delegateRewardPercentageGiven.toInt()),
              ),
            ],
          ),
        ),
        kVerticalSpacing,
        Row(
          children: <Widget>[
            OutlinedButton(
              onPressed: () {
                setState(() {
                  _lastCompletedStep = null;
                  _currentStep = _PillarUpdateStep.pillarDetails;
                });
              },
              child: Text(context.l10n.goBack),
            ),
            kHorizontalGap25,
            OutlinedButton(
              onPressed: () {
                setState(() {
                  _lastCompletedStep = _PillarUpdateStep.pillarMomentumReward;
                  _currentStep = _PillarUpdateStep.pillarUpdate;
                });
              },
              child: Text(context.l10n.next),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPillarUpdateStepContent() {
    return Row(
      children: <Widget>[
        OutlinedButton(
          onPressed: () {
            setState(() {
              _lastCompletedStep = _PillarUpdateStep.pillarDetails;
              _currentStep = _PillarUpdateStep.pillarMomentumReward;
            });
          },
          child: Text(context.l10n.goBack),
        ),
        kHorizontalGap25,
        _buildUpdatePillarButton(),
      ],
    );
  }

  bool _arePillarDetailsValid() =>
      InputValidators.checkAddress(_pillarRewardController.text) == null &&
      InputValidators.validatePillarMomentumAddress(
            _pillarProducerController.text,
          ) ==
          null;

  Widget _buildUpdatePillarButton() {
    return BlocListener<UpdatePillarBloc, UpdatePillarState>(
      listener: (_, UpdatePillarState state) {
        if (state is UpdatePillarDone) {
          _updateButtonKey.currentState?.animateReverse();
          setState(() {
            _lastCompletedStep = _PillarUpdateStep.pillarUpdate;
          });
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
      },
      child: LoadingButton.stepper(
        onPressed: () {
          _updateButtonKey.currentState?.animateForward();
          context.read<UpdatePillarBloc>().add(
            UpdatePillarRequested(
              pillarName: _pillarNameController.text,
              blockProducingAddress: Address.parse(
                _pillarProducerController.text,
              ),
              rewardAddress: Address.parse(_pillarRewardController.text),
              giveBlockRewardPercentage: _momentumRewardPercentageGiven.toInt(),
              giveDelegateRewardPercentage: _delegateRewardPercentageGiven
                  .toInt(),
            ),
          );
        },
        text: context.l10n.update,
        key: _updateButtonKey,
      ),
    );
  }

  @override
  void dispose() {
    _pillarNameController.dispose();
    _pillarRewardController.dispose();
    _pillarProducerController.dispose();
    super.dispose();
  }
}
