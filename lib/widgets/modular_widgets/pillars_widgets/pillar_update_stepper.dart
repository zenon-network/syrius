import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:stacked/stacked.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/utils/input_validators.dart';
import 'package:zenon_syrius_wallet_flutter/utils/notification_utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/custom_material_stepper.dart'
    as custom_material_stepper;
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

enum PillarUpdateStep {
  pillarDetails,
  pillarMomentumReward,
  pillarUpdate,
}

class PillarUpdateStepper extends StatefulWidget {
  final PillarInfo pillarInfo;

  const PillarUpdateStepper(this.pillarInfo, {Key? key}) : super(key: key);

  @override
  State<PillarUpdateStepper> createState() => _PillarUpdateStepperState();
}

class _PillarUpdateStepperState extends State<PillarUpdateStepper> {
  PillarUpdateStep? _lastCompletedStep;
  PillarUpdateStep _currentStep = PillarUpdateStep.values.first;

  final TextEditingController _pillarNameController = TextEditingController();
  final TextEditingController _pillarRewardController = TextEditingController();
  final TextEditingController _pillarProducerController =
      TextEditingController();

  final FocusNode _pillarRewardNode = FocusNode();
  final FocusNode _pillarMomentumNode = FocusNode();

  final GlobalKey<FormState> _pillarRewardKey = GlobalKey();
  final GlobalKey<FormState> _pillarMomentumKey = GlobalKey();
  final GlobalKey<LoadingButtonState> _updateButtonKey = GlobalKey();

  late double _momentumRewardPercentageGiven;

  late double _delegateRewardPercentageGiven;

  @override
  void initState() {
    super.initState();
    _pillarNameController.text = widget.pillarInfo.name;
    _pillarRewardController.text = widget.pillarInfo.withdrawAddress.toString();
    _pillarProducerController.text =
        widget.pillarInfo.producerAddress.toString();
    _momentumRewardPercentageGiven =
        widget.pillarInfo.giveMomentumRewardPercentage.toDouble();
    _delegateRewardPercentageGiven =
        widget.pillarInfo.giveDelegateRewardPercentage.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ListView(
          children: [
            _getMaterialStepper(),
          ],
        ),
        Visibility(
          visible: _lastCompletedStep == PillarUpdateStep.pillarUpdate,
          child: Positioned(
            bottom: 20.0,
            right: 0.0,
            left: 0.0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                StepperButton(
                  text: 'View Pillars',
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        ),
        Visibility(
          visible: _lastCompletedStep == PillarUpdateStep.pillarUpdate,
          child: Positioned(
            right: 50.0,
            child: SizedBox(
              width: 400.0,
              height: 400.0,
              child: Center(
                child: Lottie.asset('assets/lottie/ic_anim_pillar.json',
                    repeat: false),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _getMaterialStepper() {
    return Theme(
      data: Theme.of(context).copyWith(
        highlightColor: Colors.transparent,
        splashColor: Colors.transparent,
        hoverColor: Colors.transparent,
      ),
      child: custom_material_stepper.Stepper(
        currentStep: _currentStep.index,
        onStepTapped: (int index) {},
        steps: [
          StepperUtils.getMaterialStep(
            stepTitle: 'Pillar details',
            stepContent: _getPillarDetailsStepContent(),
            stepSubtitle: _pillarNameController.text,
            stepState: StepperUtils.getStepState(
              PillarUpdateStep.pillarDetails.index,
              _lastCompletedStep?.index,
            ),
            context: context,
          ),
          StepperUtils.getMaterialStep(
            stepTitle: 'Pillar momentum rewards',
            stepContent: _getPillarMomentumRewardsStepContent(),
            stepSubtitle:
                'Momentum percentage given: $_momentumRewardPercentageGiven'
                '\n'
                'Delegation percentage given: $_delegateRewardPercentageGiven',
            stepState: StepperUtils.getStepState(
              PillarUpdateStep.pillarMomentumReward.index,
              _lastCompletedStep?.index,
            ),
            context: context,
          ),
          StepperUtils.getMaterialStep(
            stepTitle: 'Pillar update',
            stepContent: _getPillarUpdateStepContent(),
            stepSubtitle: 'Pillar updated',
            stepState: StepperUtils.getStepState(
              PillarUpdateStep.pillarUpdate.index,
              _lastCompletedStep?.index,
            ),
            context: context,
          ),
        ],
      ),
    );
  }

  Widget _getPillarDetailsStepContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pillar name',
          style: Theme.of(context).textTheme.bodyText1,
        ),
        kVerticalSpacing,
        InputField(
          controller: _pillarNameController,
          enabled: false,
        ),
        kVerticalSpacing,
        Text(
          'Pillar reward address',
          style: Theme.of(context).textTheme.bodyText1,
        ),
        kVerticalSpacing,
        Form(
          key: _pillarRewardKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: InputField(
            hintText: 'Pillar reward address',
            controller: _pillarRewardController,
            thisNode: _pillarRewardNode,
            nextNode: _pillarMomentumNode,
            validator: InputValidators.checkAddress,
            onChanged: (value) {
              setState(() {});
            },
          ),
        ),
        kVerticalSpacing,
        Text(
          'Pillar producer address',
          style: Theme.of(context).textTheme.bodyText1,
        ),
        kVerticalSpacing,
        Form(
          key: _pillarMomentumKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: InputField(
            hintText: 'Pillar producer address',
            controller: _pillarProducerController,
            thisNode: _pillarMomentumNode,
            validator: (value) => InputValidators.validatePillarMomentumAddress(
              value,
            ),
            onChanged: (value) {
              setState(() {});
            },
          ),
        ),
        kVerticalSpacing,
        Row(
          children: [
            StepperButton(
              onPressed: () {
                Navigator.pop(context);
              },
              text: 'Cancel',
            ),
            const SizedBox(
              width: 25.0,
            ),
            StepperButton(
              onPressed: _arePillarDetailsValid()
                  ? () {
                      setState(() {
                        _lastCompletedStep = PillarUpdateStep.pillarDetails;
                        _currentStep = PillarUpdateStep.pillarMomentumReward;
                      });
                    }
                  : null,
              text: 'Next',
            ),
          ],
        ),
      ],
    );
  }

  Widget _getPillarMomentumRewardsStepContent() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Percentage of momentum rewards given to the delegators',
              style: Theme.of(context).textTheme.headline6,
            ),
          ],
        ),
        CustomSlider(
          activeColor: AppColors.znnColor,
          description: '',
          startValue: widget.pillarInfo.giveMomentumRewardPercentage.toDouble(),
          min: 0.0,
          maxValue: 100.0,
          callback: (double value) {
            setState(() {
              _momentumRewardPercentageGiven = value;
            });
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Pillar: ${100 - _momentumRewardPercentageGiven.toInt()}',
              style: Theme.of(context).textTheme.subtitle1,
            ),
            Text(
              'Delegators: ${_momentumRewardPercentageGiven.toInt()}',
              style: Theme.of(context).textTheme.subtitle1,
            ),
          ],
        ),
        kVerticalSpacing,
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Percentage of delegation rewards given to the delegators',
              style: Theme.of(context).textTheme.headline6,
            ),
          ],
        ),
        CustomSlider(
          activeColor: AppColors.znnColor,
          description: '',
          startValue: widget.pillarInfo.giveDelegateRewardPercentage.toDouble(),
          min: 0.0,
          maxValue: 100.0,
          callback: (double value) {
            setState(() {
              _delegateRewardPercentageGiven = value;
            });
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Pillar: ${100 - _delegateRewardPercentageGiven.toInt()}',
              style: Theme.of(context).textTheme.subtitle1,
            ),
            Text(
              'Delegators: ${_delegateRewardPercentageGiven.toInt()}',
              style: Theme.of(context).textTheme.subtitle1,
            ),
          ],
        ),
        kVerticalSpacing,
        Row(
          children: [
            StepperButton(
              onPressed: () {
                setState(() {
                  _lastCompletedStep = null;
                  _currentStep = PillarUpdateStep.pillarDetails;
                });
              },
              text: 'Go back',
            ),
            const SizedBox(
              width: 25.0,
            ),
            StepperButton(
              onPressed: () {
                setState(() {
                  _lastCompletedStep = PillarUpdateStep.pillarMomentumReward;
                  _currentStep = PillarUpdateStep.pillarUpdate;
                });
              },
              text: 'Next',
            ),
          ],
        ),
      ],
    );
  }

  Widget _getPillarUpdateStepContent() {
    return Row(
      children: [
        StepperButton(
          onPressed: () {
            setState(() {
              _lastCompletedStep = PillarUpdateStep.pillarDetails;
              _currentStep = PillarUpdateStep.pillarMomentumReward;
            });
          },
          text: 'Go back',
        ),
        const SizedBox(
          width: 25.0,
        ),
        _getUpdatePillarViewModel(),
      ],
    );
  }

  Widget _getUpdatePillarButton(UpdatePillarBloc model) {
    return LoadingButton.stepper(
      onPressed: () {
        _updateButtonKey.currentState?.animateForward();
        model.updatePillar(
          _pillarNameController.text,
          Address.parse(_pillarProducerController.text),
          Address.parse(_pillarRewardController.text),
          _momentumRewardPercentageGiven.toInt(),
          _delegateRewardPercentageGiven.toInt(),
        );
      },
      text: 'Update',
      key: _updateButtonKey,
    );
  }

  bool _arePillarDetailsValid() =>
      InputValidators.checkAddress(_pillarRewardController.text) == null &&
      InputValidators.validatePillarMomentumAddress(
              _pillarProducerController.text) ==
          null;

  Widget _getUpdatePillarViewModel() {
    return ViewModelBuilder<UpdatePillarBloc>.reactive(
      onViewModelReady: (model) {
        model.stream.listen(
          (event) {
            if (event != null) {
              _updateButtonKey.currentState?.animateReverse();
              setState(() {
                _lastCompletedStep = PillarUpdateStep.pillarUpdate;
              });
            }
          },
          onError: (error) {
            _updateButtonKey.currentState?.animateReverse();
            NotificationUtils.sendNotificationError(
              error,
              'Error while updating Pillar',
            );
          },
        );
      },
      builder: (_, model, __) => _getUpdatePillarButton(model),
      viewModelBuilder: () => UpdatePillarBloc(),
    );
  }

  @override
  void dispose() {
    _pillarNameController.dispose();
    _pillarRewardController.dispose();
    _pillarProducerController.dispose();
    _pillarMomentumNode.dispose();
    _pillarRewardNode.dispose();
    super.dispose();
  }
}
