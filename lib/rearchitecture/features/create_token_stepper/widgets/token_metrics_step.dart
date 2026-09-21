import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// Step that collects token decimal and supply metrics.
class TokenMetricsStep extends StatefulWidget {
  /// Creates a [TokenMetricsStep].
  const TokenMetricsStep({
    required this.maxSupplyController,
    required this.onBackPressed,
    required this.onContinuePressed,
    required this.tokenData,
    required this.totalSupplyController,
    super.key,
  });

  /// Controller for max supply input.
  final TextEditingController maxSupplyController;

  /// Called when the user wants to go back.
  final VoidCallback onBackPressed;

  /// Called when the user can continue.
  final VoidCallback onContinuePressed;

  /// Token data draft updated by this step.
  final ValueNotifier<NewTokenData> tokenData;

  /// Controller for total supply input.
  final TextEditingController totalSupplyController;

  @override
  State<TokenMetricsStep> createState() => _TokenMetricsStepState();
}

class _TokenMetricsStepState extends State<TokenMetricsStep> {
  String get _maxSupply => widget.maxSupplyController.text;

  bool get _isMintable => widget.tokenData.value.isMintable;

  int get _decimals => widget.tokenData.value.decimals;

  String? get _maxSupplyError =>
      _isMintable
          ? InputValidators.correctValue(
        _maxSupply,
        kBigP255m1,
        _decimals,
        kMinTokenTotalMaxSupply,
        canBeEqualToMin: true,
      )
          : InputValidators.isMaxSupplyZero(_maxSupply);

  String get _totalSupply => widget.totalSupplyController.text;

  String? get _totalSupplyError =>
      InputValidators.correctValue(
        _totalSupply,
        _isMintable
            ? _maxSupply.isNotEmpty
            ? _maxSupply.extractDecimals(
          _decimals,
        )
            : kBigP255m1
            : kBigP255m1,
        _decimals,
        _isMintable ? BigInt.zero : kMinTokenTotalMaxSupply,
        canBeEqualToMin: true,
      );

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        CustomSlider(
          activeColor: AppColors.ztsColor,
          description: context.l10n.numberOfDecimals(
            _decimals,
          ),
          startValue: 0,
          min: 0,
          maxValue: 18,
          sliderKey: const Key('token_decimals_slider'),
          callback: (double value) {
            widget.tokenData.value = widget.tokenData.value.copyWith(
              decimals: value.toInt(),
            );
          },
        ),
        kVerticalGap16,
        Visibility(
          visible: _isMintable,
          child: Column(
            children: <Widget>[
              TextField(
                key: const Key('token_max_supply_field'),
                inputFormatters: FormatUtils.getAmountTextInputFormatters(
                  widget.maxSupplyController.text,
                ),
                controller: widget.maxSupplyController,
                decoration: InputDecoration(
                  errorText: _maxSupply.isNotEmpty ? _maxSupplyError : null,
                  hintText: context.l10n.maxSupply,
                ),
              ),
              kVerticalGap16,
            ],
          ),
        ),
        TextField(
          key: const Key('token_total_supply_field'),
          inputFormatters: FormatUtils.getAmountTextInputFormatters(
            widget.totalSupplyController.text,
          ),
          controller: widget.totalSupplyController,
          decoration: InputDecoration(
            errorText: _totalSupply.isNotEmpty ? _totalSupplyError : null,
            hintText: context.l10n.totalSupply,
          ),
        ),
        kVerticalGap16,
        Row(
          children: <Widget>[
            StepperButton(
              text: context.l10n.goBack,
              onPressed: widget.onBackPressed,
            ),
            kHorizontalGap25,
            ListenableBuilder(
              listenable: Listenable.merge(<Listenable>[
                widget.totalSupplyController,
                widget.maxSupplyController,
              ]),
              builder: (_, _) =>
                  StepperButton(
                    key: const Key('token_metrics_next_button'),
                    text: context.l10n.continueText,
                    onPressed: _areTokenMetricsCorrect()
                        ? _onContinuePressed
                        : null,
                  ),
            ),
          ],
        ),
      ],
    );
  }

  bool _areTokenMetricsCorrect() =>
      (!_isMintable || _maxSupplyError == null) && _totalSupplyError == null;

  void _onContinuePressed() {
    widget.tokenData.value = widget.tokenData.value.copyWith(
      decimals: _decimals,
      maxSupply: _isMintable
          ? _maxSupply.extractDecimals(_decimals)
          : _totalSupply.extractDecimals(_decimals),
      totalSupply: _totalSupply.extractDecimals(_decimals),
    );
    widget.onContinuePressed();
  }
}
