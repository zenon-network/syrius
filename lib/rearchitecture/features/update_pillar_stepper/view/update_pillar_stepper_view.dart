import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/custom_material_stepper.dart'
    as custom_material_stepper;
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

enum _Step {
  pillarDetails,
  pillarMomentumReward,
  pillarUpdate,
}

/// A stepper that aids the user in the process of updating pillar details
class UpdatePillarStepperView extends StatefulWidget {
  /// {@macro default_constructor}
  const UpdatePillarStepperView({required PillarInfo pillarInfo, super.key})
    : _pillarInfo = pillarInfo;

  final PillarInfo _pillarInfo;

  @override
  State<UpdatePillarStepperView> createState() =>
      _UpdatePillarStepperViewState();
}

class _UpdatePillarStepperViewState extends State<UpdatePillarStepperView> {
  final TextEditingController _pillarNameController = TextEditingController();
  final TextEditingController _pillarRewardController = TextEditingController();
  final TextEditingController _pillarProducerController =
      TextEditingController();

  // When value is null, it means the stepper has completed.
  final ValueNotifier<_Step?> _currentStep = .new(
    .pillarDetails,
  );

  late final ValueNotifier<double> _momentumRewardPercentageGiven;
  late final ValueNotifier<double> _delegateRewardPercentageGiven;

  @override
  void initState() {
    super.initState();
    _pillarNameController.text = widget._pillarInfo.name;
    _pillarRewardController.text = widget._pillarInfo.withdrawAddress
        .toString();
    _pillarProducerController.text = widget._pillarInfo.producerAddress
        .toString();
    _momentumRewardPercentageGiven = ValueNotifier<double>(
      widget._pillarInfo.giveMomentumRewardPercentage.toDouble(),
    );
    _delegateRewardPercentageGiven = ValueNotifier<double>(
      widget._pillarInfo.giveDelegateRewardPercentage.toDouble(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<_Step?>(
      valueListenable: _currentStep,
      builder: (_, _Step? currentStep, _) {
        final bool hasPillarBeenUpdated = currentStep == null;

        return Stack(
          children: <Widget>[
            ListView(
              children: <Widget>[
                _getMaterialStepper(currentStep: currentStep),
              ],
            ),
            if (hasPillarBeenUpdated)
              PillarUpdatedSuccess(onViewPillarsPressed: _onViewPillarsPressed),
            if (hasPillarBeenUpdated) const PillarUpdatedSuccessAnimation(),
          ],
        );
      },
    );
  }

  Widget _getMaterialStepper({required _Step? currentStep}) {
    final int lastStepIndex = _Step.values.last.index;

    custom_material_stepper.StepState getStepState(
      _Step step,
      _Step? currentStep,
    ) {
      return step.index < (currentStep?.index ?? lastStepIndex + 1)
          ? custom_material_stepper.StepState.complete
          : custom_material_stepper.StepState.indexed;
    }

    return custom_material_stepper.Stepper(
      currentStep: currentStep?.index ?? lastStepIndex,
      onStepTapped: (int index) {},
      steps: <custom_material_stepper.Step>[
        StepperUtils.getMaterialStep(
          stepTitle: context.l10n.pillarDetails,
          stepContent: PillarUpdateDetailsStep(
            onCancelPressed: _onCancelPressed,
            onNextPressed: _navigateToNextStep,
            pillarNameController: _pillarNameController,
            pillarProducerController: _pillarProducerController,
            pillarRewardController: _pillarRewardController,
          ),
          stepSubtitle: _pillarNameController.text,
          stepState: getStepState(
            _Step.pillarDetails,
            currentStep,
          ),
          context: context,
        ),
        StepperUtils.getMaterialStep(
          stepTitle: context.l10n.pillarMomentumAddress,
          stepContent: PillarUpdateRewardsStep(
            delegateRewardPercentage: _delegateRewardPercentageGiven,
            momentumRewardPercentage: _momentumRewardPercentageGiven,
            onBackPressed: _navigateToPreviousStep,
            onNextPressed: _navigateToNextStep,
          ),
          stepSubtitle:
              '${context.l10n.momentumPercentageGiven(
                _momentumRewardPercentageGiven.value,
              )}'
              '\n'
              '${context.l10n.delegationPercentageGiven(
                _delegateRewardPercentageGiven.value,
              )}',
          stepState: getStepState(
            _Step.pillarMomentumReward,
            currentStep,
          ),
          context: context,
        ),
        StepperUtils.getMaterialStep(
          stepTitle: context.l10n.pillarUpdate,
          stepContent: SubmitPillarUpdateStep(
            delegateRewardPercentage: _delegateRewardPercentageGiven,
            momentumRewardPercentage: _momentumRewardPercentageGiven,
            onBackPressed: _navigateToPreviousStep,
            onUpdateDone: _onUpdateDone,
            pillarNameController: _pillarNameController,
            pillarProducerController: _pillarProducerController,
            pillarRewardController: _pillarRewardController,
          ),
          stepSubtitle: context.l10n.pillarUpdated,
          stepState: getStepState(
            _Step.pillarUpdate,
            currentStep,
          ),
          context: context,
        ),
      ],
    );
  }

  void _onCancelPressed() {
    Navigator.pop(context);
  }

  void _onViewPillarsPressed() {
    Navigator.pop(context);
  }

  void _onUpdateDone() {
    // All steps have been completed.
    _currentStep.value = null;
  }

  void _navigateToNextStep() {
    final int currentStepIndex = _currentStep.value!.index;

    _currentStep.value = _Step.values[currentStepIndex + 1];
  }

  void _navigateToPreviousStep() {
    final int currentStepIndex = _currentStep.value!.index;

    _currentStep.value = _Step.values[currentStepIndex - 1];
  }

  @override
  void dispose() {
    _pillarNameController.dispose();
    _pillarRewardController.dispose();
    _pillarProducerController.dispose();
    _momentumRewardPercentageGiven.dispose();
    _delegateRewardPercentageGiven.dispose();
    _currentStep.dispose();
    super.dispose();
  }
}
