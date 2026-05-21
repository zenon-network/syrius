import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class AvailableBalance extends StatelessWidget {

  const AvailableBalance.stepper(
    this.token,
    this.accountInfo, {
    super.key,
    this.padding = const EdgeInsets.only(left: 20, top: 10, bottom: 10),
  });

  const AvailableBalance(
    this.token,
    this.accountInfo, {
    super.key,
    this.padding = EdgeInsets.zero,
  });

  final Token token;
  final AccountInfo accountInfo;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Text(
        '${accountInfo.getBalance(
          token.tokenStandard,
        ).addDecimals(token.decimals)} '
        '${token.symbol} available',
        style: Theme.of(context).inputDecorationTheme.hintStyle,
      ),
    );
  }
}
