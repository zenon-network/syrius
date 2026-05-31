import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:lottie/lottie.dart';
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

/// A stepper that guides the user along the needed steps that they have to
/// take to create a pillar.
///
/// The deposit QSR step works in such a way as to not allow the user to
/// deposit, by mistake, more QSR than it's needed for the creation of a
/// pillar.
///
/// For example, if 150k QSR are needed, then that's how much the user is
/// allowed to deposit totally.
class CreatePillarStepperView extends StatefulWidget {
  /// {@macro default_constructor}
  const CreatePillarStepperView({super.key});

  @override
  State createState() {
    return _MainPillarState();
  }
}

class _MainPillarState extends State<CreatePillarStepperView> {
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

  String? get _pillarNameError =>
      Validations.pillarName(_pillarNameController.text);

  String? get _pillarRewardAddressError =>
      InputValidators.checkAddress(_pillarRewardAddressController.text);

  String? get _pillarMomentumError =>
      InputValidators.validatePillarMomentumAddress(
        _pillarMomentumController.text,
      );

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

  Widget _buildQsrManagementStep(
    BuildContext context,
    AccountInfo accountInfo,
  ) {
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
              _buildQsrManagementStepBody(
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

  Row _buildQsrManagementStepBody(
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
                      children: <Widget>[
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
                          style: const TextStyle(
                            color: AppColors.qsrColor,
                          ),
                          validator: _qsrAmountValidator,
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
                    child: _buildDepositQsrButton(accountInfo, qsrInfo),
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
                                      color: AppColors.qsrColor.withAlpha(
                                        (255 * 0.3).round(),
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
                          _buildWithdrawQsrButton(
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

  Widget _buildDepositQsrButton(
    AccountInfo accountInfo,
    CreatePillarQsrInfoData qsrInfo,
  ) {
    return BlocListener<PillarDepositQsrBloc, PillarDepositQsrState>(
      listener: (_, PillarDepositQsrState state) {
        if (state is PillarDepositQsrDone) {
          _depositQsrButtonKey.currentState?.animateReverse();
          _refreshPillarQsrInfo();
        } else if (state is PillarDepositQsrLoading) {
          _depositQsrButtonKey.currentState?.animateForward();
        } else if (state is PillarDepositQsrFailure) {
          _depositQsrButtonKey.currentState?.animateReverse();
          unawaited(
            NotificationUtils.sendNotificationError(
              state.exception,
              context.l10n.errorWhileDepositing(kQsrCoin.symbol),
            ),
          );
        }
      },
      child: LoadingButton(
        key: _depositQsrButtonKey,
        text: context.l10n.deposit,
        onPressed:
            _hasQsrBalance(accountInfo) &&
                _qsrAmountValidator(_qsrAmountController.text) == null
            ? () => _onDepositButtonPressed(qsrInfo)
            : null,
        outlineColor: AppColors.qsrColor,
        textStyle: const TextStyle(
          color: AppColors.qsrColor,
        ),
      ),
    );
  }

  void _refreshPillarQsrInfo() {
    context.read<CreatePillarQsrInfoBloc>().add(
      FetchRequestData(
        address: Address.parse(_addressController.text),
      ),
    );
  }

  Widget _buildWithdrawQsrButton(
    BigInt qsrDeposit,
  ) {
    return BlocListener<PillarWithdrawQsrBloc, PillarWithdrawQsrState>(
      listener: (_, PillarWithdrawQsrState state) {
        if (state is PillarWithdrawQsrLoading) {
          _withdrawButtonKey.currentState?.animateForward();
        } else if (state is PillarWithdrawQsrFailure) {
          _withdrawButtonKey.currentState?.animateReverse();
          unawaited(
            NotificationUtils.sendNotificationError(
              state.exception,
              context.l10n.errorWhileWithdrawing(kQsrCoin.symbol),
            ),
          );
        } else if (state is PillarWithdrawQsrPopulated) {
          _withdrawButtonKey.currentState?.animateReverse();
          _saveProgressAndNavigateToNextStep(
            _PillarStepperStep.checkPlasma,
          );
          _refreshPillarQsrInfo();
        }
      },
      child: LoadingButton(
        text: context.l10n.withdraw,
        onPressed: () => _onWithdrawButtonPressed(qsrDeposit),
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
            stepContent: _buildQsrManagementStep(context, accountInfo),
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
            stepContent: _buildZnnManagementStepBody(context, accountInfo),
            stepSubtitle: context.l10n.locked(kZnnCoin.symbol),
            stepState: StepperUtils.getStepState(
              _PillarStepperStep.znnManagement.index,
              _lastCompletedStep?.index,
            ),
            context: context,
          ),
          StepperUtils.getMaterialStep(
            stepTitle: context.l10n.registerPillar,
            stepContent: _buildDeployPillarStepBody(context),
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

  Widget _buildDeployPillarStepBody(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: TextField(
                controller: _pillarNameController,
                decoration: InputDecoration(
                  errorText: _pillarNameController.text.isNotEmpty
                      ? _pillarNameError
                      : null,
                  hintText: context.l10n.pillarName,
                ),
                focusNode: _pillarNameNode,
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
              child: TextField(
                controller: _pillarRewardAddressController,
                decoration: InputDecoration(
                  errorText: _pillarRewardAddressController.text.isNotEmpty
                      ? _pillarRewardAddressError
                      : null,
                  hintText: context.l10n.pillarRewardAddress,
                  suffixIcon: FieldSuffixButtons(
                    controller: _pillarRewardAddressController,
                  ),
                ),
                focusNode: _pillarRewardNode,
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
              child: TextField(
                controller: _pillarMomentumController,
                decoration: InputDecoration(
                  errorText: _pillarMomentumController.text.isNotEmpty
                      ? _pillarMomentumError
                      : null,
                  hintText: context.l10n.pillarProducerAddress,
                  suffixIcon: FieldSuffixButtons(
                    controller: _pillarMomentumController,
                  ),
                ),
                focusNode: _pillarMomentumNode,
              ),
            ),
            StandardTooltipIcon(
              context.l10n.addressToProduceMomentums,
              Icons.help,
            ),
          ],
        ),
        kVerticalSpacing,
        _buildPillarMomentumRewardsStepContent(),
        kVerticalGap25,
        _buildDeployButton(),
        kVerticalGap25,
      ],
    );
  }

  Widget _buildDeployButton() {
    return BlocListener<DeployPillarBloc, DeployPillarState>(
      listener: (_, DeployPillarState state) {
        if (state is DeployPillarDone) {
          _registerButtonKey.currentState?.animateReverse();
          _saveProgressAndNavigateToNextStep(
            _PillarStepperStep.deployPillar,
          );
        } else if (state is DeployPillarFailure) {
          _registerButtonKey.currentState?.animateReverse();
          unawaited(
            NotificationUtils.sendNotificationError(
              state.exception,
              context.l10n.errorDeployingPillar,
            ),
          );
        } else if (state is DeployPillarLoading) {
          _registerButtonKey.currentState?.animateForward();
        }
      },
      child: ListenableBuilder(
        listenable: Listenable.merge(<Listenable>[
          _pillarNameController,
          _pillarMomentumController,
          _pillarRewardAddressController,
        ]),
        builder: (_, _) {
          return LoadingButton(
            text: context.l10n.register,
            onPressed: _canDeployPillar() ? _onDeployPressed : null,
            key: _registerButtonKey,
          );
        },
      ),
    );
  }

  Widget _buildZnnManagementStepBody(
    BuildContext context,
    AccountInfo accountInfo,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        DisabledAddressField(_addressController),
        AvailableBalance.stepper(kZnnCoin, accountInfo),
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
        kVerticalGap25,
        DottedBorderInfoWidget(
          text: context.l10n.disassemblePillarToUnlockCoin(kZnnCoin.symbol),
        ),
        kVerticalGap25,
        OutlinedButton(
          onPressed: _hasEnoughZnn(accountInfo)
              ? () {
                  _saveProgressAndNavigateToNextStep(
                    _PillarStepperStep.znnManagement,
                  );
                }
              : null,
          child: Text(context.l10n.next),
        ),
      ],
    );
  }

  void _onDepositButtonPressed(
    CreatePillarQsrInfoData qsrInfo,
  ) {
    final BigInt qsrAmount = _qsrAmountController.text.extractDecimals(
      coinDecimals,
    );

    final bool isQsrAvailableToDeposit = qsrAmount > BigInt.zero;

    final bool willDepositExceedCost =
        qsrInfo.deposit + _maxQsrAmount > qsrInfo.cost;

    final bool canDepositBeExecuted =
        isQsrAvailableToDeposit && !willDepositExceedCost;

    if (canDepositBeExecuted) {
      context.read<PillarDepositQsrBloc>().add(
        PillarDepositQsrRequested(
          address: Address.parse(_addressController.text),
          amount: qsrAmount,
        ),
      );
    }
  }

  void _onDeployPressed() {
    if (_lastCompletedStep == _PillarStepperStep.znnManagement) {
      context.read<DeployPillarBloc>().add(
        DeployPillarRequested(
          pillarName: _pillarNameController.text,
          rewardAddress: Address.parse(_pillarRewardAddressController.text),
          blockProducingAddress: Address.parse(
            _pillarMomentumController.text,
          ),
          giveBlockRewardPercentage: _momentumRewardPercentageGiven.toInt(),
          giveDelegateRewardPercentage: _delegateRewardPercentageGiven.toInt(),
        ),
      );
    }
  }

  void _onWithdrawButtonPressed(
    BigInt qsrDeposit,
  ) {
    if (qsrDeposit > BigInt.zero) {
      context.read<PillarWithdrawQsrBloc>().add(
        PillarWithdrawQsrRequested(
          address: Address.parse(_addressController.text),
        ),
      );
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
                                unawaited(
                                  NavigationUtils.openUrl(kZnnController),
                                );
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
      _pillarNameError == null &&
      _pillarRewardAddressError == null &&
      _pillarMomentumError == null;

  bool _hasQsrBalance(AccountInfo accountInfo) =>
      accountInfo.qsr()! > BigInt.zero;

  String? _qsrAmountValidator(String? value) => InputValidators.correctValue(
    value,
    _maxQsrAmount,
    kQsrCoin.decimals,
    BigInt.one,
    canBeEqualToMin: true,
  );

  void _onQsrNextPressed() {
    _saveProgressAndNavigateToNextStep(_PillarStepperStep.qsrManagement);
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
    }
    context.read<CreatePillarQsrInfoBloc>().add(
      FetchRequestData(address: Address.parse(_addressController.text)),
    );
  }

  Widget _buildPillarMomentumRewardsStepContent() {
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
