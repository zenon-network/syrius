import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:lottie/lottie.dart';
import 'package:stacked/stacked.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/dashboard/balance_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/pillars/get_legacy_pillars_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/pillars/pillars_deploy_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/pillars/pillars_deposit_qsr_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/pillars/pillars_qsr_info_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/pillars/pillars_withdraw_qsr_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/swap/read_wallet_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/model/pillars_qsr_info.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/utils/extensions.dart';
import 'package:zenon_syrius_wallet_flutter/utils/format_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:zenon_syrius_wallet_flutter/utils/input_validators.dart';
import 'package:zenon_syrius_wallet_flutter/utils/navigation_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/notification_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/zts_utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/available_balance.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/buttons/loading_button.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/buttons/stepper_button.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/chart/standard_pie_chart.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/custom_material_stepper.dart'
    as custom_material_stepper;
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/custom_slider.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/dotted_border_info_widget.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/error_widget.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/icons/standard_tooltip_icon.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/input_field/disabled_address_field.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/input_field/input_field.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/input_field/password_input_field.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/loading_widget.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/plasma_icon.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/select_file_widget.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/stepper_utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';
import 'package:znn_swap_utility/znn_swap_utility.dart';

enum PillarType {
  regularPillar,
  legacyPillar,
}

enum PillarsStepperStep {
  checkPlasma,
  selectPillarType,
  checkForLegacyPillar,
  qsrManagement,
  znnManagement,
  deployPillar,
}

class PillarsStepperContainer extends StatefulWidget {
  const PillarsStepperContainer({Key? key}) : super(key: key);

  @override
  State createState() {
    return _MainPillarsState();
  }
}

class _MainPillarsState extends State<PillarsStepperContainer> {
  late PillarsStepperStep _currentStep;
  PillarsStepperStep? _lastCompletedStep;

  final int _numSteps = PillarsStepperStep.values.length;

  PillarType? _selectedPillarType = PillarType.regularPillar;

  final TextEditingController _qsrAmountController = TextEditingController();
  final TextEditingController _pillarNameController = TextEditingController();
  final TextEditingController _pillarRewardAddressController =
      TextEditingController();
  final TextEditingController _pillarMomentumController =
      TextEditingController();
  final TextEditingController _znnAmountController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final FocusNode _pillarNameNode = FocusNode();
  final FocusNode _pillarRewardNode = FocusNode();
  final FocusNode _pillarMomentumNode = FocusNode();

  final GlobalKey<FormState> _qsrFormKey = GlobalKey();

  final GlobalKey<LoadingButtonState> _depositQsrButtonKey = GlobalKey();
  final GlobalKey<LoadingButtonState> _withdrawButtonKey = GlobalKey();
  final GlobalKey<LoadingButtonState> _registerButtonKey = GlobalKey();

  num? _maxQsrAmount;

  final List<GlobalKey<FormState>> _pillarFormKeys = List.generate(
    3,
    (index) => GlobalKey(),
  );

  late PillarsQsrInfoBloc _pillarsQsrInfoViewModel;

  String _password = '';
  String _checkForLegacyPillarStepSubtitle = 'Step skipped';
  String? _walletPath;

  final List<SwapFileEntry> _foundLegacyPillarSwapFileEntries = [];
  List<SwapFileEntry> _decryptWalletResults = [];
  SwapFileEntry? _selectedLegacyPillarSwapFileEntry;

  List<SwapLegacyPillarEntry>? _legacyPillars;

  double _momentumRewardPercentageGiven = 0.0;
  double _delegateRewardPercentageGiven = 0.0;

  @override
  void initState() {
    super.initState();
    _znnAmountController.text = pillarRegisterZnnAmount
        .addDecimals(
          znnDecimals,
        )
        .toString();
    _addressController.text = kSelectedAddress!;
    _pillarRewardAddressController.text = kSelectedAddress!;
    sl.get<BalanceBloc>().getBalanceForAllAddresses();
    _iniStepperControllers();
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

  Widget _getQsrManagementStep(BuildContext context, AccountInfo accountInfo) {
    return ViewModelBuilder<PillarsQsrInfoBloc>.reactive(
      onModelReady: (model) {
        _pillarsQsrInfoViewModel = model;
        model.getQsrManagementInfo(
          _selectedPillarType,
          _addressController.text,
        );
        model.stream.listen(
          (event) {
            if (event != null) {
              _maxQsrAmount = math.min<num>(
                accountInfo.getBalanceWithDecimals(
                  kQsrCoin.tokenStandard,
                ),
                math.max<num>(
                  0,
                  event.cost - (event.deposit),
                ),
              );
              setState(() {
                _qsrAmountController.text = _maxQsrAmount.toString();
              });
            }
          },
        );
      },
      builder: (_, model, __) => StreamBuilder<PillarsQsrInfo?>(
        stream: model.stream,
        builder: (_, snapshot) {
          if (snapshot.hasData) {
            return _getQsrManagementStepBody(
              context,
              accountInfo,
              snapshot.data!,
            );
          } else if (snapshot.hasError) {
            return SyriusErrorWidget(snapshot.error!);
          }
          return const Padding(
            padding: EdgeInsets.all(8.0),
            child: SyriusLoadingWidget(),
          );
        },
      ),
      viewModelBuilder: () => PillarsQsrInfoBloc(),
    );
  }

  Row _getQsrManagementStepBody(
    BuildContext context,
    AccountInfo accountInfo,
    PillarsQsrInfo qsrInfo,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: DisabledAddressField(_addressController),
                      ),
                    ],
                  ),
                  const SizedBox(
                    height: 10.0,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AvailableBalance(
                          kQsrCoin,
                          accountInfo,
                        ),
                        Text(
                          '${qsrInfo.cost} ${kQsrCoin.symbol} needed for a Pillar',
                          style:
                              Theme.of(context).inputDecorationTheme.hintStyle,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 10.0,
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Form(
                          key: _qsrFormKey,
                          autovalidateMode: AutovalidateMode.onUserInteraction,
                          child: InputField(
                            inputFormatters:
                                FormatUtils.getAmountTextInputFormatters(
                              _qsrAmountController.text,
                            ),
                            controller: _qsrAmountController,
                            validator: (value) => _qsrAmountValidator(
                              value,
                              qsrInfo,
                            ),
                            suffixIcon: _getAmountSuffix(accountInfo),
                            suffixIconConstraints:
                                const BoxConstraints(maxWidth: 50.0),
                            hintText: 'Amount',
                            onChanged: (value) {
                              setState(() {});
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 25.0),
                    child: DottedBorderInfoWidget(
                      text:
                          'All the deposited ${kQsrCoin.symbol} will be burned '
                          'in order to create the Pillar Slot',
                      borderColor: AppColors.qsrColor,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Visibility(
                    visible: qsrInfo.deposit < qsrInfo.cost,
                    child: _getDepositQsrViewModel(qsrInfo),
                  ),
                  Visibility(
                    visible: qsrInfo.deposit >= qsrInfo.cost,
                    child: StepperButton(
                      text: 'Next',
                      onPressed: _onQsrNextPressed,
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
        const SizedBox(
          width: 45.0,
        ),
        Expanded(
          child: Visibility(
            visible: qsrInfo.deposit > 0,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).backgroundColor,
                borderRadius: BorderRadius.circular(6),
              ),
              margin: const EdgeInsets.only(
                bottom: 30.0,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 30.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 150.0,
                              height: 150.0,
                              child: AspectRatio(
                                aspectRatio: 1.0,
                                child: StandardPieChart(
                                  sections: [
                                    PieChartSectionData(
                                      showTitle: false,
                                      radius: 7.0,
                                      value: (qsrInfo.cost - qsrInfo.deposit) /
                                          qsrInfo.cost,
                                      color:
                                          AppColors.qsrColor.withOpacity(0.3),
                                    ),
                                    PieChartSectionData(
                                      showTitle: false,
                                      radius: 7.0,
                                      value: qsrInfo.deposit / qsrInfo.cost,
                                      color: AppColors.qsrColor,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Text(
                              'Current Pillar Slot fee\n${qsrInfo.cost} '
                              '${kQsrCoin.symbol}',
                              style: Theme.of(context).textTheme.bodyText2,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                        kVerticalSpacing,
                      ],
                    ),
                    Column(
                      children: [
                        SizedBox(
                          width: 130.0,
                          child: Text(
                            'You have deposited ${qsrInfo.deposit} '
                            '${kQsrCoin.symbol}',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyText1,
                          ),
                        ),
                        kVerticalSpacing,
                        _getWithdrawQsrButtonViewModel(
                          qsrInfo.deposit,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _getDepositQsrViewModel(PillarsQsrInfo qsrInfo) {
    return ViewModelBuilder<PillarsDepositQsrBloc>.reactive(
      onModelReady: (model) {
        model.stream.listen(
          (response) {
            if (response != null) {
              _depositQsrButtonKey.currentState?.animateReverse();
              _pillarsQsrInfoViewModel.getQsrManagementInfo(
                _selectedPillarType,
                _addressController.text,
              );
              setState(() {});
            } else {
              setState(() {});
            }
          },
          onError: (error) {
            _depositQsrButtonKey.currentState?.animateReverse();
            NotificationUtils.sendNotificationError(
              error,
              'Error while depositing ${kQsrCoin.symbol}',
            );
            setState(() {});
          },
        );
      },
      builder: (_, model, __) => _getDepositQsrButton(model, qsrInfo),
      viewModelBuilder: () => PillarsDepositQsrBloc(),
    );
  }

  Widget _getDepositQsrButton(
    PillarsDepositQsrBloc model,
    PillarsQsrInfo qsrInfo,
  ) {
    return LoadingButton.stepper(
      key: _depositQsrButtonKey,
      text: 'Deposit',
      onPressed: _qsrAmountValidator(_qsrAmountController.text, qsrInfo) == null
          ? () => _onDepositButtonPressed(model, qsrInfo)
          : null,
    );
  }

  Widget _getWithdrawQsrButtonViewModel(
    num qsrDeposit,
  ) {
    return ViewModelBuilder<PillarsWithdrawQsrBloc>.reactive(
      onModelReady: (model) {
        model.stream.listen(
          (event) {
            if (event != null) {
              _withdrawButtonKey.currentState?.animateReverse();
              _saveProgressAndNavigateToNextStep(
                PillarsStepperStep.checkPlasma,
              );
              _pillarsQsrInfoViewModel.getQsrManagementInfo(
                _selectedPillarType,
                _addressController.text,
              );
            }
          },
          onError: (error) {
            _withdrawButtonKey.currentState?.animateReverse();
            NotificationUtils.sendNotificationError(
              error,
              'Error while withdrawing ${kQsrCoin.symbol}',
            );
          },
        );
      },
      builder: (_, model, __) => _getWithdrawQsrButton(model, qsrDeposit),
      viewModelBuilder: () => PillarsWithdrawQsrBloc(),
    );
  }

  Widget _getWithdrawQsrButton(
    PillarsWithdrawQsrBloc model,
    num qsrDeposit,
  ) {
    return Visibility(
      visible: qsrDeposit > 0,
      child: LoadingButton.stepper(
        text: 'Withdraw',
        onPressed: () => _onWithdrawButtonPressed(model, qsrDeposit.toDouble()),
        key: _withdrawButtonKey,
      ),
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
            stepTitle: 'Plasma check',
            stepContent: _getPlasmaCheckFutureBuilder(),
            stepSubtitle: 'Sufficient Plasma',
            stepState: StepperUtils.getStepState(
              PillarsStepperStep.checkPlasma.index,
              _lastCompletedStep?.index,
            ),
            context: context,
          ),
          StepperUtils.getMaterialStep(
            stepTitle: 'Pillar type',
            stepContent: _getPillarTypeStepBody(),
            stepSubtitle: _getPillarTypeStepSubtitle(),
            stepState: StepperUtils.getStepState(
              PillarsStepperStep.selectPillarType.index,
              _lastCompletedStep?.index,
            ),
            context: context,
          ),
          StepperUtils.getMaterialStep(
            stepTitle: 'Check for Legacy Pillar',
            stepContent: _getCheckForLegacyPillarStepBody(),
            stepSubtitle: _checkForLegacyPillarStepSubtitle,
            stepState: StepperUtils.getStepState(
              PillarsStepperStep.checkForLegacyPillar.index,
              _lastCompletedStep?.index,
            ),
            context: context,
            expanded: true,
          ),
          StepperUtils.getMaterialStep(
            stepTitle: '${kQsrCoin.symbol} management',
            stepContent: _getQsrManagementStep(context, accountInfo),
            stepSubtitle: '${kQsrCoin.symbol} Deposited',
            stepState: StepperUtils.getStepState(
              PillarsStepperStep.qsrManagement.index,
              _lastCompletedStep?.index,
            ),
            context: context,
            expanded: true,
          ),
          StepperUtils.getMaterialStep(
            stepTitle: '${kZnnCoin.symbol} management',
            stepContent: _getZnnManagementStepBody(context, accountInfo),
            stepSubtitle: '${kZnnCoin.symbol} locked',
            stepState: StepperUtils.getStepState(
              PillarsStepperStep.znnManagement.index,
              _lastCompletedStep?.index,
            ),
            context: context,
          ),
          StepperUtils.getMaterialStep(
            stepTitle: 'Register Pillar',
            stepContent: _getDeployPillarStepBody(context),
            stepSubtitle: 'Pillar registered',
            stepState: StepperUtils.getStepState(
              PillarsStepperStep.deployPillar.index,
              _lastCompletedStep?.index,
            ),
            context: context,
          ),
        ],
      ),
    );
  }

  String _getPillarTypeStepSubtitle() {
    switch (_selectedPillarType) {
      case PillarType.legacyPillar:
        return 'Legacy Pillar';
      case PillarType.regularPillar:
        return 'Pillar';
      default:
        return 'No Pillar type selected';
    }
  }

  Widget _getAmountSuffix(AccountInfo accountInfo) {
    return Row(
      children: [
        Container(
          height: 20.0,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(3),
            color: AppColors.qsrColor,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 3.0,
              horizontal: 7.0,
            ),
            child: Row(
              children: [
                Text(
                  kQsrCoin.symbol,
                  style: Theme.of(context).textTheme.subtitle2!.copyWith(
                        color: Colors.white,
                      ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _getDeployPillarStepBody(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 25.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Form(
                  key: _pillarFormKeys[0],
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: InputField(
                    hintText: 'Pillar name',
                    controller: _pillarNameController,
                    thisNode: _pillarNameNode,
                    nextNode: _pillarRewardNode,
                    validator: (value) => Validations.pillarName(
                      value,
                    ),
                    onChanged: (value) {
                      setState(() {});
                    },
                  ),
                ),
              ),
              const SizedBox(
                width: 23.0,
              )
            ],
          ),
          kVerticalSpacing,
          Row(
            children: [
              Expanded(
                child: Form(
                  key: _pillarFormKeys[1],
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: InputField(
                    hintText: 'Pillar reward address',
                    controller: _pillarRewardAddressController,
                    thisNode: _pillarRewardNode,
                    nextNode: _pillarMomentumNode,
                    validator: InputValidators.checkAddress,
                    onChanged: (value) {
                      setState(() {});
                    },
                  ),
                ),
              ),
              const StandardTooltipIcon(
                'The address that will be able to collect the Pillar rewards',
              ),
            ],
          ),
          kVerticalSpacing,
          Row(
            children: [
              Expanded(
                child: Form(
                  key: _pillarFormKeys[2],
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: InputField(
                    hintText: 'Pillar producer address',
                    controller: _pillarMomentumController,
                    thisNode: _pillarMomentumNode,
                    validator: (value) =>
                        InputValidators.validatePillarMomentumAddress(value),
                    onChanged: (value) {
                      setState(() {});
                    },
                  ),
                ),
              ),
              const StandardTooltipIcon(
                'The address that will produce momentums, get it from znn-controller',
              ),
            ],
          ),
          kVerticalSpacing,
          _getPillarMomentumRewardsStepContent(),
          const SizedBox(
            height: 25.0,
          ),
          _getDeployButton(),
        ],
      ),
    );
  }

  Widget _getDeployButton() {
    return ViewModelBuilder<PillarsDeployBloc>.reactive(
      onModelReady: (model) {
        model.stream.listen(
          (response) {
            if (response != null) {
              _registerButtonKey.currentState?.animateReverse();
              _saveProgressAndNavigateToNextStep(
                PillarsStepperStep.deployPillar,
              );
              setState(() {});
            } else {
              setState(() {});
            }
          },
          onError: (error) {
            _registerButtonKey.currentState?.animateReverse();
            NotificationUtils.sendNotificationError(
                error, 'Error while deploying a Pillar');
            setState(() {});
          },
        );
      },
      builder: (_, model, __) => _getRegisterPillarButton(model),
      viewModelBuilder: () => PillarsDeployBloc(),
    );
  }

  Widget _getRegisterPillarButton(PillarsDeployBloc model) {
    return LoadingButton.stepper(
      text: 'Register',
      onPressed: _canDeployPillar() ? () => _onDeployPressed(model) : null,
      key: _registerButtonKey,
    );
  }

  Widget _getZnnManagementStepBody(
    BuildContext context,
    AccountInfo accountInfo,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: DisabledAddressField(_addressController),
            ),
          ],
        ),
        StepperUtils.getBalanceWidget(kZnnCoin, accountInfo),
        Row(
          children: [
            Expanded(
              child: InputField(
                enabled: false,
                controller: _znnAmountController,
                validator: InputValidators.validateNumber,
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 25.0),
          child: DottedBorderInfoWidget(
            text: 'You will be able to unlock the ${kZnnCoin.symbol} if you '
                'choose to disassemble the Pillar',
            borderColor: AppColors.znnColor,
          ),
        ),
        StepperButton(
          text: 'Next',
          onPressed: _hasEnoughZnn(accountInfo) ? _onNextPressed : null,
        ),
      ],
    );
  }

  void _onDepositButtonPressed(
    PillarsDepositQsrBloc model,
    PillarsQsrInfo qsrInfo,
  ) {
    if (_lastCompletedStep == PillarsStepperStep.checkForLegacyPillar) {
      if (qsrInfo.deposit >= qsrInfo.cost) {
        _depositQsrButtonKey.currentState?.animateForward();
        model.depositQsr(
          _qsrAmountController.text,
          justMarkStepCompleted: true,
        );
      } else if (qsrInfo.deposit + _maxQsrAmount! <= qsrInfo.cost &&
          _qsrFormKey.currentState!.validate() &&
          _qsrAmountController.text.toNum() > 0) {
        _depositQsrButtonKey.currentState?.animateForward();
        model.depositQsr(_qsrAmountController.text);
      }
    }
  }

  void _onNextPressed() {
    if (_lastCompletedStep == PillarsStepperStep.qsrManagement) {
      _saveProgressAndNavigateToNextStep(PillarsStepperStep.znnManagement);
    } else if (StepperUtils.getStepState(
          PillarsStepperStep.qsrManagement.index,
          _lastCompletedStep?.index,
        ) ==
        custom_material_stepper.StepState.complete) {
      setState(() {
        _currentStep = PillarsStepperStep.values[_currentStep.index + 1];
      });
    }
  }

  void _onDeployPressed(PillarsDeployBloc model) {
    if (_lastCompletedStep == PillarsStepperStep.znnManagement) {
      if (_pillarFormKeys
          .every((element) => element.currentState!.validate())) {
        _registerButtonKey.currentState?.animateForward();
        model.deployPillar(
          pillarType: _selectedPillarType!,
          pillarName: _pillarNameController.text,
          rewardAddress: _pillarRewardAddressController.text,
          blockProducingAddress: _pillarMomentumController.text,
          giveBlockRewardPercentage: _momentumRewardPercentageGiven.toInt(),
          giveDelegateRewardPercentage: _delegateRewardPercentageGiven.toInt(),
          signature: _selectedLegacyPillarSwapFileEntry?.signLegacyPillar(
            _password,
            _addressController.text,
          ),
          publicKey: _selectedLegacyPillarSwapFileEntry?.pubKeyB64,
        );
      } else {
        for (var element in _pillarFormKeys) {
          element.currentState!.validate();
        }
      }
    }
  }

  void _onWithdrawButtonPressed(
    PillarsWithdrawQsrBloc viewModel,
    double qsrDeposit,
  ) {
    if (qsrDeposit > 0) {
      _withdrawButtonKey.currentState?.animateForward();
      viewModel.withdrawQsr(_addressController.text);
    }
  }

  Widget _getWidgetBody(BuildContext context, AccountInfo accountInfo) {
    return Stack(
      children: [
        ListView(
          children: [
            _getMaterialStepper(context, accountInfo),
            Visibility(
              visible: (_lastCompletedStep?.index ?? -1) == _numSteps - 1,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 40.0,
                      horizontal: 50.0,
                    ),
                    margin: const EdgeInsets.symmetric(
                      vertical: 20.0,
                      horizontal: 50.0,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      borderRadius: const BorderRadius.all(
                        Radius.circular(
                          10.0,
                        ),
                      ),
                    ),
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: Theme.of(context).textTheme.headline6,
                        children: [
                          TextSpan(
                            text: 'Pillar ',
                            style: Theme.of(context).textTheme.headline6,
                          ),
                          TextSpan(
                            text: 'successfully',
                            style:
                                Theme.of(context).textTheme.headline6!.copyWith(
                                      color: AppColors.znnColor,
                                    ),
                          ),
                          TextSpan(
                            text: ' registered. Use ',
                            style: Theme.of(context).textTheme.headline6,
                          ),
                          TextSpan(
                            text: 'znn-controller ',
                            style:
                                Theme.of(context).textTheme.headline6!.copyWith(
                                      color: AppColors.znnColor,
                                      decoration: TextDecoration.underline,
                                    ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                NavigationUtils.launchUrl(
                                    kZnnController, context);
                              },
                          ),
                          const WidgetSpan(
                            child: Icon(MaterialCommunityIcons.link,
                                size: 20.0, color: AppColors.znnColor),
                          ),
                          TextSpan(
                            text: ' to check the Pillar status',
                            style: Theme.of(context).textTheme.headline6,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      StepperButton.icon(
                        context: context,
                        label: 'Register another Pillar',
                        onPressed: _onDeployAnotherPillarButtonPressed,
                        iconData: Icons.refresh,
                      ),
                      const SizedBox(
                        width: 80.0,
                      ),
                      _getViewPillarsButton()
                    ],
                  ),
                  Container(height: 20.0)
                ],
              ),
            ),
          ],
        ),
        Visibility(
          visible: (_lastCompletedStep?.index ?? -1) == _numSteps - 1,
          child: Positioned(
            right: 50.0,
            child: SizedBox(
              width: 400.0,
              height: 400.0,
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

  Widget _getViewPillarsButton() {
    return StepperButton.icon(
      context: context,
      label: 'View Pillars',
      onPressed: () {
        Navigator.pop(context);
      },
      iconData: MaterialCommunityIcons.pillar,
    );
  }

  void _onDeployAnotherPillarButtonPressed() async {
    _pillarNameController.clear();
    _pillarRewardAddressController.clear();
    _pillarMomentumController.clear();
    _lastCompletedStep = null;
    _pillarsQsrInfoViewModel.getQsrManagementInfo(
      _selectedPillarType,
      _addressController.text,
    );
    setState(() {
      _iniStepperControllers();
    });
  }

  Widget _getPillarTypeStepBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Please choose the type of Pillar you want to register',
              style: Theme.of(context).textTheme.headline6,
            ),
          ],
        ),
        _getPillarTypeListTile('Pillar', PillarType.regularPillar),
        _getPillarTypeListTile('Legacy Pillar', PillarType.legacyPillar),
        _getContinueButton(),
      ],
    );
  }

  Widget _getContinueButton() {
    return StepperButton(
      onPressed: _selectedPillarType != null
          ? () => _onPillarTypeContinuePressed()
          : null,
      text: 'Continue',
    );
  }

  Widget _getPillarTypeListTile(String text, PillarType value) {
    return ListTile(
      title: Text(
        text,
        style: Theme.of(context).textTheme.bodyText1,
      ),
      leading: Radio(
        activeColor: AppColors.znnColor,
        value: value,
        groupValue: _selectedPillarType,
        onChanged: (PillarType? value) {
          setState(() {
            _selectedPillarType = value;
            _pillarsQsrInfoViewModel.getQsrManagementInfo(
                _selectedPillarType, _addressController.text);
          });
        },
      ),
    );
  }

  void _onPillarTypeContinuePressed() {
    _saveProgressAndNavigateToNextStep(
      _selectedPillarType == PillarType.legacyPillar
          ? PillarsStepperStep.selectPillarType
          : PillarsStepperStep.checkForLegacyPillar,
    );
  }

  void _saveProgressAndNavigateToNextStep(PillarsStepperStep completedStep) {
    setState(() {
      _lastCompletedStep = completedStep;
      if (_lastCompletedStep!.index + 1 < _numSteps) {
        _currentStep = PillarsStepperStep.values[completedStep.index + 1];
      }
    });
  }

  void _iniStepperControllers() {
    _currentStep = PillarsStepperStep.values.first;
    _selectedPillarType = PillarType.values.first;
  }

  bool _hasEnoughZnn(AccountInfo accountInfo) =>
      accountInfo.getBalanceWithDecimals(
        kZnnCoin.tokenStandard,
      ) >=
      pillarRegisterZnnAmount.addDecimals(
        znnDecimals,
      );

  bool _canDeployPillar() =>
      InputValidators.notEmpty(
            'Pillar name',
            _pillarNameController.text,
          ) ==
          null &&
      InputValidators.notEmpty(
            'Pillar reward address',
            _pillarRewardAddressController.text,
          ) ==
          null &&
      InputValidators.notEmpty(
            'Pillar momentum address',
            _pillarMomentumController.text,
          ) ==
          null;

  String? _qsrAmountValidator(String? value, PillarsQsrInfo qsrInfo) =>
      InputValidators.correctValue(
        value,
        _maxQsrAmount,
        kQsrCoin.decimals,
        min: 1.0,
        canBeEqualToMin: true,
      );

  void _onQsrNextPressed() {
    if (_lastCompletedStep == PillarsStepperStep.checkForLegacyPillar) {
      _saveProgressAndNavigateToNextStep(PillarsStepperStep.qsrManagement);
    } else if (StepperUtils.getStepState(
          PillarsStepperStep.qsrManagement.index,
          _lastCompletedStep?.index,
        ) ==
        custom_material_stepper.StepState.complete) {
      setState(() {
        _currentStep = PillarsStepperStep.values[_currentStep.index + 1];
      });
    }
  }

  Widget _getPlasmaCheckFutureBuilder() {
    return FutureBuilder<PlasmaInfo?>(
      future: zenon!.embedded.plasma.get(Address.parse(kSelectedAddress!)),
      builder: (_, snapshot) {
        if (snapshot.hasError) {
          return SyriusErrorWidget(snapshot.error!);
        } else if (snapshot.hasData) {
          return _getPlasmaCheckBody(snapshot.data!);
        }
        return const Padding(
          padding: EdgeInsets.all(8.0),
          child: SyriusLoadingWidget(),
        );
      },
    );
  }

  Widget _getPlasmaCheckBody(PlasmaInfo plasmaInfo) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: DisabledAddressField(_addressController),
            ),
            const SizedBox(
              width: 25.0,
            ),
            PlasmaIcon(plasmaInfo),
          ],
        ),
        const SizedBox(
          height: 25.0,
        ),
        StepperButton(
          text: 'Next',
          onPressed: plasmaInfo.currentPlasma >= kPillarPlasmaAmountNeeded
              ? _onPlasmaCheckNextPressed
              : null,
        ),
      ],
    );
  }

  void _onPlasmaCheckNextPressed() {
    if (_lastCompletedStep == null) {
      _saveProgressAndNavigateToNextStep(PillarsStepperStep.checkPlasma);
    } else if (StepperUtils.getStepState(
          PillarsStepperStep.checkPlasma.index,
          _lastCompletedStep?.index,
        ) ==
        custom_material_stepper.StepState.complete) {
      setState(() {
        _currentStep = PillarsStepperStep.values[_currentStep.index + 1];
      });
    }
  }

  Widget _getCheckForLegacyPillarStepBody() {
    return ViewModelBuilder<GetLegacyPillarsBloc>.reactive(
      onModelReady: (model) {
        model.checkForLegacyPillar();
      },
      builder: (_, model, __) => StreamBuilder<List<SwapLegacyPillarEntry>?>(
        stream: model.stream,
        builder: (_, snapshot) {
          if (snapshot.hasError) {
            return SyriusErrorWidget(snapshot.error!);
          }
          if (snapshot.connectionState == ConnectionState.active) {
            if (snapshot.hasData) {
              _legacyPillars = snapshot.data;
              return _getDecryptWalletFileBody();
            }
            return const SyriusLoadingWidget();
          }
          return const SyriusLoadingWidget();
        },
      ),
      viewModelBuilder: () => GetLegacyPillarsBloc(),
    );
  }

  Widget _getImportWalletWidget() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Please choose the ".dat" wallet file to discover legacy Pillar entries',
          style: Theme.of(context).textTheme.headline6,
        ),
        const SizedBox(
          height: 25.0,
        ),
        SelectFileWidget(
          fileExtension: 'dat',
          onPathFoundCallback: (String path) {
            setState(() {
              _walletPath = path;
            });
          },
        ),
      ],
    );
  }

  Widget _getDecryptWalletFileBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _getImportWalletWidget(),
        Visibility(
          visible: _walletPath != null,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              kVerticalSpacing,
              _getWalletPasswordInputField(),
              kVerticalSpacing,
              Visibility(
                visible: _decryptWalletResults.isEmpty,
                child: _getDecryptWalletFileViewModel(),
              ),
              Visibility(
                visible: _foundLegacyPillarSwapFileEntries.isNotEmpty,
                child: Column(
                  children: <Widget>[
                        Row(
                          children: [
                            Text(
                              'Please choose the Legacy Pillar',
                              style: Theme.of(context).textTheme.headline6,
                            ),
                          ],
                        )
                      ] +
                      _foundLegacyPillarSwapFileEntries
                          .map((e) => _getLegacyPillarListTile(e.address, e))
                          .toList()
                          .cast<Widget>(),
                ),
              ),
              Visibility(
                visible: _foundLegacyPillarSwapFileEntries.isNotEmpty &&
                    _selectedLegacyPillarSwapFileEntry != null,
                child: StepperButton(
                  text: 'Next',
                  onPressed: () {
                    _saveProgressAndNavigateToNextStep(
                      PillarsStepperStep.checkForLegacyPillar,
                    );
                  },
                ),
              ),
              Visibility(
                visible: _foundLegacyPillarSwapFileEntries.isEmpty &&
                    _decryptWalletResults.isNotEmpty,
                child: Text(
                  'No Legacy Pillar found',
                  style: Theme.of(context).textTheme.headline6,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _getWalletPasswordInputField() {
    return Material(
      color: Colors.transparent,
      child: PasswordInputField(
        hintText: 'Wallet password',
        controller: _passwordController,
        onChanged: (value) {
          setState(() {
            _password = value;
          });
        },
      ),
    );
  }

  Widget _getDecryptWalletFileViewModel() {
    return ViewModelBuilder<ReadWalletBloc>.reactive(
      onModelReady: (model) {
        model.stream.listen(
          (results) {
            if (results != null) {
              _decryptWalletResults = results;
              _findLegacyPillar(
                _decryptWalletResults,
                _legacyPillars!,
              );
              if (_foundLegacyPillarSwapFileEntries.isEmpty) {
                _checkForLegacyPillarStepSubtitle =
                    'No Legacy Pillar available';
              } else {
                _checkForLegacyPillarStepSubtitle = 'Legacy Pillar available';
              }
              setState(() {});
            }
          },
          onError: (error) {
            NotificationUtils.sendNotificationError(error, error.toString());
          },
        );
      },
      builder: (_, model, __) => StreamBuilder<List<SwapFileEntry>?>(
        stream: model.stream,
        builder: (_, snapshot) {
          if (snapshot.hasError) {
            return _getDecryptButton(model);
          }
          if (snapshot.connectionState == ConnectionState.active) {
            if (snapshot.hasData) {
              return _getDecryptButton(model);
            }
            return const SyriusLoadingWidget();
          }
          return _getDecryptButton(model);
        },
      ),
      viewModelBuilder: () => ReadWalletBloc(),
    );
  }

  Widget _getDecryptButton(ReadWalletBloc model) {
    return StepperButton(
      onPressed: _password.isNotEmpty
          ? () {
              model.readWallet(_walletPath!, _password);
            }
          : null,
      text: 'Decrypt',
    );
  }

  void _findLegacyPillar(
    List<SwapFileEntry> decryptWalletResults,
    List<SwapLegacyPillarEntry> legacyPillars,
  ) {
    for (SwapFileEntry decryptWalletResult in decryptWalletResults) {
      for (SwapLegacyPillarEntry legacyPillar in legacyPillars) {
        if (legacyPillar.keyIdHash.toString() ==
            decryptWalletResult.keyIdHashHex) {
          _foundLegacyPillarSwapFileEntries.add(decryptWalletResult);
        }
      }
    }
  }

  Widget _getLegacyPillarListTile(String text, SwapFileEntry value) {
    return ListTile(
      title: Text(
        text,
        style: Theme.of(context).textTheme.bodyText1,
      ),
      leading: Radio(
        activeColor: AppColors.znnColor,
        value: value,
        groupValue: _selectedLegacyPillarSwapFileEntry,
        onChanged: (SwapFileEntry? value) {
          setState(() {
            _selectedLegacyPillarSwapFileEntry = value;
          });
        },
      ),
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
          startValue: 0.0,
          min: 0,
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
          startValue: 0.0,
          min: 0,
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
      ],
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
    _passwordController.dispose();
    _pillarNameNode.dispose();
    _pillarRewardNode.dispose();
    _pillarMomentumNode.dispose;
    super.dispose();
  }
}
