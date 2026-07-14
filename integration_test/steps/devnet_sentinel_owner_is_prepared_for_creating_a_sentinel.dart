// BDD Usage comments intentionally mirror Gherkin placeholders.
// ignore_for_file: unintended_html_in_doc_comment, lines_longer_than_80_chars

import 'package:flutter_test/flutter_test.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart' as app;
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

import '../support/devnet_test_context.dart';

/// Usage: <sentinel_owner> devnet sentinel owner is prepared for creating a sentinel
Future<void> devnetSentinelOwnerIsPreparedForCreatingASentinel(
  WidgetTester tester,
  String owner,
) async {
  selectDevnetSender(owner);
  final Address ownerAddress = Address.parse(owner);
  final SentinelInfo? sentinelInfo = await app.zenon!.embedded.sentinel
      .getByOwner(ownerAddress);
  expect(
    sentinelInfo,
    isNull,
    reason: 'Sentinel owner already has a sentinel; reset devnet state',
  );

  final PlasmaInfo plasmaInfo = await app.zenon!.embedded.plasma.get(
    ownerAddress,
  );
  expect(
    plasmaInfo.currentPlasma,
    greaterThanOrEqualTo(kSentinelPlasmaAmountNeeded),
    reason: 'Sentinel owner does not have enough plasma to register a sentinel',
  );

  final BigInt depositedQsr = await app.zenon!.embedded.sentinel
      .getDepositedQsr(ownerAddress);
  final BigInt remainingQsr = sentinelRegisterQsrAmount > depositedQsr
      ? sentinelRegisterQsrAmount - depositedQsr
      : BigInt.zero;
  final AccountInfo accountInfo = await app.zenon!.ledger
      .getAccountInfoByAddress(ownerAddress);

  expect(
    accountInfo.getBalance(znnZts),
    greaterThanOrEqualTo(sentinelRegisterZnnAmount),
    reason: 'Sentinel owner does not have enough ZNN to register a sentinel',
  );
  expect(
    accountInfo.getBalance(qsrZts),
    greaterThanOrEqualTo(remainingQsr),
    reason: 'Sentinel owner does not have enough QSR for the slot deposit',
  );
}
