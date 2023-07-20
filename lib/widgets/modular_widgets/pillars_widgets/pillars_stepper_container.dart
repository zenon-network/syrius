import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:lottie/lottie.dart';
import 'package:stacked/stacked.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/utils/extensions.dart';
import 'package:zenon_syrius_wallet_flutter/utils/format_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:zenon_syrius_wallet_flutter/utils/input_validators.dart';
import 'package:zenon_syrius_wallet_flutter/utils/math_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/navigation_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/notification_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/zts_utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/custom_material_stepper.dart'
    as custom_material_stepper;
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

enum PillarType {
  regularPillar,
}

enum PillarsStepperStep {
  checkPlasma,
  selectPillarType,
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

  BigInt _maxQsrAmount = BigInt.zero;

  final List<GlobalKey<FormState>> _pillarFormKeys = List.generate(
    3,
    (index) => GlobalKey(),
  );

  late PillarsQsrInfoBloc _pillarsQsrInfoViewModel;

  double _momentumRewardPercentageGiven = 0.0;
  double _delegateRewardPercentageGiven = 0.0;

  @override
  void initState() {
    super.initState();
    _znnAmountController.text = pillarRegisterZnnAmount.addDecimals(
      coinDecimals,
    );
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
      onViewModelReady: (model) {
        _pillarsQsrInfoViewModel = model;
        model.getQsrManagementInfo(
          _selectedPillarType,
          _addressController.text,
        );
        model.stream.listen(
          (event) {
            if (event != null) {
              _maxQsrAmount = MathUtils.bigMin(
                accountInfo.getBalance(
                  kQsrCoin.tokenStandard,
                ),
                MathUtils.bigMax(BigInt.zero, event.cost - event.deposit),
              );
              setState(() {
                _qsrAmountController.text =
                    _maxQsrAmount.addDecimals(coinDecimals);
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
                          '${qsrInfo.cost.addDecimals(coinDecimals)} ${kQsrCoin.symbol} required for a Pillar slot',
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
            visible: qsrInfo.deposit > BigInt.zero,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.background,
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
                              'Current Pillar Slot fee\n${qsrInfo.cost.addDecimals(coinDecimals)} '
                              '${kQsrCoin.symbol}',
                              style: Theme.of(context).textTheme.bodyMedium,
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
                            'You have deposited ${qsrInfo.deposit.addDecimals(coinDecimals)} '
                            '${kQsrCoin.symbol}',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyLarge,
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
      onViewModelReady: (model) {
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
      outlineColor: AppColors.qsrColor,
    );
  }

  Widget _getWithdrawQsrButtonViewModel(
    BigInt qsrDeposit,
  ) {
    return ViewModelBuilder<PillarsWithdrawQsrBloc>.reactive(
      onViewModelReady: (model) {
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
    BigInt qsrDeposit,
  ) {
    return Visibility(
      visible: qsrDeposit > BigInt.zero,
      child: LoadingButton.stepper(
        text: 'Withdraw',
        onPressed: () => _onWithdrawButtonPressed(model, qsrDeposit),
        key: _withdrawButtonKey,
        outlineColor: AppColors.qsrColor,
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
            stepTitle: 'Pillar deployment: Plasma check',
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
                  style: Theme.of(context).textTheme.titleSmall!.copyWith(
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
                Icons.help,
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
                Icons.help,
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
      onViewModelReady: (model) {
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
                validator: InputValidators.validateAmount,
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
    if (qsrInfo.deposit >= qsrInfo.cost) {
      _depositQsrButtonKey.currentState?.animateForward();
      model.depositQsr(
        _qsrAmountController.text.extractDecimals(coinDecimals),
        justMarkStepCompleted: true,
      );
    } else if (qsrInfo.deposit + _maxQsrAmount <= qsrInfo.cost &&
        _qsrFormKey.currentState!.validate() &&
        _qsrAmountController.text.extractDecimals(coinDecimals) > BigInt.zero) {
      _depositQsrButtonKey.currentState?.animateForward();
      model.depositQsr(_qsrAmountController.text.extractDecimals(coinDecimals));
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
    BigInt qsrDeposit,
  ) {
    if (qsrDeposit > BigInt.zero) {
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
                        style: Theme.of(context).textTheme.headlineSmall,
                        children: [
                          TextSpan(
                            text: 'Pillar ',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          TextSpan(
                            text: 'successfully',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall!
                                .copyWith(
                                  color: AppColors.znnColor,
                                ),
                          ),
                          TextSpan(
                            text: ' registered. Use ',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          TextSpan(
                            text: 'znn-controller ',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall!
                                .copyWith(
                                  color: AppColors.znnColor,
                                  decoration: TextDecoration.underline,
                                ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                NavigationUtils.openUrl(kZnnController);
                              },
                          ),
                          const WidgetSpan(
                            child: Icon(MaterialCommunityIcons.link,
                                size: 20.0, color: AppColors.znnColor),
                          ),
                          TextSpan(
                            text: ' to check the Pillar status',
                            style: Theme.of(context).textTheme.headlineSmall,
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
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ],
        ),
        _getPillarTypeListTile('Pillar', PillarType.regularPillar),
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
        style: Theme.of(context).textTheme.bodyLarge,
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
    _saveProgressAndNavigateToNextStep(PillarsStepperStep.selectPillarType);
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
      accountInfo.znn()! >= pillarRegisterZnnAmount;

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
        BigInt.one,
        canBeEqualToMin: true,
      );

  void _onQsrNextPressed() {
    setState(() {
      _saveProgressAndNavigateToNextStep(PillarsStepperStep.qsrManagement);
    });
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
        Text(
          'More Plasma is required to perform complex transactions. Please fuse enough QSR before proceeding.',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(
          height: 25.0,
        ),
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

  Widget _getPillarMomentumRewardsStepContent() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Percentage of momentum rewards given to the delegators',
              style: Theme.of(context).textTheme.headlineSmall,
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
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              'Delegators: ${_momentumRewardPercentageGiven.toInt()}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
        kVerticalSpacing,
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Percentage of delegation rewards given to the delegators',
              style: Theme.of(context).textTheme.headlineSmall,
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
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text(
              'Delegators: ${_delegateRewardPercentageGiven.toInt()}',
              style: Theme.of(context).textTheme.titleMedium,
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
