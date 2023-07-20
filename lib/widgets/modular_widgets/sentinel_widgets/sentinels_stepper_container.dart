import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:lottie/lottie.dart';
import 'package:stacked/stacked.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
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

enum SentinelsStepperStep {
  checkPlasma,
  qsrManagement,
  znnManagement,
  deploySentinel,
}

class SentinelsStepperContainer extends StatefulWidget {
  const SentinelsStepperContainer({Key? key}) : super(key: key);

  @override
  State createState() {
    return _MainSentinelsState();
  }
}

class _MainSentinelsState extends State<SentinelsStepperContainer> {
  late SentinelsStepperStep _currentStep;
  SentinelsStepperStep? _lastCompletedStep;

  final TextEditingController _qsrAmountController = TextEditingController();
  final TextEditingController _znnAmountController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  final GlobalKey<LoadingButtonState> _depositQsrButtonKey = GlobalKey();
  final GlobalKey<LoadingButtonState> _withdrawButtonKey = GlobalKey();
  final GlobalKey<LoadingButtonState> _registerButtonKey = GlobalKey();
  final GlobalKey<FormState> _qsrFormKey = GlobalKey();

  BigInt _withdrawnQSR = BigInt.zero;
  BigInt _maxQsrAmount = BigInt.zero;
  BigInt _qsrCost = BigInt.zero;

  final int _numSteps = SentinelsStepperStep.values.length;

  late SentinelsQsrInfoBloc _sentinelsQsrInfoViewModel;

  @override
  void initState() {
    super.initState();
    _qsrCost = sentinelRegisterQsrAmount;
    _qsrAmountController.text = _qsrCost.addDecimals(coinDecimals);
    _znnAmountController.text = sentinelRegisterZnnAmount.addDecimals(
      coinDecimals,
    );
    _addressController.text = kSelectedAddress!;
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
              snapshot.data![_addressController.text],
            );
          }
          return const SyriusLoadingWidget();
        }
        return const SyriusLoadingWidget();
      },
    );
  }

  Widget _getDepositQsrStep(BuildContext context, AccountInfo? accountInfo) {
    return ViewModelBuilder<SentinelsQsrInfoBloc>.reactive(
      onViewModelReady: (model) {
        _sentinelsQsrInfoViewModel = model;
        model.getQsrDepositedAmount(_addressController.text);
      },
      builder: (_, model, __) => StreamBuilder<BigInt?>(
        stream: model.stream,
        builder: (_, snapshot) {
          if (snapshot.hasData) {
            return _getDepositQsrStepBody(
              context,
              accountInfo!,
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
      viewModelBuilder: () => SentinelsQsrInfoBloc(),
    );
  }

  Widget _getDepositQsrStepBody(
    BuildContext context,
    AccountInfo accountInfo,
    BigInt depositedQsr,
  ) {
    _maxQsrAmount = MathUtils.bigMin(
        accountInfo.getBalance(kQsrCoin.tokenStandard),
        MathUtils.bigMax(
            BigInt.zero, _qsrCost - (depositedQsr - _withdrawnQSR)));

    return Column(
      children: [
        Visibility(
          visible: depositedQsr >= _qsrCost,
          child: Container(
            margin: const EdgeInsets.only(
              bottom: 30.0,
            ),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.background,
              borderRadius: BorderRadius.circular(6.0),
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
                            height: 150.0,
                            width: 150.0,
                            child: StandardPieChart(
                              sections: [
                                PieChartSectionData(
                                  showTitle: false,
                                  radius: 7.0,
                                  value: (_qsrCost
                                          .addDecimals(coinDecimals)
                                          .toNum() -
                                      (depositedQsr - _withdrawnQSR) /
                                          _qsrCost),
                                  color: AppColors.qsrColor.withOpacity(0.3),
                                ),
                                PieChartSectionData(
                                  showTitle: false,
                                  radius: 7.0,
                                  value: _qsrCost / _qsrCost,
                                  color: AppColors.qsrColor,
                                ),
                              ],
                            ),
                          ),
                          Text(
                            'Sentinel Slot value\n${_qsrCost.addDecimals(coinDecimals)} ${kQsrCoin.symbol}',
                            style: Theme.of(context).textTheme.bodyMedium,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                      kVerticalSpacing,
                      Visibility(
                        visible: false,
                        child: Row(
                          children: [
                            Container(
                              width: 5.0,
                              height: 5.0,
                              margin: const EdgeInsets.only(right: 5.0),
                              decoration: const BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.qsrColor,
                              ),
                            ),
                            Text(
                              'Deposited ${kQsrCoin.symbol}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge!
                                  .copyWith(
                                    fontSize: 10.0,
                                  ),
                            ),
                            Container(
                              width: 5.0,
                              height: 5.0,
                              margin: const EdgeInsets.only(
                                left: 10.0,
                                right: 5.0,
                              ),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.qsrColor.withOpacity(0.3),
                              ),
                            ),
                            Text(
                              'Remaining ${kQsrCoin.symbol}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge!
                                  .copyWith(
                                    fontSize: 10.0,
                                  ),
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                  Column(
                    children: [
                      SizedBox(
                        width: 130.0,
                        child: Text(
                          'You have deposited ${depositedQsr.addDecimals(coinDecimals)} ${kQsrCoin.symbol}',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                      kVerticalSpacing,
                      _getWithdrawQsrButtonViewModel(depositedQsr)
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        Visibility(
          visible: depositedQsr < _qsrCost,
          child: Column(
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
              StepperUtils.getBalanceWidget(kQsrCoin, accountInfo),
              Row(
                children: [
                  Expanded(
                    child: Form(
                      key: _qsrFormKey,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      child: InputField(
                        enabled: false,
                        onChanged: (value) {
                          setState(() {});
                        },
                        inputFormatters:
                            FormatUtils.getAmountTextInputFormatters(
                          _qsrAmountController.text,
                        ),
                        controller: _qsrAmountController,
                        validator: _qsrAmountValidator,
                        suffixIcon: _getAmountSuffix(accountInfo),
                        suffixIconConstraints: const BoxConstraints(
                          maxWidth: 50.0,
                        ),
                        hintText: 'Amount',
                      ),
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 25.0),
                child: DottedBorderInfoWidget(
                  text:
                      'You will be able to unlock the ${kQsrCoin.symbol} if you '
                      'choose to disassemble the Sentinel',
                  borderColor: AppColors.qsrColor,
                ),
              ),
            ],
          ),
        ),
        Row(
          children: [
            Visibility(
              visible: depositedQsr < _qsrCost,
              child: _getDepositButtonViewModel(accountInfo, depositedQsr),
            ),
            Visibility(
              visible: depositedQsr >= _qsrCost,
              child: StepperButton(
                text: 'Next',
                onPressed: _onQsrNextPressed,
              ),
            ),
          ],
        )
      ],
    );
  }

  String? _qsrAmountValidator(String? value) => InputValidators.correctValue(
        value,
        _maxQsrAmount,
        kQsrCoin.decimals,
        _maxQsrAmount,
        canBeEqualToMin: true,
      );

  Widget _getDepositButtonViewModel(
      AccountInfo accountInfo, BigInt depositedQsr) {
    return ViewModelBuilder<SentinelsDepositQsrBloc>.reactive(
      onViewModelReady: (model) {
        model.stream.listen(
          (response) {
            if (response != null) {
              _depositQsrButtonKey.currentState?.animateReverse();
              _sentinelsQsrInfoViewModel.getQsrDepositedAmount(
                _addressController.text,
              );
            }
          },
          onError: (error) {
            _depositQsrButtonKey.currentState?.animateReverse();
            NotificationUtils.sendNotificationError(
              error,
              'Error while depositing ${kQsrCoin.symbol} for Sentinel',
            );
          },
        );
      },
      builder: (_, model, __) => _getDepositButton(
        model,
        accountInfo,
        depositedQsr,
      ),
      viewModelBuilder: () => SentinelsDepositQsrBloc(),
    );
  }

  Widget _getDepositButton(
    SentinelsDepositQsrBloc model,
    AccountInfo accountInfo,
    BigInt depositedQsr,
  ) {
    return LoadingButton.stepper(
      key: _depositQsrButtonKey,
      text: 'Deposit',
      onPressed: _qsrAmountValidator(_qsrAmountController.text) == null
          ? () => _onDepositButtonPressed(model, depositedQsr)
          : null,
      outlineColor: AppColors.qsrColor,
    );
  }

  Widget _getWithdrawQsrButtonViewModel(BigInt qsrDeposit) {
    return ViewModelBuilder<SentinelsWithdrawQsrBloc>.reactive(
      onViewModelReady: (model) {
        model.stream.listen(
          (event) {
            if (event != null) {
              _withdrawButtonKey.currentState?.animateReverse();
              setState(() {
                _lastCompletedStep = SentinelsStepperStep.checkPlasma;
              });
              _sentinelsQsrInfoViewModel.getQsrDepositedAmount(
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
      builder: (_, model, __) => StreamBuilder<AccountBlockTemplate?>(
        stream: model.stream,
        builder: (_, snapshot) {
          if (snapshot.hasData) {
            _withdrawnQSR = qsrDeposit;
          }
          return _getWithdrawQsrButton(qsrDeposit, model);
        },
      ),
      viewModelBuilder: () => SentinelsWithdrawQsrBloc(),
    );
  }

  Widget _getWithdrawQsrButton(
    BigInt qsrDeposit,
    SentinelsWithdrawQsrBloc model,
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

  Widget _getMaterialStepper(BuildContext context, AccountInfo? accountInfo) {
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
            stepTitle: 'Sentinel deployment: Plasma check',
            stepContent: _getPlasmaCheckFutureBuilder(),
            stepSubtitle: 'Sufficient Plasma',
            stepState: StepperUtils.getStepState(
              SentinelsStepperStep.checkPlasma.index,
              _lastCompletedStep?.index,
            ),
            context: context,
          ),
          StepperUtils.getMaterialStep(
            stepTitle: '${kQsrCoin.symbol} management',
            stepContent: _getDepositQsrStep(context, accountInfo),
            stepSubtitle: '${kQsrCoin.symbol} deposited',
            stepState: StepperUtils.getStepState(
              SentinelsStepperStep.qsrManagement.index,
              _lastCompletedStep?.index,
            ),
            context: context,
          ),
          StepperUtils.getMaterialStep(
            stepTitle: '${kZnnCoin.symbol} management',
            stepContent: _getZnnManagementStepBody(context, accountInfo),
            stepSubtitle: '${kZnnCoin.symbol} locked',
            stepState: StepperUtils.getStepState(
              SentinelsStepperStep.znnManagement.index,
              _lastCompletedStep?.index,
            ),
            context: context,
          ),
          StepperUtils.getMaterialStep(
            stepTitle: 'Register Sentinel',
            stepContent: _getDeploySentinelStepBody(context),
            stepSubtitle: 'Sentinel registered',
            stepState: StepperUtils.getStepState(
              SentinelsStepperStep.deploySentinel.index,
              _lastCompletedStep?.index,
            ),
            context: context,
          ),
        ],
      ),
    );
  }

  Widget _getAmountSuffix(AccountInfo accountInfo) {
    return AmountSuffixTokenSymbolWidget(
      token: kQsrCoin,
      context: context,
    );
  }

  Widget _getDeploySentinelStepBody(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        bottom: 25.0,
      ),
      child: Row(
        children: [
          _getDeployButtonViewModel(),
        ],
      ),
    );
  }

  Widget _getDeployButtonViewModel() {
    return ViewModelBuilder<SentinelsDeployBloc>.reactive(
      onViewModelReady: (model) {
        model.stream.listen(
          (response) {
            if (response != null) {
              _registerButtonKey.currentState?.animateReverse();
              _saveProgressAndNavigateToNextStep(
                  SentinelsStepperStep.deploySentinel);
            }
          },
          onError: (error) {
            _registerButtonKey.currentState?.animateReverse();
            NotificationUtils.sendNotificationError(
              error,
              'Error while deploying the Sentinel Node',
            );
          },
        );
      },
      builder: (_, model, __) => _getDeployButton(model),
      viewModelBuilder: () => SentinelsDeployBloc(),
    );
  }

  Widget _getDeployButton(SentinelsDeployBloc model) {
    return LoadingButton.stepper(
      text: 'Register',
      onPressed: () => _onDeployPressed(model),
      key: _registerButtonKey,
    );
  }

  Widget _getZnnManagementStepBody(
    BuildContext context,
    AccountInfo? accountInfo,
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
        kVerticalSpacing,
        StepperUtils.getBalanceWidget(kZnnCoin, accountInfo!),
        kVerticalSpacing,
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
                'choose to disassemble the Sentinel',
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
      SentinelsDepositQsrBloc model, BigInt depositedQsr) {
    if (_lastCompletedStep == SentinelsStepperStep.checkPlasma) {
      if (depositedQsr >= _qsrCost) {
        _depositQsrButtonKey.currentState?.animateForward();
        model.depositQsr(
          _qsrAmountController.text.extractDecimals(coinDecimals),
          justMarkStepCompleted: true,
        );
      } else if (_maxQsrAmount + depositedQsr >= _qsrCost &&
          _qsrFormKey.currentState!.validate() &&
          _qsrAmountController.text.extractDecimals(coinDecimals) >
              BigInt.zero) {
        _depositQsrButtonKey.currentState?.animateForward();
        model.depositQsr(
            _qsrAmountController.text.extractDecimals(coinDecimals));
      }
    } else if (_lastCompletedStep == SentinelsStepperStep.qsrManagement) {
      setState(() {
        _currentStep = SentinelsStepperStep.values[_currentStep.index + 1];
      });
    }
  }

  void _onNextPressed() {
    if (_lastCompletedStep == SentinelsStepperStep.qsrManagement) {
      _saveProgressAndNavigateToNextStep(SentinelsStepperStep.znnManagement);
    } else if (StepperUtils.getStepState(
          SentinelsStepperStep.qsrManagement.index,
          _lastCompletedStep?.index,
        ) ==
        custom_material_stepper.StepState.complete) {
      setState(() {
        _currentStep = SentinelsStepperStep.values[_currentStep.index + 1];
      });
    }
  }

  void _onDeployPressed(SentinelsDeployBloc model) {
    if (_lastCompletedStep == SentinelsStepperStep.znnManagement) {
      _registerButtonKey.currentState?.animateForward();
      model.deploySentinel(
          _znnAmountController.text.extractDecimals(coinDecimals));
    }
  }

  void _onWithdrawButtonPressed(
    SentinelsWithdrawQsrBloc viewModel,
    BigInt qsrDeposit,
  ) {
    if (qsrDeposit > BigInt.zero) {
      _withdrawButtonKey.currentState?.animateForward();
      viewModel.withdrawQsr(_addressController.text);
    }
  }

  Widget _getWidgetBody(BuildContext context, AccountInfo? accountInfo) {
    return Stack(
      children: [
        ListView(
          children: [
            _getMaterialStepper(context, accountInfo),
            Visibility(
              visible:
                  _lastCompletedStep == SentinelsStepperStep.deploySentinel,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
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
                            text: 'Sentinel ',
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
                            child: Icon(
                              MaterialCommunityIcons.link,
                              size: 20.0,
                              color: AppColors.znnColor,
                            ),
                          ),
                          TextSpan(
                            text: ' to check the Sentinel status',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _getViewSentinelsButton(),
                    ],
                  ),
                  Container(height: 20.0)
                ],
              ),
            ),
          ],
        ),
        Visibility(
          visible: _lastCompletedStep == SentinelsStepperStep.deploySentinel,
          child: Positioned(
            right: 50.0,
            child: SizedBox(
              width: 400.0,
              height: 400.0,
              child: Center(
                child: Lottie.asset(
                  'assets/lottie/ic_anim_sentinel.json',
                  repeat: false,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _getViewSentinelsButton() {
    return StepperButton.icon(
      context: context,
      label: 'View Sentinels',
      onPressed: () {
        Navigator.pop(context);
      },
      iconData: MaterialCommunityIcons.eye_outline,
    );
  }

  void _iniStepperControllers() {
    _currentStep = SentinelsStepperStep.values.first;
  }

  void _saveProgressAndNavigateToNextStep(SentinelsStepperStep completedStep) {
    setState(() {
      _lastCompletedStep = completedStep;
      if (_lastCompletedStep!.index + 1 < _numSteps) {
        _currentStep = SentinelsStepperStep.values[completedStep.index + 1];
      }
    });
  }

  void _onQsrNextPressed() {
    if (_lastCompletedStep == SentinelsStepperStep.checkPlasma) {
      _saveProgressAndNavigateToNextStep(SentinelsStepperStep.qsrManagement);
    } else if (StepperUtils.getStepState(
          SentinelsStepperStep.qsrManagement.index,
          _lastCompletedStep?.index,
        ) ==
        custom_material_stepper.StepState.complete) {
      setState(() {
        _currentStep = SentinelsStepperStep.values[_currentStep.index + 1];
      });
    }
  }

  Widget _getPlasmaCheckFutureBuilder() {
    return FutureBuilder<PlasmaInfo?>(
      future: zenon!.embedded.plasma.get(Address.parse(kSelectedAddress!)),
      builder: (_, snapshot) {
        if (snapshot.hasError) {
          return SyriusErrorWidget(snapshot.error!);
        }
        switch (snapshot.connectionState) {
          case ConnectionState.active:
            return const Padding(
              padding: EdgeInsets.all(8.0),
              child: SyriusLoadingWidget(),
            );
          case ConnectionState.done:
            return _getPlasmaCheckBody(snapshot.data!);
          case ConnectionState.none:
            return Container();
          case ConnectionState.waiting:
            return const Padding(
              padding: EdgeInsets.all(8.0),
              child: SyriusLoadingWidget(),
            );
          default:
            return Container();
        }
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
          onPressed: plasmaInfo.currentPlasma >= kSentinelPlasmaAmountNeeded
              ? _onPlasmaCheckNextPressed
              : null,
        ),
      ],
    );
  }

  void _onPlasmaCheckNextPressed() {
    if (_lastCompletedStep == null) {
      _saveProgressAndNavigateToNextStep(SentinelsStepperStep.checkPlasma);
    } else if (StepperUtils.getStepState(
          SentinelsStepperStep.checkPlasma.index,
          _lastCompletedStep?.index,
        ) ==
        custom_material_stepper.StepState.complete) {
      setState(() {
        _currentStep = SentinelsStepperStep.values[_currentStep.index + 1];
      });
    }
  }

  bool _hasEnoughZnn(AccountInfo accountInfo) =>
      accountInfo.getBalance(
        kZnnCoin.tokenStandard,
      ) >=
      sentinelRegisterZnnAmount;

  @override
  void dispose() {
    _qsrAmountController.dispose();
    _znnAmountController.dispose();
    _addressController.dispose();
    super.dispose();
  }
}
