import 'package:flutter/material.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class AvailableBalance extends StatelessWidget {
  final Token token;
  final AccountInfo accountInfo;

  const AvailableBalance(
    this.token,
    this.accountInfo, {
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      '${accountInfo.getBalanceWithDecimals(
        token.tokenStandard,
      )} '
      '${token.symbol} available',
      style: Theme.of(context).inputDecorationTheme.hintStyle,
    );
  }
}
