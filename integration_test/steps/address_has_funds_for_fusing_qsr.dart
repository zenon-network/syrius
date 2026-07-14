// BDD Usage comments intentionally mirror Gherkin placeholders.
// ignore_for_file: unintended_html_in_doc_comment, non_constant_identifier_names

import 'package:flutter_test/flutter_test.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart' as app;
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

import '../support/devnet_test_context.dart';

/// Usage: <fuse_address> address has funds for fusing <amount> QSR
Future<void> addressHasFundsForFusingQsr(
  WidgetTester tester,
  dynamic fuse_address,
  dynamic amount,
) async {
  final String fuseAddress = fuse_address as String;
  final BigInt fuseAmount = (amount as String).extractDecimals(coinDecimals);

  selectDevnetSender(fuseAddress);
  final AccountInfo accountInfo = await app.zenon!.ledger
      .getAccountInfoByAddress(Address.parse(fuseAddress));

  expect(
    fuseAmount,
    greaterThanOrEqualTo(fuseMinQsrAmount),
    reason: 'QSR fuse amount must be at least the protocol minimum',
  );
  expect(
    accountInfo.getBalance(qsrZts),
    greaterThanOrEqualTo(fuseAmount),
    reason: 'Fuse address does not have enough QSR for plasma fusion',
  );
}
