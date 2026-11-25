import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';
import 'package:zenon_syrius_wallet_flutter/l10n/app_localizations.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/accelerator_donation_stepper/accelerator_donation_stepper.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/multiple_balance/multiple_balance.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/custom_material_stepper.dart'
    as custom_material_stepper;
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

enum _AcceleratorDonationStep {
  donationAddress,
  donationDetails,
  submitDonation,
}

/// Validates an optional Accelerator amount field against [maxValue].
///
/// Unlike [InputValidators.correctValue] alone, this rejects non-zero inputs
/// even when [maxValue] is zero.
String? validateAcceleratorAmount({
  required String? value,
  required BigInt maxValue,
  required int decimals,
  required BigInt minValue,
  bool canBeBlank = false,
  AppLocalizations? l10n,
}) {
  if (value == null || value.isEmpty) {
    return canBeBlank
        ? null
        : (l10n?.enterValidAmount ?? 'Enter a valid amount');
  }
  if (value.contains('.') && value.split('.')[1].length > decimals) {
    return l10n?.inputtedNumberHasTooManyDecimals ??
        'Inputted number has too many decimals';
  }
  final BigInt parsedAmount;
  try {
    parsedAmount = value.extractDecimals(decimals);
  } on Object {
    return l10n?.error ?? 'Error';
  }
  if (maxValue == BigInt.zero) {
    if (parsedAmount == BigInt.zero && minValue == BigInt.zero) {
      return null;
    }
    return l10n?.valueMustBeZero ?? 'Value must be 0';
  }
  return InputValidators.correctValue(
    value,
    maxValue,
    decimals,
    minValue,
    canBeEqualToMin: true,
    canBeBlank: canBeBlank,
  );
}

/// Returns whether the provided ZNN and QSR donation inputs are valid and
/// donate a strictly positive combined amount within the available balances.
bool areDonationInputsValid({
  required String znnInput,
  required String qsrInput,
  required BigInt znnBalance,
  required BigInt qsrBalance,
}) {
  final String? znnError = validateAcceleratorAmount(
    value: znnInput,
    maxValue: znnBalance,
    decimals: coinDecimals,
    minValue: BigInt.zero,
    canBeBlank: true,
  );
  final String? qsrError = validateAcceleratorAmount(
    value: qsrInput,
    maxValue: qsrBalance,
    decimals: coinDecimals,
    minValue: BigInt.zero,
    canBeBlank: true,
  );
  if (znnError != null || qsrError != null) {
    return false;
  }

  final BigInt znnAmount = znnInput.isNotEmpty
      ? znnInput.extractDecimals(coinDecimals)
      : BigInt.zero;
  final BigInt qsrAmount = qsrInput.isNotEmpty
      ? qsrInput.extractDecimals(coinDecimals)
      : BigInt.zero;

  return znnAmount <= znnBalance &&
      qsrAmount <= qsrBalance &&
      (znnAmount > BigInt.zero || qsrAmount > BigInt.zero);
}

/// Guides the user through donating ZNN and/or QSR to Accelerator-Z.
class AcceleratorDonationStepperView extends StatefulWidget {
  /// Creates an [AcceleratorDonationStepperView].
  const AcceleratorDonationStepperView({this._onDonationSubmitted, super.key});

  final VoidCallback? _onDonationSubmitted;

  @override
  State<AcceleratorDonationStepperView> createState() =>
      _AcceleratorDonationStepperViewState();
}

class _AcceleratorDonationStepperViewState
    extends State<AcceleratorDonationStepperView> {
  _AcceleratorDonationStep? _lastCompletedStep;
  _AcceleratorDonationStep _currentStep = _AcceleratorDonationStep.values.first;

  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _znnAmountController = TextEditingController();
  final TextEditingController _qsrAmountController = TextEditingController();

  final GlobalKey<FormState> _znnAmountKey = GlobalKey<FormState>();
  final GlobalKey<FormState> _qsrAmountKey = GlobalKey<FormState>();
  final GlobalKey<LoadingButtonState> _submitButtonKey =
      GlobalKey<LoadingButtonState>();

  BigInt _znnAmount = BigInt.zero;
  BigInt _qsrAmount = BigInt.zero;

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
    return BlocListener<SubmitDonationBloc, SubmitDonationState>(
      listener: _onSubmitDonationStateChanged,
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

  void _onSubmitDonationStateChanged(
    BuildContext context,
    SubmitDonationState state,
  ) {
    switch (state) {
      case SubmitDonationInitial():
        break;
      case SubmitDonationLoading():
        _submitButtonKey.currentState?.animateForward();
      case SubmitDonationDone():
        _submitButtonKey.currentState?.animateReverse();
        widget._onDonationSubmitted?.call();
        setState(() {
          _lastCompletedStep = _AcceleratorDonationStep.values.last;
        });
      case SubmitDonationFailure(
        :final SyriusException exception,
        :final List<AccountBlockTemplate> sentBlocks,
        :final bool znnSubmitted,
      ):
        _submitButtonKey.currentState?.animateReverse();
        if (sentBlocks.isNotEmpty) {
          widget._onDonationSubmitted?.call();
        }
        if (znnSubmitted) {
          setState(() {
            _znnAmount = BigInt.zero;
            _znnAmountController.clear();
          });
        }
        final Object errorPayload = znnSubmitted
            ? context.l10n.znnDonationSubmittedQsrFailed
            : exception is InvalidDonationAmountException
            ? context.l10n.donationAmountMustBePositive
            : exception;
        unawaited(
          NotificationUtils.sendNotificationError(
            errorPayload,
            context.l10n.errorSubmittingDonation,
          ),
        );
    }
  }

  Widget _buildLoadedBody(BuildContext context, AccountInfo? accountInfo) {
    if (accountInfo == null) {
      return SyriusErrorWidget(context.l10n.balanceUnavailableForAddress);
    }
    return _buildWidgetBody(context, accountInfo);
  }

  Widget _buildWidgetBody(BuildContext context, AccountInfo accountInfo) {
    final bool isCompleted =
        _lastCompletedStep == _AcceleratorDonationStep.values.last;

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
                  label: context.l10n.makeAnotherDonation,
                  onPressed: _resetStepper,
                  iconData: Icons.refresh,
                ),
                const SizedBox(width: 75),
                StepperButton(
                  text: context.l10n.returnToProjectList,
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

  void _resetStepper() {
    _znnAmountController.clear();
    _qsrAmountController.clear();
    _znnAmount = BigInt.zero;
    _qsrAmount = BigInt.zero;
    setState(() {
      _currentStep = _AcceleratorDonationStep.values.first;
      _lastCompletedStep = null;
    });
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
            stepTitle: context.l10n.donationAddress,
            stepContent: _buildDonationAddressStepContent(context, accountInfo),
            stepSubtitle: _addressController.text,
            stepState: StepperUtils.getStepState(
              _AcceleratorDonationStep.donationAddress.index,
              _lastCompletedStep?.index,
            ),
            context: context,
          ),
          StepperUtils.getMaterialStep(
            stepTitle: context.l10n.donationDetails,
            stepContent: _buildDonationDetailsStepContent(context, accountInfo),
            stepSubtitle: _formatDonationDetailsSubtitle(),
            stepState: StepperUtils.getStepState(
              _AcceleratorDonationStep.donationDetails.index,
              _lastCompletedStep?.index,
            ),
            context: context,
          ),
          StepperUtils.getMaterialStep(
            stepTitle: context.l10n.submitDonation,
            stepContent: _buildSubmitDonationStepContent(context),
            stepSubtitle: context.l10n.donationSubmitted,
            stepState: StepperUtils.getStepState(
              _AcceleratorDonationStep.submitDonation.index,
              _lastCompletedStep?.index,
            ),
            context: context,
          ),
        ],
      ),
    );
  }

  String _formatDonationDetailsSubtitle() {
    final String znnPrefix = _znnAmountController.text.isNotEmpty
        ? '${_znnAmountController.text} ${kZnnCoin.symbol}'
        : '';
    final String qsrSuffix = _qsrAmountController.text.isNotEmpty
        ? '${_qsrAmountController.text} ${kQsrCoin.symbol}'
        : '';
    final String splitter = znnPrefix.isNotEmpty && qsrSuffix.isNotEmpty
        ? ' ● '
        : '';

    return znnPrefix + splitter + qsrSuffix;
  }

  Widget _buildDonationAddressStepContent(
    BuildContext context,
    AccountInfo accountInfo,
  ) {
    final BigInt znnBalance = accountInfo.znn() ?? BigInt.zero;
    final BigInt qsrBalance = accountInfo.qsr() ?? BigInt.zero;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        DisabledAddressField(_addressController),
        Row(
          children: <Widget>[
            StepperUtils.getBalanceWidget(kZnnCoin, accountInfo),
            StepperUtils.getBalanceWidget(kQsrCoin, accountInfo),
          ],
        ),
        DottedBorderInfoWidget(
          text: context.l10n.allDonatedFundsGoToAccelerator,
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
              onPressed: znnBalance > BigInt.zero || qsrBalance > BigInt.zero
                  ? () {
                      setState(() {
                        _lastCompletedStep =
                            _AcceleratorDonationStep.donationAddress;
                        _currentStep = _AcceleratorDonationStep.donationDetails;
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

  Widget _buildDonationDetailsStepContent(
    BuildContext context,
    AccountInfo accountInfo,
  ) {
    final BigInt znnBalance = accountInfo.znn() ?? BigInt.zero;
    final BigInt qsrBalance = accountInfo.qsr() ?? BigInt.zero;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Text(context.l10n.totalDonationBudget),
            StandardTooltipIcon(context.l10n.yourDonationMatters, Icons.help),
          ],
        ),
        kVerticalSpacing,
        Form(
          key: _znnAmountKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: InputField(
            hintText: context.l10n.znnAmount,
            controller: _znnAmountController,
            suffixIcon: AmountSuffixWidgets(
              kZnnCoin,
              onMaxPressed: () {
                final BigInt maxZnn = accountInfo.getBalance(
                  kZnnCoin.tokenStandard,
                );
                if (_znnAmountController.text.isEmpty ||
                    _znnAmountController.text.extractDecimals(coinDecimals) <
                        maxZnn) {
                  setState(() {
                    _znnAmountController.text = maxZnn.addDecimals(
                      coinDecimals,
                    );
                  });
                }
              },
            ),
            validator: (String? value) => validateAcceleratorAmount(
              value: value,
              maxValue: znnBalance,
              decimals: coinDecimals,
              minValue: BigInt.zero,
              canBeBlank: true,
              l10n: context.l10n,
            ),
            onChanged: (String value) {
              setState(() {});
            },
            inputFormatters: FormatUtils.getAmountTextInputFormatters(
              _znnAmountController.text,
            ),
          ),
        ),
        StepperUtils.getBalanceWidget(kZnnCoin, accountInfo),
        Form(
          key: _qsrAmountKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: InputField(
            hintText: context.l10n.qsrAmount,
            controller: _qsrAmountController,
            suffixIcon: AmountSuffixWidgets(
              kQsrCoin,
              onMaxPressed: () {
                final BigInt maxQsr = accountInfo.getBalance(
                  kQsrCoin.tokenStandard,
                );
                if (_qsrAmountController.text.isEmpty ||
                    _qsrAmountController.text.extractDecimals(coinDecimals) <
                        maxQsr) {
                  setState(() {
                    _qsrAmountController.text = maxQsr.addDecimals(
                      coinDecimals,
                    );
                  });
                }
              },
            ),
            validator: (String? value) => validateAcceleratorAmount(
              value: value,
              maxValue: qsrBalance,
              decimals: coinDecimals,
              minValue: BigInt.zero,
              canBeBlank: true,
              l10n: context.l10n,
            ),
            onChanged: (String value) {
              setState(() {});
            },
            inputFormatters: FormatUtils.getAmountTextInputFormatters(
              _qsrAmountController.text,
            ),
          ),
        ),
        StepperUtils.getBalanceWidget(kQsrCoin, accountInfo),
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
              onPressed: _isInputValid(znnBalance, qsrBalance)
                  ? () {
                      setState(() {
                        _znnAmount = _znnAmountController.text.isNotEmpty
                            ? _znnAmountController.text.extractDecimals(
                                coinDecimals,
                              )
                            : BigInt.zero;
                        _qsrAmount = _qsrAmountController.text.isNotEmpty
                            ? _qsrAmountController.text.extractDecimals(
                                coinDecimals,
                              )
                            : BigInt.zero;
                        _lastCompletedStep =
                            _AcceleratorDonationStep.donationDetails;
                        _currentStep = _AcceleratorDonationStep.submitDonation;
                      });
                    }
                  : null,
            ),
          ],
        ),
      ],
    );
  }

  bool _isInputValid(BigInt znnBalance, BigInt qsrBalance) {
    return areDonationInputsValid(
      znnInput: _znnAmountController.text,
      qsrInput: _qsrAmountController.text,
      znnBalance: znnBalance,
      qsrBalance: qsrBalance,
    );
  }

  Widget _buildSubmitDonationStepContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        DottedBorderInfoWidget(
          text: context.l10n.thankYouForSupportingAccelerator,
        ),
        kVerticalSpacing,
        Row(
          children: <Widget>[
            StepperButton(
              onPressed: () {
                setState(() {
                  _currentStep = _AcceleratorDonationStep.donationDetails;
                  _lastCompletedStep = _AcceleratorDonationStep.donationAddress;
                });
              },
              text: context.l10n.goBack,
            ),
            const SizedBox(width: 15),
            LoadingButton.stepper(
              onPressed: () {
                context.read<SubmitDonationBloc>().add(
                  SubmitDonationRequested(
                    address: Address.parse(_addressController.text),
                    znnAmount: _znnAmount,
                    qsrAmount: _qsrAmount,
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

  @override
  void dispose() {
    _addressController.dispose();
    _znnAmountController.dispose();
    _qsrAmountController.dispose();
    super.dispose();
  }
}
