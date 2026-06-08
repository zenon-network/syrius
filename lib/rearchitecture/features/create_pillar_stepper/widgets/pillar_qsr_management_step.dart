import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/math_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// A note on how the max QSR that can be deposited is calculated.
///
/// The minimum value between available and needed QSR to cover the cost
///
/// For example: if 100 is available to be deposited, and only 25 needed,
/// then this variable is equal to 25
///
/// If 100 more QSR is needed, and 100 is available, then variable is equal
/// to 100
///
class PillarQsrManagementStep extends StatefulWidget {
  /// Creates a [PillarQsrManagementStep].
  const PillarQsrManagementStep({
    required this.accountInfo,
    required this.addressController,
    required this.onNextPressed,
    required this.qsrAmountController,
    super.key,
  });

  /// Account balances for the selected address.
  final AccountInfo accountInfo;

  /// Selected address controller displayed by the disabled address field.
  final TextEditingController addressController;

  /// Controller containing the QSR amount to deposit.
  final TextEditingController qsrAmountController;

  /// Called when the user can continue to the next step.
  final VoidCallback onNextPressed;

  @override
  State<PillarQsrManagementStep> createState() =>
      _PillarQsrManagementStepState();
}

class _PillarQsrManagementStepState extends State<PillarQsrManagementStep> {
  final GlobalKey<LoadingButtonState> _depositQsrButtonKey = GlobalKey();
  final GlobalKey<LoadingButtonState> _withdrawButtonKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<
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
                widget.accountInfo,
                state.data,
              ),
          },
    );
  }

  Row _buildQsrManagementStepBody(
    BuildContext context,
    AccountInfo accountInfo,
    CreatePillarQsrInfoData qsrInfo,
  ) {
    final BigInt maxQsrAmount = MathUtils.bigMin(
      widget.accountInfo.getBalance(
        kQsrCoin.tokenStandard,
      ),
      MathUtils.bigMax(BigInt.zero, qsrInfo.cost - qsrInfo.deposit),
    );

    widget.qsrAmountController.text = maxQsrAmount.addDecimals(
      coinDecimals,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: _buildFields(
            accountInfo,
            context,
            qsrInfo,
            maxQsrAmount,
          ),
        ),
        kHorizontalGap45,
        Expanded(
          child: Visibility(
            visible: qsrInfo.deposit > BigInt.zero,
            child: _buildDepositedQsrInfo(context, qsrInfo),
          ),
        ),
      ],
    );
  }

  Card _buildDepositedQsrInfo(
    BuildContext context,
    CreatePillarQsrInfoData qsrInfo,
  ) {
    final double toBeDepositedValue =
        (qsrInfo.cost - qsrInfo.deposit) / qsrInfo.cost;

    final double depositedValue = qsrInfo.deposit / qsrInfo.cost;

    return Card.filled(
      color: context.themeData.inputDecorationTheme.fillColor,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
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
                          value: toBeDepositedValue,
                          color: AppColors.qsrColor.withAlpha(
                            (255 * 0.3).round(),
                          ),
                        ),
                        PieChartSectionData(
                          showTitle: false,
                          radius: 7,
                          value: depositedValue,
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
                  _WithdrawButton(
                    address: widget.addressController.text,
                    onDone: _refreshPillarQsrInfo,
                    loadingKey: _withdrawButtonKey,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFields(
    AccountInfo accountInfo,
    BuildContext context,
    CreatePillarQsrInfoData qsrInfo,
    BigInt maxQsrAmount,
  ) {
    final bool qsrCostCovered = qsrInfo.deposit >= qsrInfo.cost;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        DisabledAddressField(widget.addressController),
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
        if (!qsrCostCovered) _buildQsrAmountField(context, maxQsrAmount),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 25),
          child: DottedBorderInfoWidget(
            borderColor: AppColors.qsrColor,
            text: context.l10n.depositedCoinWillBurn(kQsrCoin.symbol),
          ),
        ),
        if (!qsrCostCovered)
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: widget.qsrAmountController,
            builder: (_, TextEditingValue value, _) {
              return _DepositButton(
                onDepositDone: _refreshPillarQsrInfo,
                qsrAmountText: value.text,
                depositAddress: widget.addressController.text,
                accountInfo: accountInfo,
                qsrInfo: qsrInfo,
                depositQsrButtonKey: _depositQsrButtonKey,
                isQsrAmountValid:
                    _qsrAmountValidator(
                      value: value.text,
                      maxQsrAmount: maxQsrAmount,
                    ) ==
                    null,
              );
            },
          ),
        if (qsrCostCovered)
          OutlinedButton(
            onPressed: widget.onNextPressed,
            child: Text(context.l10n.next),
          ),
      ],
    );
  }

  Column _buildQsrAmountField(BuildContext context, BigInt maxQsrAmount) {
    return Column(
      children: <Widget>[
        kVerticalSpacing,
        TextFormField(
          autovalidateMode: AutovalidateMode.always,
          controller: widget.qsrAmountController,
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
          inputFormatters: FormatUtils.getAmountTextInputFormatters(
            widget.qsrAmountController.text,
          ),
          style: const TextStyle(
            color: AppColors.qsrColor,
          ),
          validator: (String? value) => _qsrAmountValidator(
            maxQsrAmount: maxQsrAmount,
            value: value,
          ),
        ),
      ],
    );
  }

  String? _qsrAmountValidator({
    required BigInt maxQsrAmount,
    required String? value,
  }) => InputValidators.correctValue(
    value,
    maxQsrAmount,
    kQsrCoin.decimals,
    BigInt.one,
    canBeEqualToMin: true,
  );

  void _refreshPillarQsrInfo() {
    context.read<CreatePillarQsrInfoBloc>().add(
      FetchRequestData(
        address: Address.parse(widget.addressController.text),
      ),
    );
  }
}

class _DepositButton extends StatelessWidget {
  const _DepositButton({
    required this.onDepositDone,
    required this.qsrAmountText,
    required this.depositAddress,
    required this.accountInfo,
    required this.qsrInfo,
    required this.depositQsrButtonKey,
    required this.isQsrAmountValid,
  });

  final AccountInfo accountInfo;
  final GlobalKey<LoadingButtonState> depositQsrButtonKey;
  final CreatePillarQsrInfoData qsrInfo;
  final String qsrAmountText;
  final String depositAddress;
  final VoidCallback onDepositDone;
  final bool isQsrAmountValid;

  @override
  Widget build(BuildContext context) {
    return BlocListener<PillarDepositQsrBloc, PillarDepositQsrState>(
      listener: (_, PillarDepositQsrState state) {
        if (state is PillarDepositQsrDone) {
          depositQsrButtonKey.currentState?.animateReverse();
          onDepositDone();
        } else if (state is PillarDepositQsrLoading) {
          depositQsrButtonKey.currentState?.animateForward();
        } else if (state is PillarDepositQsrFailure) {
          depositQsrButtonKey.currentState?.animateReverse();
          unawaited(
            NotificationUtils.sendNotificationError(
              state.exception,
              context.l10n.errorWhileDepositing(kQsrCoin.symbol),
            ),
          );
        }
      },
      child: LoadingButton(
        key: depositQsrButtonKey,
        text: context.l10n.deposit,
        onPressed: _hasQsrBalance(accountInfo) && isQsrAmountValid
            ? () => _onDepositButtonPressed(context: context, qsrInfo: qsrInfo)
            : null,
        outlineColor: AppColors.qsrColor,
        textStyle: const TextStyle(
          color: AppColors.qsrColor,
        ),
      ),
    );
  }

  bool _hasQsrBalance(AccountInfo accountInfo) =>
      accountInfo.qsr()! > BigInt.zero;

  void _onDepositButtonPressed({
    required BuildContext context,
    required CreatePillarQsrInfoData qsrInfo,
  }) {
    final BigInt qsrAmount = qsrAmountText.extractDecimals(
      coinDecimals,
    );

    final bool isQsrAvailableToDeposit = qsrAmount > BigInt.zero;

    final bool willDepositExceedCost =
        qsrInfo.deposit + qsrAmount > qsrInfo.cost;

    final bool canDepositBeExecuted =
        isQsrAvailableToDeposit && !willDepositExceedCost;

    if (canDepositBeExecuted) {
      context.read<PillarDepositQsrBloc>().add(
        PillarDepositQsrRequested(
          address: Address.parse(depositAddress),
          amount: qsrAmount,
        ),
      );
    }
  }
}

class _WithdrawButton extends StatelessWidget {
  const _WithdrawButton({
    required this.address,
    required this.onDone,
    required this.loadingKey,
  });

  final GlobalKey<LoadingButtonState> loadingKey;
  final VoidCallback onDone;
  final String address;

  @override
  Widget build(BuildContext context) {
    return BlocListener<PillarWithdrawQsrBloc, PillarWithdrawQsrState>(
      listener: (_, PillarWithdrawQsrState state) {
        if (state is PillarWithdrawQsrLoading) {
          loadingKey.currentState?.animateForward();
        } else if (state is PillarWithdrawQsrFailure) {
          loadingKey.currentState?.animateReverse();
          unawaited(
            NotificationUtils.sendNotificationError(
              state.exception,
              context.l10n.errorWhileWithdrawing(kQsrCoin.symbol),
            ),
          );
        } else if (state is PillarWithdrawQsrPopulated) {
          loadingKey.currentState?.animateReverse();
          onDone();
        }
      },
      child: LoadingButton(
        text: context.l10n.withdraw,
        onPressed: () => _onWithdrawButtonPressed(context: context),
        key: loadingKey,
        outlineColor: AppColors.qsrColor,
        textStyle: const TextStyle(
          color: AppColors.qsrColor,
        ),
      ),
    );
  }

  void _onWithdrawButtonPressed({
    required BuildContext context,
  }) {
    context.read<PillarWithdrawQsrBloc>().add(
      PillarWithdrawQsrRequested(
        address: Address.parse(address),
      ),
    );
  }
}
