// BDD Usage comments intentionally mirror Gherkin placeholders.
// ignore_for_file: unintended_html_in_doc_comment, lines_longer_than_80_chars

import 'package:flutter_test/flutter_test.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart' as app;
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

import '../support/devnet_test_context.dart';
import 'address_should_have_at_least_plasma.dart';
import 'i_fuse_qsr_to.dart';

/// Usage: <sender> address is prepared for pillar creation with at least <required_plasma> plasma using <setup_qsr_fuse_amount> QSR if needed
Future<void>
addressIsPreparedForPillarCreationWithAtLeastPlasmaUsingQsrIfNeeded(
  WidgetTester tester,
  String sender,
  String requiredPlasma,
  String setupQsrFuseAmount,
) async {
  selectDevnetSender(sender);

  final Address senderAddress = Address.parse(sender);
  final int requiredPlasmaAmount = int.parse(requiredPlasma);
  final BigInt setupFuseAmount = setupQsrFuseAmount.extractDecimals(
    coinDecimals,
  );

  final PlasmaInfo initialPlasma = await app.zenon!.embedded.plasma.get(
    senderAddress,
  );
  if (initialPlasma.currentPlasma < requiredPlasmaAmount) {
    await iFuseQsrTo(tester, setupQsrFuseAmount, sender);
    await addressShouldHaveAtLeastPlasma(tester, sender, requiredPlasma);
  }

  final AccountInfo accountInfo = await app.zenon!.ledger
      .getAccountInfoByAddress(senderAddress);
  final BigInt qsrRegistrationCost = await app.zenon!.embedded.pillar
      .getQsrRegistrationCost();
  final BigInt depositedQsr = await app.zenon!.embedded.pillar.getDepositedQsr(
    senderAddress,
  );
  final BigInt remainingQsr = qsrRegistrationCost - depositedQsr;

  expect(
    accountInfo.getBalance(znnZts),
    greaterThan(BigInt.zero),
    reason: 'Pillar sender must have ZNN available for the create flow',
  );
  expect(
    accountInfo.getBalance(qsrZts),
    greaterThanOrEqualTo(
      remainingQsr > BigInt.zero ? remainingQsr : BigInt.zero,
    ),
    reason: 'Pillar sender does not have enough QSR to cover the slot deposit',
  );
  expect(
    depositedQsr,
    lessThan(qsrRegistrationCost),
    reason:
        'Pillar sender already has enough QSR deposited; reset devnet state',
  );
  expect(
    setupFuseAmount,
    greaterThanOrEqualTo(fuseMinQsrAmount),
    reason: 'Setup QSR fuse amount must be at least the protocol minimum',
  );

  final PlasmaInfo finalPlasma = await app.zenon!.embedded.plasma.get(
    senderAddress,
  );
  expect(
    finalPlasma.currentPlasma,
    greaterThanOrEqualTo(requiredPlasmaAmount),
    reason: 'Test setup failed: pillar sender does not have enough plasma',
  );
}
