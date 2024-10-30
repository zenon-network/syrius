import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/balance/balance.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/cubits/timer_cubit.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// A [BalancePopulated] widget that displays balance data once it has been
/// successfully fetched and populated.
///
/// This widget is displayed when the [BalanceCubit] is in the
/// [TimerStatus.success] state, and the balance data is available for
/// rendering.
class BalancePopulated extends StatefulWidget {
  /// Creates a BalancePopulated object.
  const BalancePopulated({
    required this.address,
    required this.accountInfo,
    super.key,
  });

  /// The balance data that has been successfully fetched.
  ///
  /// The data is a map where the key is a string (representing the account
  /// address), and the value is an [AccountInfo] object containing the balance
  /// details.
  final AccountInfo accountInfo;

  /// The address for which the [accountInfo] was retrieved.
  final String address;

  @override
  State<BalancePopulated> createState() => _BalancePopulatedState();
}

class _BalancePopulatedState extends State<BalancePopulated> {
  final ValueNotifier<String?> _touchedSectionId = ValueNotifier<String?>(null);
  late final ValueNotifier<Color> _addressEdgesColor;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _addressEdgesColor = ValueNotifier<Color>(Theme.of(context).hintColor);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        kVerticalSpacing,
        Expanded(
          child: AspectRatio(
            aspectRatio: 1,
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                return Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    BalanceChart(
                      accountInfo: widget.accountInfo,
                      hoveredSectionId: _touchedSectionId,
                    ),
                    ValueListenableBuilder<String?>(
                      valueListenable: _touchedSectionId,
                      builder: (_, String? id, __) {
                        final Widget center = id != null
                            ? _getBalance(
                                accountInfo: widget.accountInfo,
                                constraints: constraints,
                                tokenStandard: TokenStandard.parse(
                                    _touchedSectionId.value!),
                              )
                            : const SizedBox.shrink();

                        return center;
                      },
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        BalanceAddress(
          address: widget.address,
          edgesColorNotifier: _addressEdgesColor,
        ),
        const Divider(),
        Padding(
          padding: const EdgeInsets.all(8),
          child: BalanceChartLegend(accountInfo: widget.accountInfo),
        ),
      ],
    );
  }

  Widget _getBalance({
    required AccountInfo accountInfo,
    required BoxConstraints constraints,
    required TokenStandard tokenStandard,
  }) {
    final String amount = accountInfo
        .getBalance(
          tokenStandard,
        )
        .addDecimals(coinDecimals);

    final String symbol = tokenStandard == kZnnCoin.tokenStandard
        ? kZnnCoin.symbol
        : kQsrCoin.symbol;

    final double margin = constraints.maxWidth * 0.3;

    final double width = constraints.maxWidth - margin;

    return SizedBox(
      width: width,
      child: AutoSizeText(
        '$amount $symbol',
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.headlineMedium!.copyWith(
              color: ColorUtils.getTokenColor(tokenStandard),
              fontWeight: FontWeight.bold,
            ),
      ),
    );
  }
}
