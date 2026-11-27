import 'package:flutter_test/flutter_test.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart' as app;
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

import '../support/p2p_swap_devnet_helpers.dart';

/// Usage: two funded devnet participants are prepared for a P2P HTLC swap
Future<void> twoFundedDevnetParticipantsArePreparedForAP2pHtlcSwap(
  WidgetTester tester,
) async {
  final P2pSwapDevnetContext swapContext = await P2pSwapDevnetContext.create();

  final AccountInfo initiatorInfo = await app.zenon!.ledger
      .getAccountInfoByAddress(Address.parse(swapContext.initiatorAddress));
  final BigInt requiredInitiatorZnn = '2'.extractDecimals(coinDecimals);
  expect(
    initiatorInfo.getBalance(znnZts),
    greaterThanOrEqualTo(requiredInitiatorZnn),
    reason: 'Devnet initiator does not have enough ZNN for the P2P swap test',
  );

  await ensureP2pSwapPlasma(
    swapContext: swapContext,
    targetAddress: swapContext.initiatorAddress,
  );
  await ensureP2pSwapPlasma(
    swapContext: swapContext,
    targetAddress: swapContext.counterpartyAddress,
  );
  await fundAndReceiveCounterpartyZnn(
    swapContext: swapContext,
    amountZnn: kP2pSwapCounterpartyFundingZnn,
  );
  await swapContext.activateInitiatorWallet();
}
