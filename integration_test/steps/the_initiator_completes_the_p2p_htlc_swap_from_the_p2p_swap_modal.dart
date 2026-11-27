import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenon_syrius_wallet_flutter/l10n/app_localizations.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

import '../support/p2p_swap_devnet_helpers.dart';

/// Usage: the initiator completes the P2P HTLC swap from the P2P Swap modal
Future<void> theInitiatorCompletesTheP2pHtlcSwapFromTheP2pSwapModal(
  WidgetTester tester,
) async {
  final P2pSwapDevnetContext swapContext = requireP2pSwapDevnetContext();
  final HtlcSwap initialSwap = swapContext.initialSwap!;
  final Hash counterHtlcId = swapContext.counterHtlcId!;

  await swapContext.activateInitiatorWallet();

  final HtlcSwap syncedSwap = await swapContext.syncUntilSwapReady(
    repository: swapContext.initiatorRepository,
    swapId: initialSwap.id,
    isReady: (HtlcSwap? swap) =>
        swap != null &&
        swap.state == P2pSwapState.active &&
        swap.counterHtlcId == counterHtlcId.toString(),
    description:
        'initiator HtlcSwapSyncService to detect counter-HTLC $counterHtlcId',
  );
  expect(syncedSwap.toAmount, swapContext.counterSwapAmount);
  expect(syncedSwap.toToken?.tokenStandard, znnZts);

  StreamSubscription<CompleteSwapState>? subscription;
  try {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 680,
              child: P2pSwapModal(swapId: initialSwap.id),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final Finder completeButton = find.byKey(
      const Key('complete_p2p_swap_button'),
    );
    await pumpUntilFound(
      tester,
      completeButton,
      description: 'Complete Swap button in P2pSwapModal',
    );
    await tester.ensureVisible(completeButton);
    await tester.pump(const Duration(milliseconds: 100));

    final CompleteSwapBloc completeSwapBloc = tester
        .element(completeButton)
        .read<CompleteSwapBloc>();
    final Completer<AccountBlockTemplate> unlockCompleter =
        Completer<AccountBlockTemplate>();
    subscription = completeSwapBloc.stream.listen((CompleteSwapState state) {
      if (state is CompleteSwapDone && !unlockCompleter.isCompleted) {
        unlockCompleter.complete(state.block);
      } else if (state is CompleteSwapFailure && !unlockCompleter.isCompleted) {
        unlockCompleter.completeError(state.exception);
      }
    });

    swapContext.initiatorUnlockBlock =
        await runIgnoringInstructionButtonCrossFadeOverflow<
          AccountBlockTemplate
        >(() async {
          await tester.tap(completeButton);
          return await pumpUntilComplete<AccountBlockTemplate>(
            tester,
            unlockCompleter.future,
            'CompleteSwapBloc unlock submission',
          );
        });

    await pumpUntilFound(
      tester,
      find.byType(CompletedSwapView),
      description: 'P2pSwapModal to show CompletedSwapView',
    );

    // Allow ToastUtils' 3-second foreground toast timer to fire cleanly
    // before tearing down the Overlay widget tree.
    final DateTime toastDeadline = DateTime.now().add(
      const Duration(milliseconds: 3200),
    );
    while (DateTime.now().isBefore(toastDeadline)) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  } finally {
    await subscription?.cancel();
    await tester.pumpWidget(const SizedBox.shrink());
  }
}
