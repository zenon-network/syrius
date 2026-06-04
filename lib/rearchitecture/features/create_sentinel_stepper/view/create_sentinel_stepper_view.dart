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
import 'package:zenon_syrius_wallet_flutter/utils/math_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/custom_material_stepper.dart'
    as custom_material_stepper;
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

enum _SentinelStepperStep {
  checkPlasma,
  qsrManagement,
  znnManagement,
  deploySentinel,
}

/// A stepper that guides the user through creating a sentinel.
class CreateSentinelStepperView extends StatefulWidget {
  /// {@macro default_constructor}
  const CreateSentinelStepperView({super.key});

  @override
  State<CreateSentinelStepperView> createState() => _MainSentinelState();
}

class _MainSentinelState extends State<CreateSentinelStepperView> {
  _SentinelStepperStep _currentStep = _SentinelStepperStep.checkPlasma;
  _SentinelStepperStep? _lastCompletedStep;

  bool get _hasSentinelBeenRegistered =>
      _lastCompletedStep == _SentinelStepperStep.deploySentinel;

  final TextEditingController _qsrAmountController = TextEditingController();
  final TextEditingController _znnAmountController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  final GlobalKey<LoadingButtonState> _depositQsrButtonKey = GlobalKey();
  final GlobalKey<LoadingButtonState> _withdrawButtonKey = GlobalKey();
  final GlobalKey<LoadingButtonState> _registerButtonKey = GlobalKey();

  BigInt _maxQsrAmount = BigInt.zero;

  @override
  void initState() {
    super.initState();
    _znnAmountController.text = sentinelRegisterZnnAmount.addDecimals(
      coinDecimals,
    );
    _addressController.text = kSelectedAddress!;
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
        MultipleBalanceStatus.success => _buildWidgetBody(
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
      CreateSentinelQsrInfoBloc,
      FetchState<CreateSentinelQsrInfoData>
    >(
      builder: (_, FetchState<CreateSentinelQsrInfoData> state) =>
          switch (state) {
            FetchFailure<CreateSentinelQsrInfoData>() => SyriusErrorWidget(
              state.exception,
            ),
            FetchInitial<CreateSentinelQsrInfoData>() => const Padding(
              padding: EdgeInsets.all(8),
              child: SyriusLoadingWidget(),
            ),
            FetchPopulated<CreateSentinelQsrInfoData>() =>
              _buildQsrManagementStepBody(
                context,
                accountInfo,
                state.data,
              ),
          },
      listener: (_, FetchState<CreateSentinelQsrInfoData> state) {
        if (state is FetchPopulated<CreateSentinelQsrInfoData>) {
          final CreateSentinelQsrInfoData data = state.data;

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
    CreateSentinelQsrInfoData qsrInfo,
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
                        AvailableBalance(kQsrCoin, accountInfo),
                        Text(
                          context.l10n.requiredForSentinelNode(
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
                      text: context.l10n.disassembleSentinelToUnlockCoin(
                        kQsrCoin.symbol,
                      ),
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
        const SizedBox(width: 45),
        Expanded(
          child: Visibility(
            visible: qsrInfo.deposit > BigInt.zero,
            child: Card.filled(
              color: context.themeData.inputDecorationTheme.fillColor,
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    Expanded(
                      child: Stack(
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
                              context.l10n.currentSentinelSlotFee(
                                qsrInfo.cost.addDecimals(coinDecimals),
                                kQsrCoin.symbol,
                              ),
                              textAlign: TextAlign.center,
                            ),
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
                          _buildWithdrawQsrButton(qsrInfo.deposit),
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
    CreateSentinelQsrInfoData qsrInfo,
  ) {
    return BlocListener<SentinelDepositQsrBloc, SentinelDepositQsrState>(
      listener: (_, SentinelDepositQsrState state) {
        if (state is SentinelDepositQsrDone) {
          _depositQsrButtonKey.currentState?.animateReverse();
          _refreshSentinelQsrInfo();
        } else if (state is SentinelDepositQsrLoading) {
          _depositQsrButtonKey.currentState?.animateForward();
        } else if (state is SentinelDepositQsrFailure) {
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

  void _refreshSentinelQsrInfo() {
    context.read<CreateSentinelQsrInfoBloc>().add(
      FetchRequestData(address: Address.parse(_addressController.text)),
    );
  }

  Widget _buildWithdrawQsrButton(BigInt qsrDeposit) {
    return BlocListener<SentinelWithdrawQsrBloc, SentinelWithdrawQsrState>(
      listener: (_, SentinelWithdrawQsrState state) {
        if (state is SentinelWithdrawQsrLoading) {
          _withdrawButtonKey.currentState?.animateForward();
        } else if (state is SentinelWithdrawQsrFailure) {
          _withdrawButtonKey.currentState?.animateReverse();
          unawaited(
            NotificationUtils.sendNotificationError(
              state.exception,
              context.l10n.errorWhileWithdrawing(kQsrCoin.symbol),
            ),
          );
        } else if (state is SentinelWithdrawQsrPopulated) {
          _withdrawButtonKey.currentState?.animateReverse();
          _saveProgressAndNavigateToNextStep(_SentinelStepperStep.checkPlasma);
          _refreshSentinelQsrInfo();
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
            stepTitle: context.l10n.sentinelDeployment,
            stepContent: _buildPlasmaCheckFutureBuilder(),
            stepSubtitle: context.l10n.sufficientPlasma,
            stepState: StepperUtils.getStepState(
              _SentinelStepperStep.checkPlasma.index,
              _lastCompletedStep?.index,
            ),
            context: context,
          ),
          StepperUtils.getMaterialStep(
            stepTitle: context.l10n.management(kQsrCoin.symbol),
            stepContent: _buildQsrManagementStep(context, accountInfo),
            stepSubtitle: context.l10n.deposited(kQsrCoin.symbol),
            stepState: StepperUtils.getStepState(
              _SentinelStepperStep.qsrManagement.index,
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
              _SentinelStepperStep.znnManagement.index,
              _lastCompletedStep?.index,
            ),
            context: context,
          ),
          StepperUtils.getMaterialStep(
            stepTitle: context.l10n.registerSentinel,
            stepContent: _buildDeploySentinelStepBody(context),
            stepSubtitle: context.l10n.sentinelRegistered,
            stepState: StepperUtils.getStepState(
              _SentinelStepperStep.deploySentinel.index,
              _lastCompletedStep?.index,
            ),
            context: context,
          ),
        ],
      ),
    );
  }

  Widget _buildDeploySentinelStepBody(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _buildDeployButton(),
        kVerticalGap25,
      ],
    );
  }

  Widget _buildDeployButton() {
    return BlocListener<DeploySentinelBloc, DeploySentinelState>(
      listener: (_, DeploySentinelState state) {
        if (state is DeploySentinelDone) {
          _registerButtonKey.currentState?.animateReverse();
          _saveProgressAndNavigateToNextStep(
            _SentinelStepperStep.deploySentinel,
          );
        } else if (state is DeploySentinelFailure) {
          _registerButtonKey.currentState?.animateReverse();
          unawaited(
            NotificationUtils.sendNotificationError(
              state.exception,
              context.l10n.errorDeployingSentinel,
            ),
          );
        } else if (state is DeploySentinelLoading) {
          _registerButtonKey.currentState?.animateForward();
        }
      },
      child: LoadingButton(
        text: context.l10n.register,
        onPressed: _onDeployPressed,
        key: _registerButtonKey,
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
          text: context.l10n.disassembleSentinelToUnlockCoin(kZnnCoin.symbol),
        ),
        kVerticalGap25,
        OutlinedButton(
          onPressed: _hasEnoughZnn(accountInfo)
              ? () {
                  _saveProgressAndNavigateToNextStep(
                    _SentinelStepperStep.znnManagement,
                  );
                }
              : null,
          child: Text(context.l10n.next),
        ),
      ],
    );
  }

  void _onDepositButtonPressed(CreateSentinelQsrInfoData qsrInfo) {
    final BigInt qsrAmount = _qsrAmountController.text.extractDecimals(
      coinDecimals,
    );

    final bool isQsrAvailableToDeposit = qsrAmount > BigInt.zero;
    final bool willDepositExceedCost =
        qsrInfo.deposit + qsrAmount > qsrInfo.cost;

    if (isQsrAvailableToDeposit && !willDepositExceedCost) {
      context.read<SentinelDepositQsrBloc>().add(
        SentinelDepositQsrRequested(
          address: Address.parse(_addressController.text),
          amount: qsrAmount,
        ),
      );
    }
  }

  void _onDeployPressed() {
    if (_lastCompletedStep == _SentinelStepperStep.znnManagement) {
      context.read<DeploySentinelBloc>().add(const DeploySentinelRequested());
    }
  }

  void _onWithdrawButtonPressed(BigInt qsrDeposit) {
    if (qsrDeposit > BigInt.zero) {
      context.read<SentinelWithdrawQsrBloc>().add(
        SentinelWithdrawQsrRequested(
          address: Address.parse(_addressController.text),
        ),
      );
    }
  }

  Widget _buildWidgetBody(BuildContext context, AccountInfo accountInfo) {
    return Stack(
      children: <Widget>[
        ListView(
          children: <Widget>[
            _buildMaterialStepper(context, accountInfo),
            Visibility(
              visible: _hasSentinelBeenRegistered,
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
                        Radius.circular(10),
                      ),
                    ),
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: Theme.of(context).textTheme.titleMedium,
                        children: <InlineSpan>[
                          TextSpan(
                            text: '${context.l10n.sentinel} ',
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
                            text: context.l10n.checkSentinelStatus,
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
                        child: _buildViewSentinelsButton(),
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
          visible: _hasSentinelBeenRegistered,
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

  Widget _buildViewSentinelsButton() {
    return OutlinedButton.icon(
      label: Text(context.l10n.viewSentinels),
      onPressed: () {
        Navigator.pop(context);
      },
      icon: const Icon(
        MaterialCommunityIcons.eye_outline,
        color: Colors.white,
      ),
      iconAlignment: .end,
    );
  }

  void _saveProgressAndNavigateToNextStep(_SentinelStepperStep completedStep) {
    setState(() {
      _lastCompletedStep = completedStep;
      if (!_hasSentinelBeenRegistered) {
        _currentStep = _SentinelStepperStep.values[completedStep.index + 1];
      }
    });
  }

  bool _hasEnoughZnn(AccountInfo accountInfo) =>
      accountInfo.znn()! >= sentinelRegisterZnnAmount;

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
    _saveProgressAndNavigateToNextStep(_SentinelStepperStep.qsrManagement);
  }

  Widget _buildPlasmaCheckFutureBuilder() {
    return FutureBuilder<PlasmaInfo?>(
      future: zenon!.embedded.plasma.get(Address.parse(kSelectedAddress!)),
      builder: (_, AsyncSnapshot<PlasmaInfo?> snapshot) {
        if (snapshot.hasError) {
          return SyriusErrorWidget(snapshot.error!);
        } else if (snapshot.hasData) {
          return _buildPlasmaCheckBody(snapshot.data!);
        }
        return const Padding(
          padding: EdgeInsets.all(8),
          child: SyriusLoadingWidget(),
        );
      },
    );
  }

  Widget _buildPlasmaCheckBody(PlasmaInfo plasmaInfo) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          context.l10n.morePlasmaRequired,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 25),
        Row(
          children: <Widget>[
            Expanded(
              child: DisabledAddressField(_addressController),
            ),
            const SizedBox(width: 25),
            PlasmaIcon(plasmaInfo),
          ],
        ),
        const SizedBox(height: 25),
        OutlinedButton(
          onPressed: plasmaInfo.currentPlasma >= kSentinelPlasmaAmountNeeded
              ? _onPlasmaCheckNextPressed
              : null,
          child: Text(context.l10n.next),
        ),
      ],
    );
  }

  void _onPlasmaCheckNextPressed() {
    if (_lastCompletedStep == null) {
      _saveProgressAndNavigateToNextStep(_SentinelStepperStep.checkPlasma);
    }
    _refreshSentinelQsrInfo();
  }

  @override
  void dispose() {
    _qsrAmountController.dispose();
    _znnAmountController.dispose();
    _addressController.dispose();
    super.dispose();
  }
}
