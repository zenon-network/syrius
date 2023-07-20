import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:stacked/stacked.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/custom_material_stepper.dart'
    as custom_material_stepper;
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

enum PhaseCreationStep {
  phaseDetails,
  submitPhase,
}

class PhaseCreationStepper extends StatefulWidget {
  final Project project;

  const PhaseCreationStepper(this.project, {Key? key}) : super(key: key);

  @override
  State<PhaseCreationStepper> createState() => _PhaseCreationStepperState();
}

class _PhaseCreationStepperState extends State<PhaseCreationStepper> {
  PhaseCreationStep? _lastCompletedStep;
  PhaseCreationStep _currentStep = PhaseCreationStep.values.first;

  final TextEditingController _addressController = TextEditingController();
  TextEditingController _phaseNameController = TextEditingController();
  TextEditingController _phaseDescriptionController = TextEditingController();
  TextEditingController _phaseUrlController = TextEditingController();
  TextEditingController _phaseZnnAmountController = TextEditingController();
  TextEditingController _phaseQsrAmountController = TextEditingController();

  GlobalKey<FormState> _phaseNameKey = GlobalKey();
  GlobalKey<FormState> _phaseDescriptionKey = GlobalKey();
  GlobalKey<FormState> _phaseUrlKey = GlobalKey();
  GlobalKey<FormState> _phaseZnnAmountKey = GlobalKey();
  GlobalKey<FormState> _phaseQsrAmountKey = GlobalKey();

  final GlobalKey<LoadingButtonState> _submitButtonKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _addressController.text = kSelectedAddress!;
    sl.get<BalanceBloc>().getBalanceForAllAddresses();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, AccountInfo>?>(
      stream: sl.get<BalanceBloc>().stream,
      builder: (_, snapshot) {
        if (snapshot.hasError) {
          return SyriusErrorWidget(snapshot.error!);
        }
        if (snapshot.connectionState == ConnectionState.active) {
          if (snapshot.hasData) {
            return _getWidgetBody(
              context,
              snapshot.data![_addressController.text]!,
            );
          }
          return const SyriusLoadingWidget();
        }
        return const SyriusLoadingWidget();
      },
    );
  }

  Widget _getWidgetBody(BuildContext context, AccountInfo accountInfo) {
    return Stack(
      children: [
        ListView(
          children: [
            _getMaterialStepper(context, accountInfo),
          ],
        ),
        Visibility(
          visible: _lastCompletedStep == PhaseCreationStep.values.last,
          child: Positioned(
            bottom: 20.0,
            right: 0.0,
            left: 0.0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                StepperButton.icon(
                  label: 'Create another phase',
                  onPressed: () {
                    _clearInput();
                    setState(() {
                      _currentStep = PhaseCreationStep.values.first;
                      _lastCompletedStep = null;
                    });
                  },
                  iconData: Icons.refresh,
                  context: context,
                ),
                const SizedBox(
                  width: 75.0,
                ),
                StepperButton(
                  text: 'View phases',
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        ),
        Visibility(
          visible: _lastCompletedStep == PhaseCreationStep.values.last,
          child: Positioned(
            right: 50.0,
            child: SizedBox(
              width: 400.0,
              height: 400.0,
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

  Widget _getMaterialStepper(BuildContext context, AccountInfo accountInfo) {
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
            stepTitle: 'Phase details',
            stepContent: _getPhaseDetailsStepContent(accountInfo),
            stepSubtitle: '${_phaseNameController.text} ● '
                '${_phaseZnnAmountController.text} ${kZnnCoin.symbol} ● '
                '${_phaseQsrAmountController.text} ${kQsrCoin.symbol}',
            stepState: StepperUtils.getStepState(
              PhaseCreationStep.phaseDetails.index,
              _lastCompletedStep?.index,
            ),
            context: context,
          ),
          StepperUtils.getMaterialStep(
            stepTitle: 'Submit phase',
            stepContent: _getSubmitPhaseStepContent(),
            stepSubtitle: 'ID ${widget.project.id.toShortString()}',
            stepState: StepperUtils.getStepState(
              PhaseCreationStep.submitPhase.index,
              _lastCompletedStep?.index,
            ),
            context: context,
          ),
        ],
      ),
    );
  }

  Widget _getPhaseDetailsStepContent(AccountInfo accountInfo) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('This phase belongs to Project ID '
            '${widget.project.id.toShortString()}'),
        kVerticalSpacing,
        Row(
          children: [
            Expanded(
              child: Form(
                key: _phaseNameKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: InputField(
                  controller: _phaseNameController,
                  hintText: 'Phase name',
                  onChanged: (value) {
                    setState(() {});
                  },
                  validator: Validations.projectName,
                ),
              ),
            ),
            // Empty space so that all the right edges will align
            const SizedBox(
              width: 23.0,
            ),
          ],
        ),
        kVerticalSpacing,
        Row(
          children: [
            Expanded(
              child: Form(
                key: _phaseDescriptionKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: InputField(
                  controller: _phaseDescriptionController,
                  hintText: 'Phase description',
                  onChanged: (value) {
                    setState(() {});
                  },
                  validator: Validations.projectDescription,
                ),
              ),
            ),
            // Empty space so that all the right edges will align
            const SizedBox(
              width: 23.0,
            ),
          ],
        ),
        kVerticalSpacing,
        Row(
          children: [
            Expanded(
              child: Form(
                key: _phaseUrlKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: InputField(
                  controller: _phaseUrlController,
                  hintText: 'Phase URL',
                  onChanged: (value) {
                    setState(() {});
                  },
                  validator: InputValidators.checkUrl,
                ),
              ),
            ),
            const StandardTooltipIcon(
              'Showcase the progress of your project (e.g. Git PR/commit)',
              Icons.help,
            ),
          ],
        ),
        kVerticalSpacing,
        Row(
          children: [
            Text(
              'Total phase budget',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const StandardTooltipIcon(
              'Necessary budget to successfully complete this phase',
              Icons.help,
            ),
          ],
        ),
        kVerticalSpacing,
        Row(
          children: [
            Expanded(
              child: Form(
                key: _phaseZnnAmountKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: InputField(
                  controller: _phaseZnnAmountController,
                  hintText: 'ZNN Amount',
                  suffixIcon: AmountSuffixWidgets(
                    kZnnCoin,
                    onMaxPressed: () {
                      setState(() {
                        _phaseZnnAmountController.text = widget.project
                            .getRemainingZnnFunds()
                            .addDecimals(coinDecimals);
                      });
                    },
                  ),
                  inputFormatters: FormatUtils.getAmountTextInputFormatters(
                    _phaseZnnAmountController.text,
                  ),
                  validator: (value) => InputValidators.correctValue(
                    value,
                    widget.project.getRemainingZnnFunds(),
                    coinDecimals,
                    BigInt.zero,
                    canBeEqualToMin: true,
                  ),
                  onChanged: (value) {
                    setState(() {});
                  },
                ),
              ),
            ),
            // Empty space so that all the right edges will align
            const SizedBox(
              width: 23.0,
            ),
          ],
        ),
        kVerticalSpacing,
        Row(
          children: [
            Expanded(
              child: Form(
                key: _phaseQsrAmountKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: InputField(
                  controller: _phaseQsrAmountController,
                  hintText: 'QSR Amount',
                  suffixIcon: AmountSuffixWidgets(
                    kQsrCoin,
                    onMaxPressed: () {
                      setState(() {
                        _phaseQsrAmountController.text = widget.project
                            .getRemainingQsrFunds()
                            .addDecimals(coinDecimals);
                      });
                    },
                  ),
                  inputFormatters: FormatUtils.getAmountTextInputFormatters(
                    _phaseQsrAmountController.text,
                  ),
                  validator: (value) => InputValidators.correctValue(
                    value,
                    widget.project.getRemainingQsrFunds(),
                    coinDecimals,
                    BigInt.zero,
                    canBeEqualToMin: true,
                  ),
                  onChanged: (value) {
                    setState(() {});
                  },
                ),
              ),
            ),
            // Empty space so that all the right edges will align
            const SizedBox(
              width: 23.0,
            ),
          ],
        ),
        kVerticalSpacing,
        Row(
          children: [
            StepperButton(
              text: 'Cancel',
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            const SizedBox(
              width: 15.0,
            ),
            StepperButton(
              text: 'Continue',
              onPressed: _areInputDetailsValid()
                  ? () {
                      setState(() {
                        _lastCompletedStep = PhaseCreationStep.phaseDetails;
                        _currentStep = PhaseCreationStep.submitPhase;
                      });
                    }
                  : null,
            ),
          ],
        ),
      ],
    );
  }

  Widget _getSubmitPhaseStepContent() {
    BigInt remainingZnnBudget = widget.project.getRemainingZnnFunds() -
        (_phaseZnnAmountController.text.isNotEmpty
            ? _phaseZnnAmountController.text.extractDecimals(coinDecimals)
            : BigInt.zero);

    BigInt remainingQsrBudget = widget.project.getRemainingQsrFunds() -
        (_phaseQsrAmountController.text.isNotEmpty
            ? _phaseQsrAmountController.text.extractDecimals(coinDecimals)
            : BigInt.zero);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DottedBorderInfoWidget(
          text: 'Remaining budget for the next phases is '
              '${remainingZnnBudget.addDecimals(coinDecimals)} ${kZnnCoin.symbol} and '
              '${remainingQsrBudget.addDecimals(coinDecimals)} ${kQsrCoin.symbol}',
        ),
        kVerticalSpacing,
        Row(
          children: [
            StepperButton(
              onPressed: () {
                setState(() {
                  _currentStep = PhaseCreationStep.phaseDetails;
                  _lastCompletedStep = null;
                });
              },
              text: 'Go back',
            ),
            const SizedBox(
              width: 15.0,
            ),
            _getCreatePhaseViewModel(),
          ],
        ),
      ],
    );
  }

  Widget _getSubmitButton(CreatePhaseBloc model) {
    return LoadingButton.stepper(
      onPressed: () {
        _submitButtonKey.currentState?.animateForward();
        model.createPhase(
          widget.project.id,
          _phaseNameController.text,
          _phaseDescriptionController.text,
          _phaseUrlController.text,
          _phaseZnnAmountController.text.extractDecimals(
            coinDecimals,
          ),
          _phaseQsrAmountController.text.extractDecimals(
            coinDecimals,
          ),
        );
      },
      text: 'Submit',
      key: _submitButtonKey,
    );
  }

  Widget _getCreatePhaseViewModel() {
    return ViewModelBuilder<CreatePhaseBloc>.reactive(
      onViewModelReady: (model) {
        model.stream.listen(
          (event) {
            if (event != null) {
              _submitButtonKey.currentState?.animateReverse();
              setState(() {
                _lastCompletedStep = PhaseCreationStep.values.last;
              });
            }
          },
          onError: (error) {
            _submitButtonKey.currentState?.animateReverse();
            NotificationUtils.sendNotificationError(
              error,
              'Error while creating phase',
            );
          },
        );
      },
      builder: (_, model, __) => _getSubmitButton(model),
      viewModelBuilder: () => CreatePhaseBloc(),
    );
  }

  bool _areInputDetailsValid() =>
      Validations.projectName(
            _phaseNameController.text,
          ) ==
          null &&
      Validations.projectDescription(
            _phaseDescriptionController.text,
          ) ==
          null &&
      InputValidators.checkUrl(
            _phaseUrlController.text,
          ) ==
          null &&
      InputValidators.correctValue(
            _phaseZnnAmountController.text,
            widget.project.getRemainingZnnFunds(),
            coinDecimals,
            BigInt.zero,
            canBeEqualToMin: true,
          ) ==
          null &&
      InputValidators.correctValue(
            _phaseQsrAmountController.text,
            widget.project.getRemainingQsrFunds(),
            coinDecimals,
            BigInt.zero,
            canBeEqualToMin: true,
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

  void _clearInput() {
    _phaseNameController = TextEditingController();
    _phaseDescriptionController = TextEditingController();
    _phaseUrlController = TextEditingController();
    _phaseZnnAmountController = TextEditingController();
    _phaseQsrAmountController = TextEditingController();
    _phaseNameKey = GlobalKey();
    _phaseDescriptionKey = GlobalKey();
    _phaseUrlKey = GlobalKey();
    _phaseZnnAmountKey = GlobalKey();
    _phaseQsrAmountKey = GlobalKey();
  }
}
