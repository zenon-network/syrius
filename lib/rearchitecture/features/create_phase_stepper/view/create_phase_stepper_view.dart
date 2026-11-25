import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/accelerator_donation_stepper/accelerator_donation_stepper.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/create_phase_stepper/create_phase_stepper.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/custom_material_stepper.dart'
    as custom_material_stepper;
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

enum _PhaseCreationStep { phaseDetails, submitPhase }

/// Guides the project owner through creating a new Accelerator phase.
class CreatePhaseStepperView extends StatefulWidget {
  /// Creates a [CreatePhaseStepperView].
  const CreatePhaseStepperView({
    required this._project,
    this._onPhaseCreated,
    super.key,
  });

  final Project _project;
  final VoidCallback? _onPhaseCreated;

  @override
  State<CreatePhaseStepperView> createState() => _CreatePhaseStepperViewState();
}

class _CreatePhaseStepperViewState extends State<CreatePhaseStepperView> {
  _PhaseCreationStep? _lastCompletedStep;
  _PhaseCreationStep _currentStep = _PhaseCreationStep.values.first;

  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phaseNameController = TextEditingController();
  final TextEditingController _phaseDescriptionController =
      TextEditingController();
  final TextEditingController _phaseUrlController = TextEditingController();
  final TextEditingController _phaseZnnAmountController =
      TextEditingController();
  final TextEditingController _phaseQsrAmountController =
      TextEditingController();

  GlobalKey<FormState> _phaseNameKey = GlobalKey<FormState>();
  GlobalKey<FormState> _phaseDescriptionKey = GlobalKey<FormState>();
  GlobalKey<FormState> _phaseUrlKey = GlobalKey<FormState>();
  GlobalKey<FormState> _phaseZnnAmountKey = GlobalKey<FormState>();
  GlobalKey<FormState> _phaseQsrAmountKey = GlobalKey<FormState>();

  final GlobalKey<LoadingButtonState> _submitButtonKey =
      GlobalKey<LoadingButtonState>();

  @override
  void initState() {
    super.initState();
    _addressController.text = kSelectedAddress!;
  }

  @override
  Widget build(BuildContext context) {
    final bool isCompleted =
        _lastCompletedStep == _PhaseCreationStep.values.last;

    return Stack(
      children: <Widget>[
        ListView(children: <Widget>[_buildMaterialStepper(context)]),
        Visibility(
          visible: isCompleted,
          child: Positioned(
            bottom: 20,
            right: 0,
            left: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                StepperButton.icon(
                  label: context.l10n.createAnotherPhase,
                  onPressed: () {
                    _clearInput();
                    setState(() {
                      _currentStep = _PhaseCreationStep.values.first;
                      _lastCompletedStep = null;
                    });
                  },
                  iconData: Icons.refresh,
                ),
                const SizedBox(width: 75),
                StepperButton(
                  text: context.l10n.viewPhases,
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        ),
        Visibility(
          visible: isCompleted,
          child: Positioned(
            right: 50,
            child: SizedBox(
              width: 400,
              height: 400,
              child: Center(
                child: Lottie.asset(
                  'assets/lottie/ic_anim_zts.json',
                  repeat: false,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMaterialStepper(BuildContext context) {
    return Theme(
      data: Theme.of(context).copyWith(
        highlightColor: Colors.transparent,
        splashColor: Colors.transparent,
        hoverColor: Colors.transparent,
      ),
      child: custom_material_stepper.Stepper(
        currentStep: _currentStep.index,
        onStepTapped: (int index) {},
        steps: <custom_material_stepper.Step>[
          StepperUtils.getMaterialStep(
            stepTitle: context.l10n.phaseDetails,
            stepContent: _buildPhaseDetailsStepContent(context),
            stepSubtitle:
                '${_phaseNameController.text} ● '
                '${_phaseZnnAmountController.text} ${kZnnCoin.symbol} ● '
                '${_phaseQsrAmountController.text} ${kQsrCoin.symbol}',
            stepState: StepperUtils.getStepState(
              _PhaseCreationStep.phaseDetails.index,
              _lastCompletedStep?.index,
            ),
            context: context,
          ),
          StepperUtils.getMaterialStep(
            stepTitle: context.l10n.submitPhase,
            stepContent: _buildSubmitPhaseStepContent(context),
            stepSubtitle: context.l10n.idWithValue(
              widget._project.id.toShortString(),
            ),
            stepState: StepperUtils.getStepState(
              _PhaseCreationStep.submitPhase.index,
              _lastCompletedStep?.index,
            ),
            context: context,
          ),
        ],
      ),
    );
  }

  Widget _buildPhaseDetailsStepContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          context.l10n.phaseBelongsToProject(
            widget._project.id.toShortString(),
          ),
        ),
        kVerticalSpacing,
        Row(
          children: <Widget>[
            Expanded(
              child: Form(
                key: _phaseNameKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: InputField(
                  controller: _phaseNameController,
                  hintText: context.l10n.phaseName,
                  onChanged: (String value) {
                    setState(() {});
                  },
                  validator: Validations.projectName,
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
              child: Form(
                key: _phaseDescriptionKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: InputField(
                  controller: _phaseDescriptionController,
                  hintText: context.l10n.phaseDescription,
                  onChanged: (String value) {
                    setState(() {});
                  },
                  validator: Validations.projectDescription,
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
              child: Form(
                key: _phaseUrlKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: InputField(
                  controller: _phaseUrlController,
                  hintText: context.l10n.phaseUrl,
                  onChanged: (String value) {
                    setState(() {});
                  },
                  validator: InputValidators.checkUrl,
                ),
              ),
            ),
            StandardTooltipIcon(
              context.l10n.showcaseProgressOfProject,
              Icons.help,
            ),
          ],
        ),
        kVerticalSpacing,
        Row(
          children: <Widget>[
            Text(
              context.l10n.totalPhaseBudget,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            StandardTooltipIcon(
              context.l10n.necessaryBudgetToCompletePhase,
              Icons.help,
            ),
          ],
        ),
        kVerticalSpacing,
        Row(
          children: <Widget>[
            Expanded(
              child: Form(
                key: _phaseZnnAmountKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: InputField(
                  controller: _phaseZnnAmountController,
                  hintText: context.l10n.znnAmount,
                  suffixIcon: AmountSuffixWidgets(
                    kZnnCoin,
                    onMaxPressed: () {
                      setState(() {
                        _phaseZnnAmountController.text = widget._project
                            .getRemainingZnnFunds()
                            .addDecimals(coinDecimals);
                      });
                    },
                  ),
                  inputFormatters: FormatUtils.getAmountTextInputFormatters(
                    _phaseZnnAmountController.text,
                  ),
                  validator: (String? value) => validateAcceleratorAmount(
                    value: value,
                    maxValue: widget._project.getRemainingZnnFunds(),
                    decimals: coinDecimals,
                    minValue: BigInt.zero,
                    l10n: context.l10n,
                  ),
                  onChanged: (String value) {
                    setState(() {});
                  },
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
              child: Form(
                key: _phaseQsrAmountKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: InputField(
                  controller: _phaseQsrAmountController,
                  hintText: context.l10n.qsrAmount,
                  suffixIcon: AmountSuffixWidgets(
                    kQsrCoin,
                    onMaxPressed: () {
                      setState(() {
                        _phaseQsrAmountController.text = widget._project
                            .getRemainingQsrFunds()
                            .addDecimals(coinDecimals);
                      });
                    },
                  ),
                  inputFormatters: FormatUtils.getAmountTextInputFormatters(
                    _phaseQsrAmountController.text,
                  ),
                  validator: (String? value) => validateAcceleratorAmount(
                    value: value,
                    maxValue: widget._project.getRemainingQsrFunds(),
                    decimals: coinDecimals,
                    minValue: BigInt.zero,
                    l10n: context.l10n,
                  ),
                  onChanged: (String value) {
                    setState(() {});
                  },
                ),
              ),
            ),
            const SizedBox(width: 23),
          ],
        ),
        kVerticalSpacing,
        Row(
          children: <Widget>[
            StepperButton(
              text: context.l10n.cancel,
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            const SizedBox(width: 15),
            StepperButton(
              text: context.l10n.continueText,
              onPressed: _areInputDetailsValid()
                  ? () {
                      setState(() {
                        _lastCompletedStep = _PhaseCreationStep.phaseDetails;
                        _currentStep = _PhaseCreationStep.submitPhase;
                      });
                    }
                  : null,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSubmitPhaseStepContent(BuildContext context) {
    final BigInt remainingZnnBudget =
        widget._project.getRemainingZnnFunds() -
        _tryExtractAmount(_phaseZnnAmountController.text);
    final BigInt remainingQsrBudget =
        widget._project.getRemainingQsrFunds() -
        _tryExtractAmount(_phaseQsrAmountController.text);

    return BlocListener<CreatePhaseBloc, CreatePhaseState>(
      listener: (BuildContext context, CreatePhaseState state) {
        switch (state) {
          case CreatePhaseInitial():
            break;
          case CreatePhaseLoading():
            _submitButtonKey.currentState?.animateForward();
          case CreatePhaseDone():
            _submitButtonKey.currentState?.animateReverse();
            widget._onPhaseCreated?.call();
            setState(() {
              _lastCompletedStep = _PhaseCreationStep.values.last;
            });
          case CreatePhaseFailure(:final SyriusException exception):
            _submitButtonKey.currentState?.animateReverse();
            unawaited(
              NotificationUtils.sendNotificationError(
                exception,
                context.l10n.errorCreatingPhase,
              ),
            );
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          DottedBorderInfoWidget(
            text: context.l10n.remainingBudgetForNextPhases(
              remainingZnnBudget.addDecimals(coinDecimals),
              kZnnCoin.symbol,
              remainingQsrBudget.addDecimals(coinDecimals),
              kQsrCoin.symbol,
            ),
          ),
          kVerticalSpacing,
          Row(
            children: <Widget>[
              StepperButton(
                onPressed: () {
                  setState(() {
                    _currentStep = _PhaseCreationStep.phaseDetails;
                    _lastCompletedStep = null;
                  });
                },
                text: context.l10n.goBack,
              ),
              const SizedBox(width: 15),
              LoadingButton.stepper(
                onPressed: () {
                  context.read<CreatePhaseBloc>().add(
                    CreatePhaseRequested(
                      address: Address.parse(_addressController.text),
                      projectId: widget._project.id,
                      name: _phaseNameController.text,
                      description: _phaseDescriptionController.text,
                      url: _phaseUrlController.text,
                      znnFundsNeeded: _phaseZnnAmountController.text
                          .extractDecimals(coinDecimals),
                      qsrFundsNeeded: _phaseQsrAmountController.text
                          .extractDecimals(coinDecimals),
                    ),
                  );
                },
                text: context.l10n.submit,
                key: _submitButtonKey,
              ),
            ],
          ),
        ],
      ),
    );
  }

  BigInt _tryExtractAmount(String value) {
    if (value.isEmpty) {
      return BigInt.zero;
    }
    try {
      return value.extractDecimals(coinDecimals);
    } on Object {
      return BigInt.zero;
    }
  }

  bool _areInputDetailsValid() =>
      Validations.projectName(_phaseNameController.text) == null &&
      Validations.projectDescription(_phaseDescriptionController.text) ==
          null &&
      InputValidators.checkUrl(_phaseUrlController.text) == null &&
      validateAcceleratorAmount(
            value: _phaseZnnAmountController.text,
            maxValue: widget._project.getRemainingZnnFunds(),
            decimals: coinDecimals,
            minValue: BigInt.zero,
          ) ==
          null &&
      validateAcceleratorAmount(
            value: _phaseQsrAmountController.text,
            maxValue: widget._project.getRemainingQsrFunds(),
            decimals: coinDecimals,
            minValue: BigInt.zero,
          ) ==
          null;

  void _clearInput() {
    _phaseNameController.clear();
    _phaseDescriptionController.clear();
    _phaseUrlController.clear();
    _phaseZnnAmountController.clear();
    _phaseQsrAmountController.clear();
    _phaseNameKey = GlobalKey<FormState>();
    _phaseDescriptionKey = GlobalKey<FormState>();
    _phaseUrlKey = GlobalKey<FormState>();
    _phaseZnnAmountKey = GlobalKey<FormState>();
    _phaseQsrAmountKey = GlobalKey<FormState>();
  }

  @override
  void dispose() {
    _addressController.dispose();
    _phaseNameController.dispose();
    _phaseDescriptionController.dispose();
    _phaseUrlController.dispose();
    _phaseZnnAmountController.dispose();
    _phaseQsrAmountController.dispose();
    super.dispose();
  }
}
