import 'dart:async';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/math_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// QSR management step for the sentinel creation flow.
class SentinelQsrManagementStep extends StatefulWidget {
  /// Creates a [SentinelQsrManagementStep].
  const SentinelQsrManagementStep({
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
  State<SentinelQsrManagementStep> createState() =>
      _SentinelQsrManagementStepState();
}

class _SentinelQsrManagementStepState extends State<SentinelQsrManagementStep> {
  final GlobalKey<LoadingButtonState> _depositQsrButtonKey = GlobalKey();
  final GlobalKey<LoadingButtonState> _withdrawButtonKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<
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
                widget.accountInfo,
                state.data,
              ),
          },
    );
  }

  Row _buildQsrManagementStepBody(
    BuildContext context,
    AccountInfo accountInfo,
    CreateSentinelQsrInfoData qsrInfo,
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
    CreateSentinelQsrInfoData qsrInfo,
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
                  _WithdrawButton(
                    address: widget.addressController.text,
                    loadingKey: _withdrawButtonKey,
                    onDone: _refreshSentinelQsrInfo,
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
    CreateSentinelQsrInfoData qsrInfo,
    BigInt maxQsrAmount,
  ) {
    final bool qsrCostCovered = qsrInfo.deposit >= qsrInfo.cost;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        DisabledAddressField(widget.addressController),
        kVerticalSpacing,
        DottedBorderInfoWidget(
          borderColor: AppColors.qsrColor,
          text: context.l10n.cannotReuseAddressForSentinel,
        ),
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
                style: Theme.of(context).inputDecorationTheme.hintStyle,
              ),
            ],
          ),
        ),
        if (!qsrCostCovered) _buildQsrAmountField(context, maxQsrAmount),
        kVerticalGap25,
        DottedBorderInfoWidget(
          borderColor: AppColors.qsrColor,
          text: context.l10n.disassembleSentinelToUnlockCoin(kQsrCoin.symbol),
        ),
        kVerticalGap25,
        if (!qsrCostCovered)
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: widget.qsrAmountController,
            builder: (_, TextEditingValue value, _) {
              return _DepositButton(
                loadingKey: _depositQsrButtonKey,
                onDone: _refreshSentinelQsrInfo,
                onPressed:
                    _canDeposit(
                      accountInfo: accountInfo,
                      maxQsrAmount: maxQsrAmount,
                      qsrAmountText: value.text,
                    )
                    ? () => _onDepositButtonPressed(
                        qsrAmountText: value.text,
                        qsrInfo: qsrInfo,
                      )
                    : null,
              );
            },
          ),
        if (qsrCostCovered)
          KeyedSubtree(
            key: const Key('sentinel_qsr_next_button'),
            child: OutlinedButton(
              onPressed: widget.onNextPressed,
              child: Text(context.l10n.next),
            ),
          ),
      ],
    );
  }

  Column _buildQsrAmountField(BuildContext context, BigInt maxQsrAmount) {
    return Column(
      children: <Widget>[
        kVerticalSpacing,
        TextFormField(
          key: const Key('sentinel_qsr_amount_field'),
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

  void _refreshSentinelQsrInfo() {
    sl.get<MultipleBalanceBloc>().add(
      MultipleBalanceFetch(
        addresses: kDefaultAddressList.map((String? e) => e!).toList(),
      ),
    );
    context.read<CreateSentinelQsrInfoBloc>().add(
      FetchRequestData(
        address: Address.parse(widget.addressController.text),
      ),
    );
  }

  bool _canDeposit({
    required AccountInfo accountInfo,
    required BigInt maxQsrAmount,
    required String qsrAmountText,
  }) =>
      _hasQsrBalance(accountInfo) &&
      _qsrAmountValidator(
            value: qsrAmountText,
            maxQsrAmount: maxQsrAmount,
          ) ==
          null;

  bool _hasQsrBalance(AccountInfo accountInfo) =>
      accountInfo.qsr()! > BigInt.zero;

  void _onDepositButtonPressed({
    required String qsrAmountText,
    required CreateSentinelQsrInfoData qsrInfo,
  }) {
    final BigInt qsrAmount = qsrAmountText.extractDecimals(
      coinDecimals,
    );

    context.read<SentinelDepositQsrBloc>().add(
      SentinelDepositQsrRequested(
        address: Address.parse(widget.addressController.text),
        amount: qsrAmount,
      ),
    );
  }
}

class _DepositButton extends StatelessWidget {
  const _DepositButton({
    required this.loadingKey,
    required this.onDone,
    required this.onPressed,
  });

  final GlobalKey<LoadingButtonState> loadingKey;
  final VoidCallback onDone;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return BlocListener<SentinelDepositQsrBloc, SentinelDepositQsrState>(
      listener: (_, SentinelDepositQsrState state) {
        if (state is SentinelDepositQsrDone) {
          loadingKey.currentState?.animateReverse();
          onDone();
        } else if (state is SentinelDepositQsrLoading) {
          loadingKey.currentState?.animateForward();
        } else if (state is SentinelDepositQsrFailure) {
          loadingKey.currentState?.animateReverse();
          unawaited(
            NotificationUtils.sendNotificationError(
              state.exception,
              context.l10n.errorWhileDepositing(kQsrCoin.symbol),
            ),
          );
        }
      },
      child: KeyedSubtree(
        key: const Key('sentinel_qsr_deposit_button'),
        child: LoadingButton(
          key: loadingKey,
          text: context.l10n.deposit,
          onPressed: onPressed,
          outlineColor: AppColors.qsrColor,
          // TODO(maznnwell): make sure that the outline and text colors are the same
          textStyle: const TextStyle(
            color: AppColors.qsrColor,
          ),
        ),
      ),
    );
  }
}

class _WithdrawButton extends StatelessWidget {
  const _WithdrawButton({
    required this.address,
    required this.loadingKey,
    required this.onDone,
  });

  final String address;
  final GlobalKey<LoadingButtonState> loadingKey;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return BlocListener<SentinelWithdrawQsrBloc, SentinelWithdrawQsrState>(
      listener: (_, SentinelWithdrawQsrState state) {
        if (state is SentinelWithdrawQsrLoading) {
          loadingKey.currentState?.animateForward();
        } else if (state is SentinelWithdrawQsrFailure) {
          loadingKey.currentState?.animateReverse();
          unawaited(
            NotificationUtils.sendNotificationError(
              state.exception,
              context.l10n.errorWhileWithdrawing(kQsrCoin.symbol),
            ),
          );
        } else if (state is SentinelWithdrawQsrPopulated) {
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

  void _onWithdrawButtonPressed({required BuildContext context}) {
    context.read<SentinelWithdrawQsrBloc>().add(
      SentinelWithdrawQsrRequested(
        address: Address.parse(address),
      ),
    );
  }
}
