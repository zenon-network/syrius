import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/create_project_stepper/create_project_stepper.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/multiple_balance/multiple_balance.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/custom_material_stepper.dart'
    as custom_material_stepper;
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

enum _ProjectCreationStep { projectCreation, projectDetails, submitProject }

/// Guides the user through creating a new Accelerator-Z project.
class CreateProjectStepperView extends StatefulWidget {
  /// Creates a [CreateProjectStepperView].
  const CreateProjectStepperView({this._onProjectCreated, super.key});

  final VoidCallback? _onProjectCreated;

  @override
  State<CreateProjectStepperView> createState() =>
      _CreateProjectStepperViewState();
}

class _CreateProjectStepperViewState extends State<CreateProjectStepperView> {
  _ProjectCreationStep? _lastCompletedStep;
  _ProjectCreationStep _currentStep = _ProjectCreationStep.values.first;

  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _projectNameController = TextEditingController();
  final TextEditingController _projectDescriptionController =
      TextEditingController();
  final TextEditingController _projectUrlController = TextEditingController();
  final TextEditingController _projectZnnAmountController =
      TextEditingController();
  final TextEditingController _projectQsrAmountController =
      TextEditingController();

  GlobalKey<FormState> _projectNameKey = GlobalKey<FormState>();
  GlobalKey<FormState> _projectDescriptionKey = GlobalKey<FormState>();
  GlobalKey<FormState> _projectUrlKey = GlobalKey<FormState>();
  GlobalKey<FormState> _projectZnnKey = GlobalKey<FormState>();
  GlobalKey<FormState> _projectQsrKey = GlobalKey<FormState>();

  final GlobalKey<LoadingButtonState> _submitButtonKey =
      GlobalKey<LoadingButtonState>();

  @override
  void initState() {
    super.initState();
    _addressController.text = kSelectedAddress!;
    context.read<MultipleBalanceBloc>().add(
      MultipleBalanceFetch(
        addresses: kDefaultAddressList.whereType<String>().toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<CreateProjectBloc, CreateProjectState>(
      listener: _onCreateProjectStateChanged,
      child: BlocBuilder<MultipleBalanceBloc, MultipleBalanceState>(
        builder: (BuildContext context, MultipleBalanceState state) {
          return switch (state.status) {
            MultipleBalanceStatus.failure => SyriusErrorWidget(state.error!),
            MultipleBalanceStatus.initial ||
            MultipleBalanceStatus.loading => const SyriusLoadingWidget(),
            MultipleBalanceStatus.success => _buildLoadedBody(
              context,
              state.data?[_addressController.text],
            ),
          };
        },
      ),
    );
  }

  void _onCreateProjectStateChanged(
    BuildContext context,
    CreateProjectState state,
  ) {
    switch (state) {
      case CreateProjectInitial():
        break;
      case CreateProjectLoading():
        _submitButtonKey.currentState?.animateForward();
      case CreateProjectDone():
        _submitButtonKey.currentState?.animateReverse();
        widget._onProjectCreated?.call();
        setState(() {
          _lastCompletedStep = _ProjectCreationStep.submitProject;
        });
      case CreateProjectFailure(:final SyriusException exception):
        _submitButtonKey.currentState?.animateReverse();
        unawaited(
          NotificationUtils.sendNotificationError(
            exception,
            context.l10n.errorSubmittingProject,
          ),
        );
    }
  }

  Widget _buildLoadedBody(BuildContext context, AccountInfo? accountInfo) {
    if (accountInfo == null) {
      return const SyriusLoadingWidget();
    }
    return _buildWidgetBody(context, accountInfo);
  }

  Widget _buildWidgetBody(BuildContext context, AccountInfo accountInfo) {
    final bool isCompleted =
        _lastCompletedStep == _ProjectCreationStep.values.last;

    return Stack(
      children: <Widget>[
        ListView(
          children: <Widget>[_buildMaterialStepper(context, accountInfo)],
        ),
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
                  label: context.l10n.createAnotherProject,
                  onPressed: () {
                    _clearInput();
                    setState(() {
                      _currentStep = _ProjectCreationStep.values.first;
                      _lastCompletedStep = null;
                    });
                  },
                  iconData: Icons.refresh,
                ),
                const SizedBox(width: 75),
                StepperButton(
                  text: context.l10n.viewProjects,
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

  void _clearInput() {
    _projectNameController.clear();
    _projectDescriptionController.clear();
    _projectUrlController.clear();
    _projectZnnAmountController.clear();
    _projectQsrAmountController.clear();
    _projectNameKey = GlobalKey<FormState>();
    _projectDescriptionKey = GlobalKey<FormState>();
    _projectUrlKey = GlobalKey<FormState>();
    _projectZnnKey = GlobalKey<FormState>();
    _projectQsrKey = GlobalKey<FormState>();
  }

  Widget _buildMaterialStepper(BuildContext context, AccountInfo accountInfo) {
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
            stepTitle: context.l10n.projectCreation,
            stepContent: _buildProjectCreationStepContent(context, accountInfo),
            stepSubtitle: _addressController.text,
            stepState: StepperUtils.getStepState(
              _ProjectCreationStep.projectCreation.index,
              _lastCompletedStep?.index,
            ),
            context: context,
          ),
          StepperUtils.getMaterialStep(
            stepTitle: context.l10n.projectDetails,
            stepContent: _buildProjectDetailsStepContent(context),
            stepSubtitle:
                '${_projectNameController.text} ● '
                '${_projectZnnAmountController.text} ${kZnnCoin.symbol} ● '
                '${_projectQsrAmountController.text} ${kQsrCoin.symbol}',
            stepState: StepperUtils.getStepState(
              _ProjectCreationStep.projectDetails.index,
              _lastCompletedStep?.index,
            ),
            context: context,
          ),
          StepperUtils.getMaterialStep(
            stepTitle: context.l10n.submitProject,
            stepContent: _buildSubmitProjectStepContent(context),
            stepSubtitle: context.l10n.projectSubmitted,
            stepState: StepperUtils.getStepState(
              _ProjectCreationStep.submitProject.index,
              _lastCompletedStep?.index,
            ),
            context: context,
          ),
        ],
      ),
    );
  }

  Widget _buildProjectCreationStepContent(
    BuildContext context,
    AccountInfo accountInfo,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(context.l10n.yourProjectOwnerAddress),
        kVerticalSpacing,
        DisabledAddressField(_addressController),
        StepperUtils.getBalanceWidget(kZnnCoin, accountInfo),
        DottedBorderInfoWidget(
          text: context.l10n.creatingProjectConsumesZnn(
            projectCreationFeeInZnn.addDecimals(coinDecimals),
            kZnnCoin.symbol,
          ),
        ),
        kVerticalSpacing,
        Row(
          children: <Widget>[
            StepperButton(
              onPressed: () {
                Navigator.pop(context);
              },
              text: context.l10n.cancel,
            ),
            const SizedBox(width: 15),
            StepperButton(
              onPressed:
                  accountInfo.getBalance(kZnnCoin.tokenStandard) >=
                      projectCreationFeeInZnn
                  ? () {
                      setState(() {
                        _lastCompletedStep =
                            _ProjectCreationStep.projectCreation;
                        _currentStep = _ProjectCreationStep.projectDetails;
                      });
                    }
                  : null,
              text: context.l10n.continueText,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildProjectDetailsStepContent(BuildContext context) {
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
                  hintText: context.l10n.projectName,
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
                key: _projectDescriptionKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: InputField(
                  controller: _projectDescriptionController,
                  hintText: context.l10n.projectDescription,
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
                key: _projectUrlKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: InputField(
                  controller: _projectUrlController,
                  hintText: context.l10n.projectUrl,
                  onChanged: (String value) {
                    setState(() {});
                  },
                  validator: InputValidators.checkUrl,
                ),
              ),
            ),
            StandardTooltipIcon(context.l10n.linkToProjectArticle, Icons.help),
          ],
        ),
        kVerticalSpacing,
        Row(
          children: <Widget>[
            Text(
              context.l10n.totalProjectBudget,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            StandardTooltipIcon(context.l10n.setBudgetForProject, Icons.help),
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
                  hintText: context.l10n.znnAmount,
                  suffixIcon: AmountSuffixWidgets(
                    kZnnCoin,
                    onMaxPressed: () {
                      final BigInt maxZnn = kZnnProjectMaximumFunds;
                      if (_projectZnnAmountController.text.isEmpty ||
                          _projectZnnAmountController.text.extractDecimals(
                                coinDecimals,
                              ) <
                              maxZnn) {
                        setState(() {
                          _projectZnnAmountController.text = maxZnn.addDecimals(
                            coinDecimals,
                          );
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
            const SizedBox(width: 23),
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
                  hintText: context.l10n.qsrAmount,
                  suffixIcon: AmountSuffixWidgets(
                    kQsrCoin,
                    onMaxPressed: () {
                      final BigInt maxQsr = kQsrProjectMaximumFunds;
                      if (_projectQsrAmountController.text.isEmpty ||
                          _projectQsrAmountController.text.extractDecimals(
                                coinDecimals,
                              ) <
                              maxQsr) {
                        setState(() {
                          _projectQsrAmountController.text = maxQsr.addDecimals(
                            coinDecimals,
                          );
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
                        _lastCompletedStep =
                            _ProjectCreationStep.projectDetails;
                        _currentStep = _ProjectCreationStep.submitProject;
                      });
                    }
                  : null,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSubmitProjectStepContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        DottedBorderInfoWidget(
          text: context.l10n.consumeZnnToSubmitProject(
            projectCreationFeeInZnn.addDecimals(coinDecimals),
            kZnnCoin.symbol,
          ),
        ),
        kVerticalSpacing,
        Row(
          children: <Widget>[
            StepperButton(
              onPressed: () {
                setState(() {
                  _currentStep = _ProjectCreationStep.projectDetails;
                  _lastCompletedStep = _ProjectCreationStep.projectCreation;
                });
              },
              text: context.l10n.goBack,
            ),
            const SizedBox(width: 15),
            LoadingButton.stepper(
              onPressed: () {
                context.read<CreateProjectBloc>().add(
                  CreateProjectRequested(
                    address: Address.parse(_addressController.text),
                    name: _projectNameController.text,
                    description: _projectDescriptionController.text,
                    url: _projectUrlController.text,
                    znnFundsNeeded: _projectZnnAmountController.text
                        .extractDecimals(coinDecimals),
                    qsrFundsNeeded: _projectQsrAmountController.text
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
    );
  }

  bool _areInputDetailsValid() =>
      Validations.projectName(_projectNameController.text) == null &&
      Validations.projectDescription(_projectDescriptionController.text) ==
          null &&
      InputValidators.checkUrl(_projectUrlController.text) == null &&
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
            kQsrCoin.decimals,
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
