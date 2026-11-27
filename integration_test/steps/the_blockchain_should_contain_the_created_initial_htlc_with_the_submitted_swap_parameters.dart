// BDD Usage comments intentionally mirror Gherkin placeholders.
// ignore_for_file: lines_longer_than_80_chars

import 'package:flutter_test/flutter_test.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart' as app;
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

import '../support/p2p_swap_devnet_helpers.dart';

/// Usage: the blockchain should contain the created initial HTLC with the submitted swap parameters
Future<void>
theBlockchainShouldContainTheCreatedInitialHtlcWithTheSubmittedSwapParameters(
  WidgetTester tester,
) async {
  final P2pSwapDevnetContext swapContext = requireP2pSwapDevnetContext();
  final HtlcSwap initialSwap = swapContext.initialSwap!;
  final Hash initialHtlcId = swapContext.initialHtlcId!;
  final BigInt expectedAmount = swapContext.initialSwapAmount!;

  final HtlcInfo onChainHtlc = await pollDevnet<HtlcInfo>(
    () => app.zenon!.embedded.htlc.getById(initialHtlcId),
    isReady: (HtlcInfo htlc) => htlc.id == initialHtlcId,
    description: 'initial HTLC $initialHtlcId on-chain',
  );

  expect(onChainHtlc.id, initialHtlcId);
  expect(onChainHtlc.tokenStandard, znnZts);
  expect(onChainHtlc.amount, expectedAmount);
  expect(onChainHtlc.timeLocked, Address.parse(swapContext.initiatorAddress));
  expect(
    onChainHtlc.hashLocked,
    Address.parse(swapContext.counterpartyAddress),
  );
  expect(onChainHtlc.hashType, initialSwap.hashType);
  expect(
    FormatUtils.encodeHexString(onChainHtlc.hashLock),
    initialSwap.hashLock,
  );
  expect(onChainHtlc.expirationTime, initialSwap.initialHtlcExpirationTime);

  await pollDevnet<AccountBlock?>(
    () => app.zenon!.ledger.getAccountBlockByHash(initialHtlcId),
    isReady: (AccountBlock? block) =>
        block?.confirmationDetail?.momentumTimestamp != null,
    description: 'confirmed creation block for initial HTLC $initialHtlcId',
  );

  await waitForConfirmedHtlcContractReceive(
    initialHtlcId,
    description:
        'confirmed HTLC contract receive block for initial HTLC '
        '$initialHtlcId',
  );
}
