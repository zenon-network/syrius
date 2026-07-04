// BDD Usage comments intentionally mirror Gherkin placeholders.
// ignore_for_file: unintended_html_in_doc_comment, lines_longer_than_80_chars

import 'package:flutter_test/flutter_test.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart' as app;
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

import '../support/devnet_test_context.dart';
import 'address_should_have_at_least_plasma.dart';
import 'i_fuse_qsr_to.dart';

/// Usage: the devnet pillar owner is prepared for creating testPillar
Future<void> theDevnetPillarOwnerIsPreparedForCreatingTestpillar(
  WidgetTester tester,
) async {
  const String owner = DevnetTestContext.testPillarOwnerAddress;
  const String plasmaFuser = 'z1qq6eg8n43g032hanpsfp02qcdmv7zfj3y2lt5d';
  const String name = DevnetTestContext.testPillarName;
  const String setupQsrFuseAmount =
      DevnetTestContext.testPillarSetupQsrFuseAmount;

  selectDevnetSender(owner);
  final Address ownerAddress = Address.parse(owner);
  final bool nameAvailable = await app.zenon!.embedded.pillar
      .checkNameAvailability(name);
  expect(
    nameAvailable,
    isTrue,
    reason: 'Pillar name $name already exists; reset devnet state',
  );

  final BigInt qsrRegistrationCost = await app.zenon!.embedded.pillar
      .getQsrRegistrationCost();
  final BigInt depositedQsr = await app.zenon!.embedded.pillar.getDepositedQsr(
    ownerAddress,
  );
  final BigInt remainingQsr = qsrRegistrationCost > depositedQsr
      ? qsrRegistrationCost - depositedQsr
      : BigInt.zero;
  final AccountInfo accountInfo = await app.zenon!.ledger
      .getAccountInfoByAddress(ownerAddress);
  final PlasmaInfo plasmaInfo = await app.zenon!.embedded.plasma.get(
    ownerAddress,
  );
  final BigInt setupFuseAmount = setupQsrFuseAmount.extractDecimals(
    coinDecimals,
  );
  final bool needsPlasma =
      plasmaInfo.currentPlasma < kPillarPlasmaAmountNeeded;

  expect(
    accountInfo.getBalance(znnZts),
    greaterThanOrEqualTo(pillarRegisterZnnAmount),
    reason: 'Pillar owner does not have enough ZNN to register a pillar',
  );
  expect(
    accountInfo.getBalance(qsrZts),
    greaterThanOrEqualTo(remainingQsr),
    reason: 'Pillar owner does not have enough QSR for setup and slot deposit',
  );

  if (needsPlasma) {
    final AccountInfo plasmaFuserAccountInfo = await app.zenon!.ledger
        .getAccountInfoByAddress(Address.parse(plasmaFuser));
    expect(
      plasmaFuserAccountInfo.getBalance(qsrZts),
      greaterThanOrEqualTo(setupFuseAmount),
      reason: 'Plasma fuser does not have enough QSR for setup',
    );

    // The z1qq6eg8n43g032hanpsfp02qcdmv7zfj3y2lt5d address already has a
    // high plasma level, so the fuse transaction will be faster.
    selectDevnetSender(plasmaFuser);
    try {
      await iFuseQsrTo(tester, setupQsrFuseAmount, owner);
      await addressShouldHaveAtLeastPlasma(
        tester,
        owner,
        kPillarPlasmaAmountNeeded.toString(),
      );
    } finally {
      selectDevnetSender(owner);
    }
  }
}
