// BDD Usage comments intentionally mirror Gherkin placeholders.
// ignore_for_file: unintended_html_in_doc_comment

import 'package:flutter_test/flutter_test.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart' as app;
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

import '../support/devnet_test_context.dart';

/// Usage: <sender> address is selected for plasma fusion
Future<void> addressIsSelectedForPlasmaFusion(
  WidgetTester tester,
  String sender,
) async {
  selectDevnetSender(sender);

  final AccountInfo accountInfo = await app.zenon!.ledger
      .getAccountInfoByAddress(Address.parse(sender));
  expect(
    accountInfo.getBalance(kQsrCoin.tokenStandard),
    greaterThan(BigInt.zero),
    reason: 'Selected devnet sender must have QSR for plasma fusion',
  );
}
