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

enum ProjectCreationStep {
  projectCreation,
  projectDetails,
  submitProject,
}

class ProjectCreationStepper extends StatefulWidget {
  const ProjectCreationStepper({super.key});

  @override
  State<ProjectCreationStepper> createState() => _ProjectCreationStepperState();
}

class _ProjectCreationStepperState extends State<ProjectCreationStepper> {
  ProjectCreationStep? _lastCompletedStep;
  ProjectCreationStep _currentStep = ProjectCreationStep.values.first;

  final TextEditingController _addressController = TextEditingController();
  TextEditingController _projectNameController = TextEditingController();
  TextEditingController _projectDescriptionController = TextEditingController();
  TextEditingController _projectUrlController = TextEditingController();
  TextEditingController _projectZnnAmountController = TextEditingController();
  TextEditingController _projectQsrAmountController = TextEditingController();

  GlobalKey<FormState> _projectNameKey = GlobalKey();
  GlobalKey<FormState> _projectDescriptionKey = GlobalKey();
  GlobalKey<FormState> _projectUrlKey = GlobalKey();
  GlobalKey<FormState> _projectZnnKey = GlobalKey();
  GlobalKey<FormState> _projectQsrKey = GlobalKey();

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
      builder: (_, AsyncSnapshot<Map<String, AccountInfo>?> snapshot) {
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
      children: <Widget>[
        ListView(
          children: <Widget>[
            _getMaterialStepper(context, accountInfo),
          ],
        ),
        Visibility(
          visible: _lastCompletedStep == ProjectCreationStep.values.last,
          child: Positioned(
            bottom: 20,
            right: 0,
            left: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                StepperButton.icon(
                  label: 'Create another project',
                  onPressed: () {
                    _clearInput();
                    setState(() {
                      _currentStep = ProjectCreationStep.values.first;
                      _lastCompletedStep = null;
                    });
                  },
                  iconData: Icons.refresh,
                ),
                const SizedBox(
                  width: 75,
                ),
                StepperButton(
                  text: 'View projects',
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        ),
        Visibility(
          visible: _lastCompletedStep == ProjectCreationStep.values.last,
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

  void _clearInput() {
    _projectNameController = TextEditingController();
    _projectDescriptionController = TextEditingController();
    _projectUrlController = TextEditingController();
    _projectZnnAmountController = TextEditingController();
    _projectQsrAmountController = TextEditingController();
    _projectNameKey = GlobalKey();
    _projectDescriptionKey = GlobalKey();
    _projectUrlKey = GlobalKey();
    _projectZnnKey = GlobalKey();
    _projectQsrKey = GlobalKey();
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
        steps: <custom_material_stepper.Step>[
          StepperUtils.getMaterialStep(
            stepTitle: 'Project creation',
            stepContent: _getProjectCreationStepContent(accountInfo),
            stepSubtitle: _addressController.text,
            stepState: StepperUtils.getStepState(
              ProjectCreationStep.projectCreation.index,
              _lastCompletedStep?.index,
            ),
            context: context,
          ),
          StepperUtils.getMaterialStep(
            stepTitle: 'Project details',
            stepContent: _getProjectDetailsStepContent(accountInfo),
            stepSubtitle: '${_projectNameController.text} ● '
                '${_projectZnnAmountController.text} ${kZnnCoin.symbol} ● '
                '${_projectQsrAmountController.text} ${kQsrCoin.symbol}',
            stepState: StepperUtils.getStepState(
              ProjectCreationStep.projectDetails.index,
              _lastCompletedStep?.index,
            ),
            context: context,
          ),
          StepperUtils.getMaterialStep(
            stepTitle: 'Submit project',
            stepContent: _getSubmitProjectStepContent(),
            stepSubtitle: 'Project submitted',
            stepState: StepperUtils.getStepState(
              ProjectCreationStep.submitProject.index,
              _lastCompletedStep?.index,
            ),
            context: context,
          ),
        ],
      ),
    );
  }

  Widget _getProjectCreationStepContent(AccountInfo accountInfo) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text('This will be your project owner address'),
        kVerticalSpacing,
        DisabledAddressField(_addressController),
        StepperUtils.getBalanceWidget(kZnnCoin, accountInfo),
        DottedBorderInfoWidget(
          text:
              'Creating a project consumes ${projectCreationFeeInZnn.addDecimals(coinDecimals)} ${kZnnCoin.symbol} that goes to the Accelerator',
        ),
        kVerticalSpacing,
        Row(
          children: <Widget>[
            StepperButton(
              onPressed: () {
                Navigator.pop(context);
              },
              text: 'Cancel',
            ),
            const SizedBox(
              width: 15,
            ),
            StepperButton(
              onPressed: accountInfo.getBalance(
                        kZnnCoin.tokenStandard,
                      ) >=
                      projectCreationFeeInZnn
                  ? () {
                      setState(() {
                        _lastCompletedStep =
                            ProjectCreationStep.projectCreation;
                        _currentStep = ProjectCreationStep.projectDetails;
                      });
                    }
                  : null,
              text: 'Continue',
            ),
          ],
        ),
      ],
    );
  }

  Widget _getProjectDetailsStepContent(AccountInfo accountInfo) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Form(
                key: _projectNameKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: InputField(
                  controller: _projectNameController,
                  hintText: 'Project name',
                  onChanged: (String value) {
                    setState(() {});
                  },
                  validator: Validations.projectName,
                ),
              ),
            ),
            // Empty space so that all the right edges will align
            const SizedBox(
              width: 23,
            ),
          ],
        ),
        kVerticalSpacing,
        Row(
          children: <Widget>[
            Expanded(
              child: Form(
                key: _projectDescriptionKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: InputField(
                  controller: _projectDescriptionController,
                  hintText: 'Project description',
                  onChanged: (String value) {
                    setState(() {});
                  },
                  validator: Validations.projectDescription,
                ),
              ),
            ),
            // Empty space so that all the right edges will align
            const SizedBox(
              width: 23,
            ),
          ],
        ),
        kVerticalSpacing,
        Row(
          children: <Widget>[
            Expanded(
              child: Form(
                key: _projectUrlKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: InputField(
                  controller: _projectUrlController,
                  hintText: 'Project URL',
                  onChanged: (String value) {
                    setState(() {});
                  },
                  validator: InputValidators.checkUrl,
                ),
              ),
            ),
            const StandardTooltipIcon(
              'Link to project article',
              Icons.help,
            ),
          ],
        ),
        kVerticalSpacing,
        Row(
          children: <Widget>[
            Text(
              'Total project budget',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const StandardTooltipIcon(
              'Set a budget for the project',
              Icons.help,
            ),
          ],
        ),
        kVerticalSpacing,
        Row(
          children: <Widget>[
            Expanded(
              child: Form(
                key: _projectZnnKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: InputField(
                  inputFormatters: FormatUtils.getAmountTextInputFormatters(
                    _projectZnnAmountController.text,
                  ),
                  controller: _projectZnnAmountController,
                  hintText: 'ZNN Amount',
                  suffixIcon: AmountSuffixWidgets(
                    kZnnCoin,
                    onMaxPressed: () {
                      final BigInt maxZnn = kZnnProjectMaximumFunds;
                      if (_projectZnnAmountController.text.isEmpty ||
                          _projectZnnAmountController.text
                                  .extractDecimals(coinDecimals) <
                              maxZnn) {
                        setState(() {
                          _projectZnnAmountController.text =
                              maxZnn.addDecimals(coinDecimals);
                        });
                      }
                    },
                  ),
                  validator: (String? value) => InputValidators.correctValue(
                    value,
                    kZnnProjectMaximumFunds,
                    kZnnCoin.decimals,
                    kZnnProjectMinimumFunds,
                    canBeEqualToMin: true,
                  ),
                  onChanged: (String value) {
                    setState(() {});
                  },
                ),
              ),
            ),
            // Empty space so that all the right edges will align
            const SizedBox(
              width: 23,
            ),
          ],
        ),
        kVerticalSpacing,
        Row(
          children: <Widget>[
            Expanded(
              child: Form(
                key: _projectQsrKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: InputField(
                  inputFormatters: FormatUtils.getAmountTextInputFormatters(
                    _projectQsrAmountController.text,
                  ),
                  controller: _projectQsrAmountController,
                  hintText: 'QSR Amount',
                  suffixIcon: AmountSuffixWidgets(
                    kQsrCoin,
                    onMaxPressed: () {
                      final BigInt maxQsr = kQsrProjectMaximumFunds;
                      if (_projectQsrAmountController.text.isEmpty ||
                          _projectQsrAmountController.text
                                  .extractDecimals(coinDecimals) <
                              maxQsr) {
                        setState(() {
                          _projectQsrAmountController.text =
                              maxQsr.addDecimals(coinDecimals);
                        });
                      }
                    },
                  ),
                  validator: (String? value) => InputValidators.correctValue(
                    value,
                    kQsrProjectMaximumFunds,
                    kQsrCoin.decimals,
                    kQsrProjectMinimumFunds,
                    canBeEqualToMin: true,
                  ),
                  onChanged: (String value) {
                    setState(() {});
                  },
                ),
              ),
            ),
            const SizedBox(
              width: 23,
            ),
          ],
        ),
        kVerticalSpacing,
        Row(
          children: <Widget>[
            StepperButton(
              text: 'Cancel',
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            const SizedBox(
              width: 15,
            ),
            StepperButton(
              text: 'Continue',
              onPressed: _areInputDetailsValid()
                  ? () {
                      setState(() {
                        _lastCompletedStep = ProjectCreationStep.projectDetails;
                        _currentStep = ProjectCreationStep.submitProject;
                      });
                    }
                  : null,
            ),
          ],
        ),
      ],
    );
  }

  Widget _getSubmitProjectStepContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        DottedBorderInfoWidget(
          text:
              'Consume ${projectCreationFeeInZnn.addDecimals(coinDecimals)} ${kZnnCoin.symbol} to submit the project',
        ),
        kVerticalSpacing,
        Row(
          children: <Widget>[
            StepperButton(
              onPressed: () {
                setState(() {
                  _currentStep = ProjectCreationStep.projectDetails;
                  _lastCompletedStep = ProjectCreationStep.projectCreation;
                });
              },
              text: 'Go back',
            ),
            const SizedBox(
              width: 15,
            ),
            _getSubmitProjectViewModel(),
          ],
        ),
      ],
    );
  }

  Widget _getSubmitProjectViewModel() {
    return ViewModelBuilder<CreateProjectBloc>.reactive(
      onViewModelReady: (CreateProjectBloc model) {
        model.stream.listen(
          (AccountBlockTemplate? event) {
            if (event != null) {
              _submitButtonKey.currentState?.animateReverse();
              setState(() {
                _lastCompletedStep = ProjectCreationStep.submitProject;
              });
            }
          },
          onError: (error) async {
            _submitButtonKey.currentState?.animateReverse();
            await NotificationUtils.sendNotificationError(
              error,
              'Error while submitting project',
            );
          },
        );
      },
      builder: (_, CreateProjectBloc model, __) => _getSubmitProjectButton(model),
      viewModelBuilder: CreateProjectBloc.new,
    );
  }

  Widget _getSubmitProjectButton(CreateProjectBloc model) {
    return LoadingButton.stepper(
      onPressed: () {
        _submitButtonKey.currentState?.animateForward();
        model.createProject(
          _projectNameController.text,
          _projectDescriptionController.text,
          _projectUrlController.text,
          _projectZnnAmountController.text.extractDecimals(
            coinDecimals,
          ),
          _projectQsrAmountController.text.extractDecimals(
            coinDecimals,
          ),
        );
      },
      text: 'Submit',
      key: _submitButtonKey,
    );
  }

  bool _areInputDetailsValid() =>
      Validations.projectName(
            _projectNameController.text,
          ) ==
          null &&
      Validations.projectDescription(
            _projectDescriptionController.text,
          ) ==
          null &&
      InputValidators.checkUrl(
            _projectUrlController.text,
          ) ==
          null &&
      InputValidators.correctValue(
            _projectZnnAmountController.text,
            kZnnProjectMaximumFunds,
            kZnnCoin.decimals,
            kZnnProjectMinimumFunds,
            canBeEqualToMin: true,
          ) ==
          null &&
      InputValidators.correctValue(
            _projectQsrAmountController.text,
            kQsrProjectMaximumFunds,
            kZnnCoin.decimals,
            kQsrProjectMinimumFunds,
            canBeEqualToMin: true,
          ) ==
          null;

  @override
  void dispose() {
    _addressController.dispose();
    _projectNameController.dispose();
    _projectDescriptionController.dispose();
    _projectUrlController.dispose();
    _projectZnnAmountController.dispose();
    _projectQsrAmountController.dispose();
    super.dispose();
  }
}
