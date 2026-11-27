import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// Displays the available balance for a given [token] and [accountInfo].
class AvailableBalance extends StatelessWidget {
  /// Creates an [AvailableBalance] widget.
  const AvailableBalance(
    this.token,
    this.accountInfo, {
    super.key,
    this.padding = EdgeInsets.zero,
  });

  /// Creates an [AvailableBalance] widget with default stepper padding.
  const AvailableBalance.stepper(
    this.token,
    this.accountInfo, {
    super.key,
    this.padding = const EdgeInsets.only(left: 20, top: 10, bottom: 10),
  });

  /// The token whose balance is displayed.
  final Token token;

  /// The account information providing the balance.
  final AccountInfo accountInfo;

  /// Padding applied around the balance text.
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Text(
        textAlign: TextAlign.start,
        '${accountInfo.getBalance(
          token.tokenStandard,
        ).addDecimals(token.decimals)} '
        '${token.symbol} available',
        style: Theme.of(context).inputDecorationTheme.hintStyle,
      ),
    );
  }
}
