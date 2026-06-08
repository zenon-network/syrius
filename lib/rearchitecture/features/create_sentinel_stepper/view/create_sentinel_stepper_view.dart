import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/extensions.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:zenon_syrius_wallet_flutter/utils/zts_utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/custom_material_stepper.dart'
    as custom_material_stepper;
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

enum _Step {
  checkPlasma,
  qsrManagement,
  znnManagement,
  deploySentinel,
}

/// A stepper that guides the user through creating a sentinel.
class CreateSentinelStepperView extends StatefulWidget {
  /// {@macro default_constructor}
  const CreateSentinelStepperView({super.key});

  @override
  State<CreateSentinelStepperView> createState() => _MainSentinelState();
}

class _MainSentinelState extends State<CreateSentinelStepperView> {
  final TextEditingController _qsrAmountController = TextEditingController();
  final TextEditingController _znnAmountController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  // When value is null, it means the stepper has completed.
  final ValueNotifier<_Step?> _currentStep = .new(
    .checkPlasma,
  );

  @override
  void initState() {
    super.initState();
    _znnAmountController.text = sentinelRegisterZnnAmount.addDecimals(
      coinDecimals,
    );
    _addressController.text = kSelectedAddress!;
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
    return ValueListenableBuilder<_Step?>(
      valueListenable: _currentStep,
      builder: (_, _Step? currentStep, _) {
        final bool hasSentinelBeenRegistered = currentStep == null;

        return Stack(
          children: <Widget>[
            ListView(
              children: <Widget>[
                _buildMaterialStepper(
                  accountInfo: accountInfo,
                  currentStep: currentStep,
                ),
                if (hasSentinelBeenRegistered)
                  SentinelRegisteredSuccess(
                    onViewSentinelsPressed: () {
                      Navigator.pop(context);
                    },
                  ),
              ],
            ),
            if (hasSentinelBeenRegistered)
              const SentinelRegisteredSuccessAnimation(),
          ],
        );
      },
    );
  }

  Widget _buildMaterialStepper({
    required AccountInfo accountInfo,
    required _Step? currentStep,
  }) {
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
          stepTitle: context.l10n.sentinelDeployment,
          stepContent: SentinelPlasmaCheckStep(
            addressController: _addressController,
            onNextPressed: _onPlasmaCheckNextPressed,
          ),
          stepSubtitle: context.l10n.sufficientPlasma,
          stepState: getStepState(
            _Step.checkPlasma,
            currentStep,
          ),
          context: context,
        ),
        StepperUtils.getMaterialStep(
          stepTitle: context.l10n.management(kQsrCoin.symbol),
          stepContent: SentinelQsrManagementStep(
            accountInfo: accountInfo,
            addressController: _addressController,
            onNextPressed: _navigateToNextStep,
            qsrAmountController: _qsrAmountController,
          ),
          stepSubtitle: context.l10n.deposited(kQsrCoin.symbol),
          stepState: getStepState(
            _Step.qsrManagement,
            currentStep,
          ),
          context: context,
          expanded: true,
        ),
        StepperUtils.getMaterialStep(
          stepTitle: context.l10n.management(kZnnCoin.symbol),
          stepContent: SentinelZnnManagementStep(
            accountInfo: accountInfo,
            addressController: _addressController,
            onNextPressed: _navigateToNextStep,
            znnAmountController: _znnAmountController,
          ),
          stepSubtitle: context.l10n.locked(kZnnCoin.symbol),
          stepState: getStepState(
            _Step.znnManagement,
            currentStep,
          ),
          context: context,
        ),
        StepperUtils.getMaterialStep(
          stepTitle: context.l10n.registerSentinel,
          stepContent: DeploySentinelStep(
            onDeployDone: _onDeployDone,
          ),
          stepSubtitle: context.l10n.sentinelRegistered,
          stepState: getStepState(
            _Step.deploySentinel,
            currentStep,
          ),
          context: context,
        ),
      ],
    );
  }

  void _refreshSentinelQsrInfo() {
    context.read<CreateSentinelQsrInfoBloc>().add(
      FetchRequestData(
        address: Address.parse(_addressController.text),
      ),
    );
  }

  void _onDeployDone() {
    // All steps have been completed.
    _currentStep.value = null;
  }

  void _navigateToNextStep() {
    final int currentStepIndex = _currentStep.value!.index;

    _currentStep.value = _Step.values[currentStepIndex + 1];
  }

  void _onPlasmaCheckNextPressed() {
    _navigateToNextStep();
    _refreshSentinelQsrInfo();
  }

  @override
  void dispose() {
    _qsrAmountController.dispose();
    _znnAmountController.dispose();
    _addressController.dispose();
    _currentStep.dispose();
    super.dispose();
  }
}
