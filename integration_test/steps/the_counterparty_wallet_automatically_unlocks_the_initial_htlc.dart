import 'package:flutter_test/flutter_test.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

import '../support/p2p_swap_devnet_helpers.dart';

/// Usage: the counterparty wallet automatically unlocks the initial HTLC
Future<void> theCounterpartyWalletAutomaticallyUnlocksTheInitialHtlc(
  WidgetTester tester,
) async {
  final P2pSwapDevnetContext swapContext = requireP2pSwapDevnetContext();
  final HtlcSwap initialSwap = swapContext.initialSwap!;
  final Hash initialHtlcId = swapContext.initialHtlcId!;
  final AccountBlockTemplate unlockBlock = swapContext.initiatorUnlockBlock!;

  swapContext.initiatorUnlockContractReceive =
      await waitForConfirmedHtlcContractReceive(
        unlockBlock.hash,
        description:
            'confirmed HTLC contract receive block for initiator unlock '
            '${unlockBlock.hash}',
      );

  // Run the counterparty's real sync + auto-unlock service so it discovers the
  // revealed preimage on-chain and claims the initial HTLC automatically.
  await swapContext.activateCounterpartyWallet();
  swapContext.completedCounterpartySwap = await swapContext.syncUntilSwapReady(
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
}
