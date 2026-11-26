import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/accelerator_donation_stepper/accelerator_donation_stepper.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/update_phase_stepper/update_phase_stepper.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/custom_material_stepper.dart'
    as custom_material_stepper;
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

enum _UpdatePhaseStep { phaseDetails, updatePhase }

/// Guides the project owner through updating an active voting phase.
class UpdatePhaseStepperView extends StatefulWidget {
  /// Creates an [UpdatePhaseStepperView].
  const UpdatePhaseStepperView({
    required this._phase,
    required this._project,
    this._onPhaseUpdated,
    super.key,
  });

  final Phase _phase;
  final Project _project;
  final VoidCallback? _onPhaseUpdated;

  @override
  State<UpdatePhaseStepperView> createState() => _UpdatePhaseStepperViewState();
}

class _UpdatePhaseStepperViewState extends State<UpdatePhaseStepperView> {
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _phaseNameController = TextEditingController();
  final TextEditingController _phaseDescriptionController =
      TextEditingController();
  final TextEditingController _phaseUrlController = TextEditingController();
  final TextEditingController _phaseZnnAmountController =
      TextEditingController();
  final TextEditingController _phaseQsrAmountController =
      TextEditingController();

  final GlobalKey<FormState> _phaseNameKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _phaseDescriptionKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _phaseUrlKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _phaseZnnAmountKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _phaseQsrAmountKey = GlobalKey<FormState>();
  final GlobalKey<LoadingButtonState> _updateButtonKey =
      GlobalKey<LoadingButtonState>();

  _UpdatePhaseStep? _lastCompletedStep;
  _UpdatePhaseStep _currentStep = _UpdatePhaseStep.values.first;

  @override
  void initState() {
    super.initState();
    _addressController.text = kSelectedAddress!;
    _phaseNameController.text = widget._phase.name;
    _phaseDescriptionController.text = widget._phase.description;
    _phaseUrlController.text = widget._phase.url;
    _phaseZnnAmountController.text = widget._phase.znnFundsNeeded.addDecimals(
      coinDecimals,
    );
    _phaseQsrAmountController.text = widget._phase.qsrFundsNeeded.addDecimals(
      coinDecimals,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isCompleted = _lastCompletedStep == _UpdatePhaseStep.updatePhase;

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
              _UpdatePhaseStep.phaseDetails.index,
              _lastCompletedStep?.index,
            ),
            context: context,
          ),
          StepperUtils.getMaterialStep(
            stepTitle: context.l10n.updatePhase,
            stepContent: _buildUpdatePhaseStepContent(context),
            stepSubtitle: context.l10n.idWithValue(
              widget._phase.id.toShortString(),
            ),
            stepState: StepperUtils.getStepState(
              _UpdatePhaseStep.updatePhase.index,
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
        Row(
          children: <Widget>[
            Expanded(
              child: Text(
                context.l10n.phaseBelongsToProject(
                  widget._project.id.toShortString(),
                ),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
          ],
        ),
        kVerticalSpacing,
        Form(
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
        kVerticalSpacing,
        Form(
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
        kVerticalSpacing,
        Form(
          key: _phaseUrlKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: InputField(
            controller: _phaseUrlController,
            hintText: context.l10n.phaseUrl,
            onChanged: (String value) {
              setState(() {});
            },
            validator: (String? value) =>
                InputValidators.checkUrl(value, l10n: context.l10n),
          ),
        ),
        kVerticalSpacing,
        Text(
          context.l10n.totalPhaseBudget,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        kVerticalSpacing,
        Form(
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
              decimals: kZnnCoin.decimals,
              minValue: BigInt.zero,
              l10n: context.l10n,
            ),
            onChanged: (String value) {
              setState(() {});
            },
          ),
        ),
        kVerticalSpacing,
        Form(
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
              decimals: kQsrCoin.decimals,
              minValue: BigInt.zero,
              l10n: context.l10n,
            ),
            onChanged: (String value) {
              setState(() {});
            },
          ),
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
                        _lastCompletedStep = _UpdatePhaseStep.phaseDetails;
                        _currentStep = _UpdatePhaseStep.updatePhase;
                      });
                    }
                  : null,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildUpdatePhaseStepContent(BuildContext context) {
    return BlocListener<UpdatePhaseBloc, UpdatePhaseState>(
      listener: (BuildContext context, UpdatePhaseState state) {
        switch (state) {
          case UpdatePhaseInitial():
            break;
          case UpdatePhaseLoading():
            _updateButtonKey.currentState?.animateForward();
          case UpdatePhaseDone():
            _updateButtonKey.currentState?.animateReverse();
            widget._onPhaseUpdated?.call();
            setState(() {
              _lastCompletedStep = _UpdatePhaseStep.updatePhase;
            });
          case UpdatePhaseFailure(:final SyriusException exception):
            _updateButtonKey.currentState?.animateReverse();
            unawaited(
              NotificationUtils.sendNotificationError(
                exception,
                context.l10n.errorUpdatingPhase,
              ),
            );
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          DottedBorderInfoWidget(text: context.l10n.updatingPhaseResetsVotes),
          kVerticalSpacing,
          Row(
            children: <Widget>[
              StepperButton(
                onPressed: () {
                  setState(() {
                    _currentStep = _UpdatePhaseStep.phaseDetails;
                    _lastCompletedStep = null;
                  });
                },
                text: context.l10n.goBack,
              ),
              const SizedBox(width: 15),
              LoadingButton.stepper(
                onPressed: () {
                  context.read<UpdatePhaseBloc>().add(
                    UpdatePhaseRequested(
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
                text: context.l10n.update,
                key: _updateButtonKey,
              ),
            ],
          ),
        ],
      ),
    );
  }

  bool _areInputDetailsValid() =>
      Validations.projectName(_phaseNameController.text) == null &&
      Validations.projectDescription(_phaseDescriptionController.text) ==
          null &&
      InputValidators.checkUrl(_phaseUrlController.text) == null &&
      validateAcceleratorAmount(
            value: _phaseZnnAmountController.text,
            maxValue: widget._project.getRemainingZnnFunds(),
            decimals: kZnnCoin.decimals,
            minValue: BigInt.zero,
          ) ==
          null &&
      validateAcceleratorAmount(
            value: _phaseQsrAmountController.text,
            maxValue: widget._project.getRemainingQsrFunds(),
            decimals: kQsrCoin.decimals,
            minValue: BigInt.zero,
          ) ==
          null;

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
