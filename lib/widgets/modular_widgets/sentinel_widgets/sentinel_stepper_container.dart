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

enum SentinelStepperStep {
  checkPlasma,
  qsrManagement,
  znnManagement,
  deploySentinel,
}

class SentinelStepperContainer extends StatefulWidget {
  const SentinelStepperContainer({super.key});

  @override
  State createState() {
    return _MainSentinelState();
  }
}

class _MainSentinelState extends State<SentinelStepperContainer> {
  late SentinelStepperStep _currentStep;
  SentinelStepperStep? _lastCompletedStep;

  final int _numSteps = SentinelStepperStep.values.length;

  final TextEditingController _qsrAmountController = TextEditingController();
  final TextEditingController _znnAmountController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final GlobalKey<FormState> _qsrFormKey = GlobalKey();

  final GlobalKey<LoadingButtonState> _depositQsrButtonKey = GlobalKey();
  final GlobalKey<LoadingButtonState> _withdrawButtonKey = GlobalKey();
  final GlobalKey<LoadingButtonState> _registerButtonKey = GlobalKey();

  BigInt _maxQsrAmount = BigInt.zero;

  late SentinelsQsrInfoBloc _sentinelsQsrInfoViewModel;

  @override
  void initState() {
    super.initState();
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
    return ViewModelBuilder<SentinelsQsrInfoBloc>.reactive(
      onViewModelReady: (model) {
        _sentinelsQsrInfoViewModel = model;
        model.getQsrManagementInfo(_addressController.text);
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
      builder: (_, model, __) => StreamBuilder<SentinelsQsrInfo?>(
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
            padding: EdgeInsets.all(8),
            child: SyriusLoadingWidget(),
          );
        },
      ),
      viewModelBuilder: SentinelsQsrInfoBloc.new,
    );
  }

  Row _getQsrManagementStepBody(
    BuildContext context,
    AccountInfo accountInfo,
    SentinelsQsrInfo qsrInfo,
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
                    height: 10,
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AvailableBalance(
                          kQsrCoin,
                          accountInfo,
                        ),
                        Text(
                          '${qsrInfo.cost.addDecimals(coinDecimals)} ${kQsrCoin.symbol} required for a Sentinel Node',
                          style:
                              Theme.of(context).inputDecorationTheme.hintStyle,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 10,
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
                            validator: (value) => InputValidators.correctValue(
                              value,
                              _maxQsrAmount,
                              kQsrCoin.decimals,
                              BigInt.zero,
                            ),
                            suffixIcon: _getAmountSuffix(accountInfo),
                            suffixIconConstraints:
                                const BoxConstraints(maxWidth: 50),
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
                    padding: const EdgeInsets.symmetric(vertical: 25),
                    child: DottedBorderInfoWidget(
                      text:
                          'You will be able to unlock the ${kQsrCoin.symbol} if you '
                          'choose to disassemble the Sentinel',
                      borderColor: AppColors.qsrColor,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Visibility(
                    visible: qsrInfo.deposit < qsrInfo.cost,
                    child: _getDepositQsrViewModel(accountInfo, qsrInfo),
                  ),
                  Visibility(
                    visible: qsrInfo.deposit >= qsrInfo.cost,
                    child: StepperButton(
                      text: 'Next',
                      onPressed: _onQsrNextPressed,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(
          width: 45,
        ),
        Expanded(
          child: Visibility(
            visible: qsrInfo.deposit > BigInt.zero,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: BorderRadius.circular(6),
              ),
              margin: const EdgeInsets.only(
                bottom: 30,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 30),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Column(
                      children: [
                        Stack(
                          alignment: Alignment.center,
                          children: [
                            SizedBox(
                              width: 150,
                              height: 150,
                              child: AspectRatio(
                                aspectRatio: 1,
                                child: StandardPieChart(
                                  sections: [
                                    PieChartSectionData(
                                      showTitle: false,
                                      radius: 7,
                                      value: (qsrInfo.cost - qsrInfo.deposit) /
                                          qsrInfo.cost,
                                      color:
                                          AppColors.qsrColor.withOpacity(0.3),
                                    ),
                                    PieChartSectionData(
                                      showTitle: false,
                                      radius: 7,
                                      value: qsrInfo.deposit / qsrInfo.cost,
                                      color: AppColors.qsrColor,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Text(
                              'Sentinel Slot value\n${qsrInfo.cost.addDecimals(coinDecimals)} ${kQsrCoin.symbol}',
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
                          width: 130,
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

  Widget _getDepositQsrViewModel(
      AccountInfo accountInfo, SentinelsQsrInfo qsrInfo,) {
    return ViewModelBuilder<SentinelsDepositQsrBloc>.reactive(
      onViewModelReady: (model) {
        model.stream.listen(
          (response) {
            if (response != null) {
              _depositQsrButtonKey.currentState?.animateReverse();
              _sentinelsQsrInfoViewModel.getQsrManagementInfo(
                _addressController.text,
              );
              setState(() {});
            } else {
              setState(() {});
            }
          },
          onError: (error) async {
            _depositQsrButtonKey.currentState?.animateReverse();
            await NotificationUtils.sendNotificationError(
              error,
              'Error while depositing ${kQsrCoin.symbol}',
            );
            setState(() {});
          },
        );
      },
      builder: (_, model, __) =>
          _getDepositQsrButton(model, accountInfo, qsrInfo),
      viewModelBuilder: SentinelsDepositQsrBloc.new,
    );
  }

  Widget _getDepositQsrButton(
    SentinelsDepositQsrBloc model,
    AccountInfo accountInfo,
    SentinelsQsrInfo qsrInfo,
  ) {
    return LoadingButton.stepper(
      key: _depositQsrButtonKey,
      text: 'Deposit',
      onPressed: _hasQsrBalance(accountInfo) &&
              _qsrAmountValidator(_qsrAmountController.text, qsrInfo) == null
          ? () => _onDepositButtonPressed(model, qsrInfo)
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
              _saveProgressAndNavigateToNextStep(
                SentinelStepperStep.checkPlasma,
              );
              _sentinelsQsrInfoViewModel.getQsrManagementInfo(
                _addressController.text,
              );
            }
          },
          onError: (error) async {
            _withdrawButtonKey.currentState?.animateReverse();
            await NotificationUtils.sendNotificationError(
              error,
              'Error while withdrawing ${kQsrCoin.symbol}',
            );
          },
        );
      },
      builder: (_, model, __) => _getWithdrawQsrButton(model, qsrDeposit),
      viewModelBuilder: SentinelsWithdrawQsrBloc.new,
    );
  }

  Widget _getWithdrawQsrButton(
    SentinelsWithdrawQsrBloc model,
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
            stepTitle: 'Sentinel deployment: Plasma check',
            stepContent: _getPlasmaCheckFutureBuilder(),
            stepSubtitle: 'Sufficient Plasma',
            stepState: StepperUtils.getStepState(
              SentinelStepperStep.checkPlasma.index,
              _lastCompletedStep?.index,
            ),
            context: context,
          ),
          StepperUtils.getMaterialStep(
            stepTitle: '${kQsrCoin.symbol} management',
            stepContent: _getQsrManagementStep(context, accountInfo),
            stepSubtitle: '${kQsrCoin.symbol} deposited',
            stepState: StepperUtils.getStepState(
              SentinelStepperStep.qsrManagement.index,
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
              SentinelStepperStep.znnManagement.index,
              _lastCompletedStep?.index,
            ),
            context: context,
          ),
          StepperUtils.getMaterialStep(
            stepTitle: 'Register Sentinel',
            stepContent: _getDeploySentinelStepBody(context),
            stepSubtitle: 'Sentinel registered',
            stepState: StepperUtils.getStepState(
              SentinelStepperStep.deploySentinel.index,
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
        bottom: 25,
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
                  SentinelStepperStep.deploySentinel,);
              setState(() {});
            } else {
              setState(() {});
            }
          },
          onError: (error) async {
            _registerButtonKey.currentState?.animateReverse();
            await NotificationUtils.sendNotificationError(
              error,
              'Error while deploying the Sentinel Node',
            );
            setState(() {});
          },
        );
      },
      builder: (_, model, __) => _getRegisterSentinelButton(model),
      viewModelBuilder: SentinelsDeployBloc.new,
    );
  }

  Widget _getRegisterSentinelButton(SentinelsDeployBloc model) {
    return LoadingButton.stepper(
      text: 'Register',
      onPressed: () => _onDeployPressed(model),
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
          children: <Widget>[
            Expanded(
              child: DisabledAddressField(_addressController),
            ),
          ],
        ),
        kVerticalSpacing,
        StepperUtils.getBalanceWidget(kZnnCoin, accountInfo),
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
          padding: const EdgeInsets.symmetric(vertical: 25),
          child: DottedBorderInfoWidget(
            text: 'You will be able to unlock the ${kZnnCoin.symbol} if you '
                'choose to disassemble the Sentinel',
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
      SentinelsDepositQsrBloc model, SentinelsQsrInfo qsrInfo,) {
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
    if (_lastCompletedStep == SentinelStepperStep.qsrManagement) {
      _saveProgressAndNavigateToNextStep(SentinelStepperStep.znnManagement);
    } else if (StepperUtils.getStepState(
          SentinelStepperStep.qsrManagement.index,
          _lastCompletedStep?.index,
        ) ==
        custom_material_stepper.StepState.complete) {
      setState(() {
        _currentStep = SentinelStepperStep.values[_currentStep.index + 1];
      });
    }
  }

  void _onDeployPressed(SentinelsDeployBloc model) {
    if (_lastCompletedStep == SentinelStepperStep.znnManagement) {
      _registerButtonKey.currentState?.animateForward();
      model.deploySentinel(
          _znnAmountController.text.extractDecimals(coinDecimals),);
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

  Widget _getWidgetBody(BuildContext context, AccountInfo accountInfo) {
    return Stack(
      children: [
        ListView(
          children: [
            _getMaterialStepper(context, accountInfo),
            Visibility(
              visible: _lastCompletedStep == SentinelStepperStep.deploySentinel,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 40,
                      horizontal: 50,
                    ),
                    margin: const EdgeInsets.symmetric(
                      vertical: 20,
                      horizontal: 50,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      borderRadius: const BorderRadius.all(
                        Radius.circular(
                          10,
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
                              size: 20,
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
                  Container(height: 20),
                ],
              ),
            ),
          ],
        ),
        Visibility(
          visible: _lastCompletedStep == SentinelStepperStep.deploySentinel,
          child: Positioned(
            right: 50,
            child: SizedBox(
              width: 400,
              height: 400,
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
      label: 'View Sentinels',
      onPressed: () {
        Navigator.pop(context);
      },
      iconData: MaterialCommunityIcons.eye_outline,
    );
  }

  void _saveProgressAndNavigateToNextStep(SentinelStepperStep completedStep) {
    setState(() {
      _lastCompletedStep = completedStep;
      if (_lastCompletedStep!.index + 1 < _numSteps) {
        _currentStep = SentinelStepperStep.values[completedStep.index + 1];
      }
    });
  }

  void _iniStepperControllers() {
    _currentStep = SentinelStepperStep.values.first;
  }

  bool _hasEnoughZnn(AccountInfo accountInfo) =>
      accountInfo.znn()! >= sentinelRegisterZnnAmount;

  bool _hasQsrBalance(AccountInfo accountInfo) =>
      accountInfo.qsr()! > BigInt.zero;

  String? _qsrAmountValidator(String? value, SentinelsQsrInfo qsrInfo) =>
      InputValidators.correctValue(
        value,
        _maxQsrAmount,
        kQsrCoin.decimals,
        BigInt.one,
        canBeEqualToMin: true,
      );

  void _onQsrNextPressed() {
    setState(() {
      _saveProgressAndNavigateToNextStep(SentinelStepperStep.qsrManagement);
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
          padding: EdgeInsets.all(8),
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
          height: 25,
        ),
        Row(
          children: <Widget>[
            Expanded(
              child: DisabledAddressField(_addressController),
            ),
            const SizedBox(
              width: 25,
            ),
            PlasmaIcon(plasmaInfo),
          ],
        ),
        const SizedBox(
          height: 25,
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
      _saveProgressAndNavigateToNextStep(SentinelStepperStep.checkPlasma);
    } else if (StepperUtils.getStepState(
          SentinelStepperStep.checkPlasma.index,
          _lastCompletedStep?.index,
        ) ==
        custom_material_stepper.StepState.complete) {
      setState(() {
        _currentStep = SentinelStepperStep.values[_currentStep.index + 1];
      });
    }
  }

  @override
  void dispose() {
    _qsrAmountController.dispose();
    _znnAmountController.dispose();
    _addressController.dispose();
    super.dispose();
  }
}
