// BDD Usage comments intentionally mirror Gherkin placeholders.
// ignore_for_file: lines_longer_than_80_chars

import 'package:flutter_test/flutter_test.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart' as app;
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

import '../support/p2p_swap_devnet_helpers.dart';

/// Usage: the blockchain should record the unlocked HTLC swap for both participants
Future<void> theBlockchainShouldRecordTheUnlockedHtlcSwapForBothParticipants(
  WidgetTester tester,
) async {
  final P2pSwapDevnetContext swapContext = requireP2pSwapDevnetContext();
  final HtlcSwap initialSwap = swapContext.initialSwap!;
  final Hash initialHtlcId = swapContext.initialHtlcId!;
  final Hash counterHtlcId = swapContext.counterHtlcId!;
  final BigInt initialSwapAmount = swapContext.initialSwapAmount!;
  final BigInt counterSwapAmount = swapContext.counterSwapAmount!;
  final AccountBlockTemplate unlockBlock = swapContext.initiatorUnlockBlock!;

  final AccountBlock? confirmedUnlockBlock = await pollDevnet<AccountBlock?>(
    () => app.zenon!.ledger.getAccountBlockByHash(unlockBlock.hash),
    isReady: (AccountBlock? block) =>
        block?.confirmationDetail?.momentumTimestamp != null,
    description: 'confirmed initiator unlock block ${unlockBlock.hash}',
  );

  expect(confirmedUnlockBlock, isNotNull);
  expect(confirmedUnlockBlock!.hash, unlockBlock.hash);
  expect(
    confirmedUnlockBlock.address,
    Address.parse(swapContext.initiatorAddress),
  );
  expect(confirmedUnlockBlock.toAddress, htlcAddress);

  final BlockData? unlockData = decodeHtlcBlockData(confirmedUnlockBlock.data);
  expect(unlockData, isNotNull);
  expect(unlockData!.function, 'Unlock');
  expect(unlockData.params['id'].toString(), counterHtlcId.toString());
  expect(
    FormatUtils.encodeHexString(unlockData.params['preimage'] as List<int>),
    initialSwap.preimage,
  );

  await waitForConfirmedHtlcContractReceive(
    unlockBlock.hash,
    description:
        'confirmed HTLC contract receive block for initiator unlock '
        '${unlockBlock.hash}',
  );
  await waitForHtlcRemoved(counterHtlcId);
  await waitForHtlcPayoutUnreceivedBlock(
    recipient: Address.parse(swapContext.initiatorAddress),
    expectedToken: znnZts,
    expectedAmount: counterSwapAmount,
  );

  // Run the counterparty's real sync + auto-unlock service so it discovers the
  // revealed preimage on-chain and claims the initial HTLC automatically.
  await swapContext.activateCounterpartyWallet();
  final HtlcSwap completedCounterpartySwap = await swapContext
      .syncUntilSwapReady(
        repository: swapContext.counterpartyRepository,
        swapId: initialSwap.id,
        isReady: (HtlcSwap? swap) =>
            swap != null &&
            swap.state == P2pSwapState.completed &&
            swap.preimage == initialSwap.preimage,
        description:
            'counterparty HtlcSwapSyncService to auto-unlock initial HTLC '
            '$initialHtlcId',
      );
  expect(completedCounterpartySwap.state, P2pSwapState.completed);
  expect(completedCounterpartySwap.preimage, initialSwap.preimage);

  await waitForHtlcRemoved(initialHtlcId);
  await waitForHtlcPayoutUnreceivedBlock(
    recipient: Address.parse(swapContext.counterpartyAddress),
    expectedToken: znnZts,
    expectedAmount: initialSwapAmount,
  );
}
