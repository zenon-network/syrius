import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:lottie/lottie.dart';
import 'package:stacked/stacked.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
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

enum _PillarStepperStep {
  checkPlasma,
  qsrManagement,
  znnManagement,
  deployPillar,
}

class PillarStepperView extends StatefulWidget {
  const PillarStepperView({super.key});

  @override
  State createState() {
    return _MainPillarState();
  }
}

class _MainPillarState extends State<PillarStepperView> {
  _PillarStepperStep _currentStep = _PillarStepperStep.checkPlasma;
  _PillarStepperStep? _lastCompletedStep;

  bool get _hasPillarBeenRegistered =>
      _lastCompletedStep == _PillarStepperStep.deployPillar;

  final TextEditingController _qsrAmountController = TextEditingController();
  final TextEditingController _pillarNameController = TextEditingController();
  final TextEditingController _pillarRewardAddressController =
      TextEditingController();
  final TextEditingController _pillarMomentumController =
      TextEditingController();
  final TextEditingController _znnAmountController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  final FocusNode _pillarNameNode = FocusNode();
  final FocusNode _pillarRewardNode = FocusNode();
  final FocusNode _pillarMomentumNode = FocusNode();

  final GlobalKey<FormFieldState> _qsrFormKey = GlobalKey();

  final GlobalKey<LoadingButtonState> _depositQsrButtonKey = GlobalKey();
  final GlobalKey<LoadingButtonState> _withdrawButtonKey = GlobalKey();
  final GlobalKey<LoadingButtonState> _registerButtonKey = GlobalKey();

  /// The minimum value between available and needed QSR to cover the cost
  ///
  /// For example: if 100 is available to be deposited, and only 25 needed,
  /// then this variable is equal to 25
  ///
  /// If 100 more QSR is needed, and 100 is available, then variable is equal
  /// to 100
  BigInt _maxQsrAmount = BigInt.zero;

  final List<GlobalKey<FormState>> _pillarFormKeys = List.generate(
    3,
    (int index) => GlobalKey(),
  );

  double _momentumRewardPercentageGiven = 0;
  double _delegateRewardPercentageGiven = 0;

  @override
  void initState() {
    super.initState();
    _znnAmountController.text = pillarRegisterZnnAmount.addDecimals(
      coinDecimals,
    );
    _addressController.text = kSelectedAddress!;
    _pillarRewardAddressController.text = kSelectedAddress!;
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
        MultipleBalanceStatus.success => _getWidgetBody(
          context,
          state.data![_addressController.text]!,
        ),
      },
    );
  }

  Widget _getQsrManagementStep(BuildContext context, AccountInfo accountInfo) {
    return BlocConsumer<
      CreatePillarQsrInfoBloc,
      FetchState<CreatePillarQsrInfoData>
    >(
      builder: (_, FetchState<CreatePillarQsrInfoData> state) =>
          switch (state) {
            FetchFailure<CreatePillarQsrInfoData>() => SyriusErrorWidget(
              state.exception,
            ),
            FetchInitial<CreatePillarQsrInfoData>() => const Padding(
              padding: EdgeInsets.all(8),
              child: SyriusLoadingWidget(),
            ),
            FetchPopulated<CreatePillarQsrInfoData>() =>
              _getQsrManagementStepBody(
                context,
                accountInfo,
                state.data,
              ),
          },
      listener: (_, FetchState<CreatePillarQsrInfoData> state) {
        if (state is FetchPopulated<CreatePillarQsrInfoData>) {
          final CreatePillarQsrInfoData data = state.data;

          _maxQsrAmount = MathUtils.bigMin(
            accountInfo.getBalance(
              kQsrCoin.tokenStandard,
            ),
            MathUtils.bigMax(BigInt.zero, data.cost - data.deposit),
          );
          setState(() {
            _qsrAmountController.text = _maxQsrAmount.addDecimals(
              coinDecimals,
            );
          });
        }
      },
    );
  }

  Row _getQsrManagementStepBody(
    BuildContext context,
    AccountInfo accountInfo,
    CreatePillarQsrInfoData qsrInfo,
  ) {
    final bool qsrCostCovered = qsrInfo.deposit >= qsrInfo.cost;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  DisabledAddressField(_addressController),
                  kVerticalSpacing,
                  Padding(
                    padding: const EdgeInsets.only(left: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        AvailableBalance(
                          kQsrCoin,
                          accountInfo,
                        ),
                        Text(
                          context.l10n.requiredForPillarSlot(
                            qsrInfo.cost.addDecimals(coinDecimals),
                            kQsrCoin.symbol,
                          ),
                          style: Theme.of(
                            context,
                          ).inputDecorationTheme.hintStyle,
                        ),
                      ],
                    ),
                  ),
                  Visibility(
                    visible: !qsrCostCovered,
                    child: Column(
                      children: [
                        kVerticalSpacing,
                        TextFormField(
                          autovalidateMode: AutovalidateMode.always,
                          controller: _qsrAmountController,
                          cursorColor: AppColors.qsrColor,
                          decoration: InputDecoration(
                            border: const OutlineInputBorder(
                              borderSide: BorderSide(
                                color: AppColors.qsrColor,
                              ),
                            ),
                            enabledBorder: const OutlineInputBorder(
                              borderSide: BorderSide(
                                color: AppColors.qsrColor,
                              ),
                            ),
                            focusedBorder: const OutlineInputBorder(
                              borderSide: BorderSide(
                                color: AppColors.qsrColor,
                              ),
                            ),
                            hintText: context.l10n.amount,
                          ),
                          inputFormatters:
                              FormatUtils.getAmountTextInputFormatters(
                                _qsrAmountController.text,
                              ),
                          key: _qsrFormKey,
                          style: const TextStyle(
                            color: AppColors.qsrColor,
                          ),
                          validator: (String? value) =>
                              InputValidators.correctValue(
                                value,
                                _maxQsrAmount,
                                kQsrCoin.decimals,
                                BigInt.zero,
                              ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 25),
                    child: DottedBorderInfoWidget(
                      borderColor: AppColors.qsrColor,
                      text: context.l10n.depositedCoinWillBurn(kQsrCoin.symbol),
                    ),
                  ),
                ],
              ),
              Row(
                children: <Widget>[
                  Visibility(
                    visible: !qsrCostCovered,
                    child: _getDepositQsrViewModel(accountInfo, qsrInfo),
                  ),
                  Visibility(
                    visible: qsrCostCovered,
                    child: OutlinedButton(
                      onPressed: _onQsrNextPressed,
                      child: Text(context.l10n.next),
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
            child: Card(
              color: context.themeData.inputDecorationTheme.fillColor,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    Expanded(
                      child: Column(
                        children: <Widget>[
                          Stack(
                            alignment: Alignment.center,
                            children: <Widget>[
                              AspectRatio(
                                aspectRatio: 1,
                                child: StandardPieChart(
                                  sections: <PieChartSectionData>[
                                    PieChartSectionData(
                                      showTitle: false,
                                      radius: 7,
                                      value:
                                          (qsrInfo.cost - qsrInfo.deposit) /
                                          qsrInfo.cost,
                                      color: AppColors.qsrColor.withOpacity(
                                        0.3,
                                      ),
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
                              Padding(
                                padding: const EdgeInsets.all(8),
                                child: Text(
                                  context.l10n.currentPillarSlotFee(
                                    qsrInfo.cost.addDecimals(coinDecimals),
                                    kQsrCoin.symbol,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Column(
                        children: <Widget>[
                          Text(
                            context.l10n.youHaveDeposited(
                              qsrInfo.deposit.addDecimals(coinDecimals),
                              kQsrCoin.symbol,
                            ),
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                          kVerticalSpacing,
                          _getWithdrawQsrButtonViewModel(
                            qsrInfo.deposit,
                          ),
                        ],
                      ),
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
    AccountInfo accountInfo,
    CreatePillarQsrInfoData qsrInfo,
  ) {
    return ViewModelBuilder<PillarsDepositQsrBloc>.reactive(
      onViewModelReady: (PillarsDepositQsrBloc model) {
        model.stream.listen(
          (AccountBlockTemplate? response) {
            if (response != null) {
              _depositQsrButtonKey.currentState?.animateReverse();
              _refreshPillarQsrInfo();
              setState(() {});
            } else {
              setState(() {});
            }
          },
          onError: (error) async {
            _depositQsrButtonKey.currentState?.animateReverse();
            await NotificationUtils.sendNotificationError(
              error,
              context.l10n.errorWhileDepositing(kQsrCoin.symbol),
            );
            setState(() {});
          },
        );
      },
      builder: (_, PillarsDepositQsrBloc model, __) =>
          _getDepositQsrButton(model, accountInfo, qsrInfo),
      viewModelBuilder: PillarsDepositQsrBloc.new,
    );
  }

  void _refreshPillarQsrInfo() {
    context.read<CreatePillarQsrInfoBloc>().add(
      FetchRequestData(
        address: Address.parse(_addressController.text),
      ),
    );
  }

  Widget _getDepositQsrButton(
    PillarsDepositQsrBloc model,
    AccountInfo accountInfo,
    CreatePillarQsrInfoData qsrInfo,
  ) {
    return LoadingButton(
      key: _depositQsrButtonKey,
      text: context.l10n.deposit,
      onPressed:
          _hasQsrBalance(accountInfo) &&
              _qsrAmountValidator(_qsrAmountController.text, qsrInfo) == null
          ? () => _onDepositButtonPressed(model, qsrInfo)
          : null,
      outlineColor: AppColors.qsrColor,
      textStyle: const TextStyle(
        color: AppColors.qsrColor,
      ),
    );
  }

  Widget _getWithdrawQsrButtonViewModel(
    BigInt qsrDeposit,
  ) {
    return ViewModelBuilder<PillarsWithdrawQsrBloc>.reactive(
      onViewModelReady: (PillarsWithdrawQsrBloc model) {
        model.stream.listen(
          (AccountBlockTemplate? event) {
            if (event != null) {
              _withdrawButtonKey.currentState?.animateReverse();
              _saveProgressAndNavigateToNextStep(
                _PillarStepperStep.checkPlasma,
              );
              _refreshPillarQsrInfo();
            }
          },
          onError: (error) async {
            _withdrawButtonKey.currentState?.animateReverse();
            await NotificationUtils.sendNotificationError(
              error,
              context.l10n.errorWhileWithdrawing(kQsrCoin.symbol),
            );
          },
        );
      },
      builder: (_, PillarsWithdrawQsrBloc model, __) =>
          _getWithdrawQsrButton(model, qsrDeposit),
      viewModelBuilder: PillarsWithdrawQsrBloc.new,
    );
  }

  Widget _getWithdrawQsrButton(
    PillarsWithdrawQsrBloc model,
    BigInt qsrDeposit,
  ) {
    return Visibility(
      visible: qsrDeposit > BigInt.zero,
      child: LoadingButton(
        text: context.l10n.withdraw,
        onPressed: () => _onWithdrawButtonPressed(model, qsrDeposit),
        key: _withdrawButtonKey,
        outlineColor: AppColors.qsrColor,
        textStyle: const TextStyle(
          color: AppColors.qsrColor,
        ),
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
        steps: <custom_material_stepper.Step>[
          StepperUtils.getMaterialStep(
            stepTitle: context.l10n.pillarDeployment,
            stepContent: _getPlasmaCheckFutureBuilder(),
            stepSubtitle: context.l10n.sufficientPlasma,
            stepState: StepperUtils.getStepState(
              _PillarStepperStep.checkPlasma.index,
              _lastCompletedStep?.index,
            ),
            context: context,
          ),
          StepperUtils.getMaterialStep(
            stepTitle: context.l10n.management(kQsrCoin.symbol),
            stepContent: _getQsrManagementStep(context, accountInfo),
            stepSubtitle: context.l10n.deposited(kQsrCoin.symbol),
            stepState: StepperUtils.getStepState(
              _PillarStepperStep.qsrManagement.index,
              _lastCompletedStep?.index,
            ),
            context: context,
            expanded: true,
          ),
          StepperUtils.getMaterialStep(
            stepTitle: context.l10n.management(kZnnCoin.symbol),
            stepContent: _getZnnManagementStepBody(context, accountInfo),
            stepSubtitle: context.l10n.locked(kZnnCoin.symbol),
            stepState: StepperUtils.getStepState(
              _PillarStepperStep.znnManagement.index,
              _lastCompletedStep?.index,
            ),
            context: context,
          ),
          StepperUtils.getMaterialStep(
            stepTitle: context.l10n.registerPillar,
            stepContent: _getDeployPillarStepBody(context),
            stepSubtitle: context.l10n.pillarRegistered,
            stepState: StepperUtils.getStepState(
              _PillarStepperStep.deployPillar.index,
              _lastCompletedStep?.index,
            ),
            context: context,
          ),
        ],
      ),
    );
  }

  Widget _getDeployPillarStepBody(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: TextFormField(
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  controller: _pillarNameController,
                  decoration: InputDecoration(
                    hintText: context.l10n.pillarName,
                  ),
                  focusNode: _pillarNameNode,
                  key: _pillarFormKeys[0],
                  validator: Validations.pillarName,
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
              Expanded(
                child: TextFormField(
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  controller: _pillarRewardAddressController,
                  decoration: InputDecoration(
                    hintText: context.l10n.pillarRewardAddress,
                    suffixIcon: ContentPasteButton(
                      controller: _pillarRewardAddressController,
                    ),
                  ),
                  focusNode: _pillarRewardNode,
                  key: _pillarFormKeys[1],
                  validator: InputValidators.checkAddress,
                ),
              ),
              StandardTooltipIcon(
                context.l10n.addressToCollectRewards,
                Icons.help,
              ),
            ],
          ),
          kVerticalSpacing,
          Row(
            children: <Widget>[
              Expanded(
                child: Form(
                  child: TextFormField(
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    controller: _pillarMomentumController,
                    decoration: InputDecoration(
                      hintText: context.l10n.pillarProducerAddress,
                      suffixIcon: ContentPasteButton(
                        controller: _pillarMomentumController,
                      ),
                    ),
                    focusNode: _pillarMomentumNode,
                    key: _pillarFormKeys[2],
                    validator: InputValidators.validatePillarMomentumAddress,
                  ),
                ),
              ),
              StandardTooltipIcon(
                context.l10n.addressToProduceMomentums,
                Icons.help,
              ),
            ],
          ),
          kVerticalSpacing,
          _getPillarMomentumRewardsStepContent(),
          const SizedBox(
            height: 25,
          ),
          _getDeployButton(),
        ],
      ),
    );
  }

  Widget _getDeployButton() {
    return ViewModelBuilder<PillarsDeployBloc>.reactive(
      onViewModelReady: (PillarsDeployBloc model) {
        model.stream.listen(
          (AccountBlockTemplate? response) {
            if (response != null) {
              _registerButtonKey.currentState?.animateReverse();
              _saveProgressAndNavigateToNextStep(
                _PillarStepperStep.deployPillar,
              );
              setState(() {});
            } else {
              setState(() {});
            }
          },
          onError: (error) async {
            _registerButtonKey.currentState?.animateReverse();
            await NotificationUtils.sendNotificationError(
              error,
              context.l10n.errorDeployingPillar,
            );
            setState(() {});
          },
        );
      },
      builder: (_, PillarsDeployBloc model, __) =>
          _getRegisterPillarButton(model),
      viewModelBuilder: PillarsDeployBloc.new,
    );
  }

  Widget _getRegisterPillarButton(PillarsDeployBloc model) {
    return LoadingButton(
      text: context.l10n.register,
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
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: DisabledAddressField(_addressController),
            ),
          ],
        ),
        StepperUtils.getBalanceWidget(kZnnCoin, accountInfo),
        Row(
          children: <Widget>[
            Expanded(
              child: TextField(
                enabled: false,
                controller: _znnAmountController,
                style: const TextStyle(
                  color: AppColors.znnColor,
                ),
              ),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 25),
          child: DottedBorderInfoWidget(
            text: context.l10n.disassemblePillarToUnlockCoin(kZnnCoin.symbol),
          ),
        ),
        OutlinedButton(
          onPressed: _hasEnoughZnn(accountInfo) ? _onNextPressed : null,
          child: Text(context.l10n.next),
        ),
      ],
    );
  }

  void _onDepositButtonPressed(
    PillarsDepositQsrBloc model,
    CreatePillarQsrInfoData qsrInfo,
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
    if (_lastCompletedStep == _PillarStepperStep.qsrManagement) {
      _saveProgressAndNavigateToNextStep(_PillarStepperStep.znnManagement);
    } else if (StepperUtils.getStepState(
          _PillarStepperStep.qsrManagement.index,
          _lastCompletedStep?.index,
        ) ==
        custom_material_stepper.StepState.complete) {
      setState(() {
        _currentStep = _PillarStepperStep.values[_currentStep.index + 1];
      });
    }
  }

  void _onDeployPressed(PillarsDeployBloc model) {
    if (_lastCompletedStep == _PillarStepperStep.znnManagement) {
      if (_pillarFormKeys.every(
        (GlobalKey<FormState> element) => element.currentState!.validate(),
      )) {
        _registerButtonKey.currentState?.animateForward();
        model.deployPillar(
          pillarName: _pillarNameController.text,
          rewardAddress: _pillarRewardAddressController.text,
          blockProducingAddress: _pillarMomentumController.text,
          giveBlockRewardPercentage: _momentumRewardPercentageGiven.toInt(),
          giveDelegateRewardPercentage: _delegateRewardPercentageGiven.toInt(),
        );
      } else {
        for (final GlobalKey<FormState> element in _pillarFormKeys) {
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
      children: <Widget>[
        ListView(
          children: <Widget>[
            _getMaterialStepper(context, accountInfo),
            Visibility(
              visible: _hasPillarBeenRegistered,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
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
                        style: Theme.of(context).textTheme.titleMedium,
                        children: <InlineSpan>[
                          TextSpan(
                            text: '${context.l10n.pillar} ',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          TextSpan(
                            text: context.l10n.successfully,
                            style: Theme.of(context).textTheme.titleMedium!
                                .copyWith(
                                  color: AppColors.znnColor,
                                ),
                          ),
                          TextSpan(
                            text: context.l10n.registeredUse,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          TextSpan(
                            text: context.l10n.znnController,
                            style: Theme.of(context).textTheme.titleMedium!
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
                            text: context.l10n.checkPillarStatus,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      SizedBox(
                        width: 250,
                        child: _buildRegisterAnotherPillarButton(context),
                      ),
                      const SizedBox(
                        width: 80,
                      ),
                      SizedBox(
                        width: 250,
                        child: _getViewPillarsButton(),
                      ),
                    ],
                  ),
                  Container(height: 20),
                ],
              ),
            ),
          ],
        ),
        Visibility(
          visible: _hasPillarBeenRegistered,
          child: Positioned(
            right: 50,
            child: SizedBox(
              width: 400,
              height: 400,
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

  OutlinedButton _buildRegisterAnotherPillarButton(BuildContext context) {
    return OutlinedButton.icon(
      label: Text(context.l10n.registerAnotherPillar),
      onPressed: _onDeployAnotherPillarButtonPressed,
      icon: const Icon(
        Icons.refresh,
        color: Colors.white,
      ),
      iconAlignment: .end,
    );
  }

  Widget _getViewPillarsButton() {
    return OutlinedButton.icon(
      label: Text(context.l10n.viewPillars),
      onPressed: () {
        Navigator.pop(context);
      },
      icon: const Icon(
        MaterialCommunityIcons.pillar,
        color: Colors.white,
      ),
      iconAlignment: .end,
    );
  }

  Future<void> _onDeployAnotherPillarButtonPressed() async {
    _pillarNameController.clear();
    _pillarRewardAddressController.clear();
    _pillarMomentumController.clear();
    _lastCompletedStep = null;
    _refreshPillarQsrInfo();
    setState(() {
      _currentStep = _PillarStepperStep.values.first;
    });
  }

  void _saveProgressAndNavigateToNextStep(_PillarStepperStep completedStep) {
    setState(() {
      _lastCompletedStep = completedStep;
      if (!_hasPillarBeenRegistered) {
        _currentStep = _PillarStepperStep.values[completedStep.index + 1];
      }
    });
  }

  bool _hasEnoughZnn(AccountInfo accountInfo) =>
      accountInfo.znn()! >= pillarRegisterZnnAmount;

  bool _canDeployPillar() =>
      InputValidators.notEmpty(
            context.l10n.pillarName,
            _pillarNameController.text,
          ) ==
          null &&
      InputValidators.notEmpty(
            context.l10n.pillarRewardAddress,
            _pillarRewardAddressController.text,
          ) ==
          null &&
      InputValidators.notEmpty(
            context.l10n.pillarMomentumAddress,
            _pillarMomentumController.text,
          ) ==
          null;

  bool _hasQsrBalance(AccountInfo accountInfo) =>
      accountInfo.qsr()! > BigInt.zero;

  String? _qsrAmountValidator(String? value, CreatePillarQsrInfoData qsrInfo) =>
      InputValidators.correctValue(
        value,
        _maxQsrAmount,
        kQsrCoin.decimals,
        BigInt.one,
        canBeEqualToMin: true,
      );

  void _onQsrNextPressed() {
    setState(() {
      _saveProgressAndNavigateToNextStep(_PillarStepperStep.qsrManagement);
    });
  }

  Widget _getPlasmaCheckFutureBuilder() {
    return FutureBuilder<PlasmaInfo?>(
      future: zenon!.embedded.plasma.get(Address.parse(kSelectedAddress!)),
      builder: (_, AsyncSnapshot<PlasmaInfo?> snapshot) {
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
      children: <Widget>[
        Text(
          context.l10n.morePlasmaRequired,
          style: Theme.of(context).textTheme.titleMedium,
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
        OutlinedButton(
          onPressed: plasmaInfo.currentPlasma >= kPillarPlasmaAmountNeeded
              ? _onPlasmaCheckNextPressed
              : null,
          child: Text(context.l10n.next),
        ),
      ],
    );
  }

  void _onPlasmaCheckNextPressed() {
    if (_lastCompletedStep == null) {
      _saveProgressAndNavigateToNextStep(_PillarStepperStep.checkPlasma);
    } else if (StepperUtils.getStepState(
          _PillarStepperStep.checkPlasma.index,
          _lastCompletedStep?.index,
        ) ==
        custom_material_stepper.StepState.complete) {
      setState(() {
        _currentStep = _PillarStepperStep.values[_currentStep.index + 1];
      });
    }
    context.read<CreatePillarQsrInfoBloc>().add(
      FetchRequestData(address: Address.parse(_addressController.text)),
    );
  }

  Widget _getPillarMomentumRewardsStepContent() {
    return Column(
      children: <Widget>[
        CustomSlider(
          description: context.l10n.percentageOfMomentumRewards,
          descriptionPosition: SliderDescriptionPosition.top,
          startValue: 0,
          min: 0,
          maxValue: 100,
          callback: (double value) {
            setState(() {
              _momentumRewardPercentageGiven = value;
            });
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(
              context.l10n.pillarsWithNumber(
                100 - _momentumRewardPercentageGiven.toInt(),
              ),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            Text(
              context.l10n.delegators(_momentumRewardPercentageGiven.toInt()),
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ],
        ),
        kVerticalSpacing,
        CustomSlider(
          description: context.l10n.percentageDelegationRewardsGiven,
          descriptionPosition: SliderDescriptionPosition.top,
          startValue: 0,
          min: 0,
          maxValue: 100,
          callback: (double value) {
            setState(() {
              _delegateRewardPercentageGiven = value;
            });
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text(
              context.l10n.pillarsWithNumber(
                100 - _delegateRewardPercentageGiven.toInt(),
              ),
              style: Theme.of(context).textTheme.titleSmall,
            ),
            Text(
              context.l10n.delegators(_delegateRewardPercentageGiven.toInt()),
              style: Theme.of(context).textTheme.titleSmall,
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
    _pillarNameNode.dispose();
    _pillarRewardNode.dispose();
    _pillarMomentumNode.dispose();
    super.dispose();
  }
}
