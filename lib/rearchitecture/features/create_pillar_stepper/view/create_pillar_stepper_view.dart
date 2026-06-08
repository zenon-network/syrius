import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/create_pillar_stepper/view/widgets/deploy_pillar_step.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/create_pillar_stepper/view/widgets/pillar_plasma_check_step.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/create_pillar_stepper/view/widgets/pillar_qsr_management_step.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/create_pillar_stepper/view/widgets/pillar_registered_success.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/create_pillar_stepper/view/widgets/pillar_znn_management_step.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/extensions.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:zenon_syrius_wallet_flutter/utils/input_validators.dart';
import 'package:zenon_syrius_wallet_flutter/utils/zts_utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/custom_material_stepper.dart'
    as custom_material_stepper;
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

enum _PillarStepperStep {
  checkPlasma,
  qsrManagement,
  znnManagement,
  deployPillar,
}

/// A stepper that guides the user along the needed steps that they have to
/// take to create a pillar.
///
/// The deposit QSR step works in such a way as to not allow the user to
/// deposit, by mistake, more QSR than it's needed for the creation of a
/// pillar.
///
/// For example, if 150k QSR are needed, then that's how much the user is
/// allowed to deposit totally.
class CreatePillarStepperView extends StatefulWidget {
  /// {@macro default_constructor}
  const CreatePillarStepperView({super.key});

  @override
  State createState() {
    return _MainPillarState();
  }
}

class _MainPillarState extends State<CreatePillarStepperView> {
  final TextEditingController _qsrAmountController = TextEditingController();
  final TextEditingController _pillarNameController = TextEditingController();
  final TextEditingController _pillarRewardAddressController =
      TextEditingController();
  final TextEditingController _pillarMomentumController =
      TextEditingController();
  final TextEditingController _znnAmountController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  final FocusNode _pillarNameNode = FocusNode();
  final FocusNode _pillarRewardNode = FocusNode();
  final FocusNode _pillarMomentumNode = FocusNode();

  String? get _pillarNameError =>
      Validations.pillarName(_pillarNameController.text);

  String? get _pillarRewardAddressError =>
      InputValidators.checkAddress(_pillarRewardAddressController.text);

  String? get _pillarMomentumError =>
      InputValidators.validatePillarMomentumAddress(
        _pillarMomentumController.text,
      );

  double _momentumRewardPercentageGiven = 0;
  double _delegateRewardPercentageGiven = 0;

  // When value is null, it means the stepper has completed
  final ValueNotifier<_PillarStepperStep?> _currentStep = .new(
    .checkPlasma,
  );

  @override
  void initState() {
    super.initState();
    _znnAmountController.text = pillarRegisterZnnAmount.addDecimals(
      coinDecimals,
    );
    _addressController.text = kSelectedAddress!;
    _pillarRewardAddressController.text = kSelectedAddress!;
    sl.get<MultipleBalanceBloc>().add(
      MultipleBalanceFetch(
        addresses: kDefaultAddressList.map((String? e) => e!).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MultipleBalanceBloc, MultipleBalanceState>(
      builder: (_, MultipleBalanceState state) => switch (state.status) {
        MultipleBalanceStatus.failure => SyriusErrorWidget(state.error!),
        MultipleBalanceStatus.initial => const SyriusLoadingWidget(),
        MultipleBalanceStatus.loading => const SyriusLoadingWidget(),
        MultipleBalanceStatus.success => _buildBody(
          context,
          state.data![_addressController.text]!,
        ),
      },
    );
  }

  Widget _buildBody(BuildContext context, AccountInfo accountInfo) {
    return ValueListenableBuilder<_PillarStepperStep?>(
      valueListenable: _currentStep,
      builder: (_, _PillarStepperStep? currentStep, _) {
        final bool hasPillarBeenRegistered = _currentStep.value == null;

        return Stack(
          children: <Widget>[
            ListView(
              children: <Widget>[
                _getMaterialStepper(
                  accountInfo: accountInfo,
                  currentStep: currentStep,
                ),
                if (hasPillarBeenRegistered)
                  PillarRegisteredSuccess(
                    onRegisterAnotherPressed:
                        _onDeployAnotherPillarButtonPressed,
                    onViewPillarsPressed: () {
                      Navigator.pop(context);
                    },
                  ),
              ],
            ),
            if (hasPillarBeenRegistered)
              const PillarRegisteredSuccessAnimation(),
          ],
        );
      },
    );
  }

  Widget _getMaterialStepper({
    required AccountInfo accountInfo,
    required _PillarStepperStep? currentStep,
  }) {
    // TODO(maznnwell): to be extracted to StepperUtils
    custom_material_stepper.StepState getStepState(
      _PillarStepperStep step,
      _PillarStepperStep? currentStep,
    ) {
      return step.index < (currentStep?.index ?? -1)
          ? custom_material_stepper.StepState.complete
          : custom_material_stepper.StepState.indexed;
    }

    return custom_material_stepper.Stepper(
      currentStep: currentStep?.index ?? 0,
      onStepTapped: (int index) {},
      steps: <custom_material_stepper.Step>[
        StepperUtils.getMaterialStep(
          stepTitle: context.l10n.pillarDeployment,
          stepContent: PillarPlasmaCheckStep(
            addressController: _addressController,
            onNextPressed: _onPlasmaCheckNextPressed,
          ),
          stepSubtitle: context.l10n.sufficientPlasma,
          stepState: getStepState(
            _PillarStepperStep.checkPlasma,
            _currentStep.value,
          ),
          context: context,
        ),
        StepperUtils.getMaterialStep(
          stepTitle: context.l10n.management(kQsrCoin.symbol),
          stepContent: PillarQsrManagementStep(
            accountInfo: accountInfo,
            addressController: _addressController,
            onNextPressed: _navigateToNextStep,
            qsrAmountController: _qsrAmountController,
          ),
          stepSubtitle: context.l10n.deposited(kQsrCoin.symbol),
          stepState: getStepState(
            _PillarStepperStep.qsrManagement,
            _currentStep.value,
          ),
          context: context,
          expanded: true,
        ),
        StepperUtils.getMaterialStep(
          stepTitle: context.l10n.management(kZnnCoin.symbol),
          stepContent: PillarZnnManagementStep(
            accountInfo: accountInfo,
            addressController: _addressController,
            onNextPressed: _navigateToNextStep,
            znnAmountController: _znnAmountController,
          ),
          stepSubtitle: context.l10n.locked(kZnnCoin.symbol),
          stepState: getStepState(
            _PillarStepperStep.znnManagement,
            _currentStep.value,
          ),
          context: context,
        ),
        StepperUtils.getMaterialStep(
          stepTitle: context.l10n.registerPillar,
          stepContent: DeployPillarStep(
            canDeployPillar: _canDeployPillar,
            delegateRewardPercentage: _delegateRewardPercentageGiven,
            momentumRewardPercentage: _momentumRewardPercentageGiven,
            onDeployDone: _onDeployDone,
            onDeployPressed: _onDeployPressed,
            onDelegateRewardChanged: (double value) {
              setState(() {
                _delegateRewardPercentageGiven = value;
              });
            },
            onMomentumRewardChanged: (double value) {
              setState(() {
                _momentumRewardPercentageGiven = value;
              });
            },
            pillarMomentumController: _pillarMomentumController,
            pillarMomentumError: () => _pillarMomentumError,
            pillarMomentumNode: _pillarMomentumNode,
            pillarNameController: _pillarNameController,
            pillarNameError: () => _pillarNameError,
            pillarNameNode: _pillarNameNode,
            pillarRewardAddressController: _pillarRewardAddressController,
            pillarRewardAddressError: () => _pillarRewardAddressError,
            pillarRewardNode: _pillarRewardNode,
          ),
          stepSubtitle: context.l10n.pillarRegistered,
          stepState: getStepState(
            _PillarStepperStep.deployPillar,
            _currentStep.value,
          ),
          context: context,
        ),
      ],
    );
  }

  void _refreshPillarQsrInfo() {
    context.read<CreatePillarQsrInfoBloc>().add(
      FetchRequestData(
        address: Address.parse(_addressController.text),
      ),
    );
  }

  void _onDeployDone() {
    // All steps have been completed
    _currentStep.value = null;
  }

  void _onDeployPressed() {
    context.read<DeployPillarBloc>().add(
      DeployPillarRequested(
        pillarName: _pillarNameController.text,
        rewardAddress: Address.parse(_pillarRewardAddressController.text),
        blockProducingAddress: Address.parse(
          _pillarMomentumController.text,
        ),
        giveBlockRewardPercentage: _momentumRewardPercentageGiven.toInt(),
        giveDelegateRewardPercentage: _delegateRewardPercentageGiven.toInt(),
      ),
    );
  }

  Future<void> _onDeployAnotherPillarButtonPressed() async {
    _pillarNameController.clear();
    _pillarRewardAddressController.clear();
    _pillarMomentumController.clear();
    _currentStep.value = .checkPlasma;
    _refreshPillarQsrInfo();
    _currentStep.value = _PillarStepperStep.values.first;
  }

  void _navigateToNextStep() {
    final int currentStepIndex = _currentStep.value!.index;

    _currentStep.value = _PillarStepperStep.values[currentStepIndex + 1];
  }

  bool _canDeployPillar() =>
      _pillarNameError == null &&
      _pillarRewardAddressError == null &&
      _pillarMomentumError == null;

  void _onPlasmaCheckNextPressed() {
    _navigateToNextStep();
    context.read<CreatePillarQsrInfoBloc>().add(
      FetchRequestData(address: Address.parse(_addressController.text)),
    );
  }

  @override
  void dispose() {
    _qsrAmountController.dispose();
    _pillarNameController.dispose();
    _pillarRewardAddressController.dispose();
    _pillarMomentumController.dispose();
    _znnAmountController.dispose();
    _addressController.dispose();
    _pillarNameNode.dispose();
    _pillarRewardNode.dispose();
    _pillarMomentumNode.dispose();
    super.dispose();
  }
}
