import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// Step that collects token decimal and supply metrics.
class TokenMetricsStep extends StatefulWidget {
  /// Creates a [TokenMetricsStep].
  const TokenMetricsStep({
    required this.isMintable,
    required this.maxSupplyController,
    required this.onBackPressed,
    required this.onContinuePressed,
    required this.selectedNumDecimals,
    required this.totalSupplyController,
    super.key,
  });

  /// Whether max supply should be collected.
  final bool isMintable;

  /// Controller for max supply input.
  final TextEditingController maxSupplyController;

  /// Called when the user wants to go back.
  final VoidCallback onBackPressed;

  /// Called when the user can continue.
  final VoidCallback onContinuePressed;

  /// Selected decimal count.
  final ValueNotifier<int> selectedNumDecimals;

  /// Controller for total supply input.
  final TextEditingController totalSupplyController;

  @override
  State<TokenMetricsStep> createState() => _TokenMetricsStepState();
}

class _TokenMetricsStepState extends State<TokenMetricsStep> {
  String get _maxSupply => widget.maxSupplyController.text;

  String? get _maxSupplyError => widget.isMintable
      ? InputValidators.correctValue(
          _maxSupply,
          kBigP255m1,
          widget.selectedNumDecimals.value,
          kMinTokenTotalMaxSupply,
          canBeEqualToMin: true,
        )
      : InputValidators.isMaxSupplyZero(_maxSupply);

  String get _totalSupply => widget.totalSupplyController.text;

  String? get _totalSupplyError => InputValidators.correctValue(
    _totalSupply,
    widget.isMintable
        ? _maxSupply.isNotEmpty
              ? _maxSupply.extractDecimals(
                  widget.selectedNumDecimals.value,
                )
              : kBigP255m1
        : kBigP255m1,
    widget.selectedNumDecimals.value,
    widget.isMintable ? BigInt.zero : kMinTokenTotalMaxSupply,
    canBeEqualToMin: true,
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        ValueListenableBuilder<int>(
          valueListenable: widget.selectedNumDecimals,
          builder: (_, int value, _) {
            return CustomSlider(
              activeColor: AppColors.ztsColor,
              description: context.l10n.numberOfDecimals(
                value,
              ),
              startValue: 0,
              min: 0,
              maxValue: 18,
              callback: (double value) {
                widget.selectedNumDecimals.value = value.toInt();
              },
            );
          },
        ),
        kVerticalGap16,
        Visibility(
          visible: widget.isMintable,
          child: Column(
            children: <Widget>[
              TextField(
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
              builder: (_, _) => StepperButton(
                text: context.l10n.continueText,
                onPressed: _areTokenMetricsCorrect()
                    ? widget.onContinuePressed
                    : null,
              ),
            ),
          ],
        ),
      ],
    );
  }

  bool _areTokenMetricsCorrect() =>
      (!widget.isMintable || _maxSupplyError == null) &&
      _totalSupplyError == null;
}
