// BDD Usage comments intentionally mirror Gherkin placeholders.
// ignore_for_file: unintended_html_in_doc_comment, lines_longer_than_80_chars

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenon_syrius_wallet_flutter/l10n/app_localizations.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart' as app;
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

import '../support/p2p_swap_devnet_helpers.dart';

/// Usage: the counterparty joins the P2P HTLC swap with <counter_amount> ZNN from the Join P2P Swap modal
Future<void> theCounterpartyJoinsTheP2pHtlcSwapWithZnnFromTheJoinP2pSwapModal(
  WidgetTester tester,
  String counterAmount,
) async {
  final P2pSwapDevnetContext swapContext = requireP2pSwapDevnetContext();
  final HtlcSwap initialSwap = swapContext.initialSwap!;
  final Hash initialHtlcId = swapContext.initialHtlcId!;
  final BigInt expectedCounterAmount = counterAmount.extractDecimals(
    coinDecimals,
  );

  await swapContext.activateCounterpartyWallet();

  final Completer<String?> dialogResultCompleter = Completer<String?>();

  try {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: _JoinSwapDialogHost(
          onDialogResult: (String? swapId) {
            if (!dialogResultCompleter.isCompleted) {
              dialogResultCompleter.complete(swapId);
            }
          },
        ),
      ),
    );
    await tester.pump();

    final Finder depositIdField = find.byKey(
      const Key('join_p2p_swap_deposit_id_field'),
    );
    await pumpUntilFound(
      tester,
      depositIdField,
      description: 'Join P2P Swap deposit ID input field',
    );
    await tester.enterText(depositIdField, initialHtlcId.toString());
    await tester.pump(const Duration(milliseconds: 200));

    final Finder validateButton = find.byKey(
      const Key('join_p2p_swap_validate_button'),
    );
    await pumpUntilFound(
      tester,
      validateButton,
      description: 'Join P2P Swap validate button',
    );
    await tester.ensureVisible(validateButton);
    await tester.pump(const Duration(milliseconds: 100));
    final Finder amountField = find.byKey(
      const Key('join_p2p_swap_amount_field'),
    );
    await runIgnoringInstructionButtonCrossFadeOverflow<void>(() async {
      await tester.tap(validateButton);
      await pumpUntilFound(
        tester,
        amountField,
        description: 'Join P2P Swap amount field after HTLC validation',
      );
    });
    await tester.enterText(amountField, counterAmount);
    await tester.pump(const Duration(milliseconds: 200));

    final Finder joinButton = find.byKey(
      const Key('join_p2p_swap_submit_button'),
    );
    await pumpUntilFound(
      tester,
      joinButton,
      description: 'Join P2P Swap submit button',
    );
    await tester.ensureVisible(joinButton);
    await tester.pump(const Duration(milliseconds: 100));

    final String? returnedSwapId =
        await runIgnoringInstructionButtonCrossFadeOverflow<String?>(() async {
          await tester.tap(joinButton);
          return await pumpUntilComplete<String?>(
            tester,
            dialogResultCompleter.future,
            'JoinP2pSwapModal completion',
          );
        });
    expect(returnedSwapId, initialHtlcId.toString());

    final HtlcSwap? joinedSwap = await swapContext.counterpartyRepository
        .getSwapById(returnedSwapId!);
    expect(joinedSwap, isNotNull);
    expect(joinedSwap!.direction, P2pSwapDirection.incoming);
    expect(joinedSwap.state, P2pSwapState.active);
    expect(joinedSwap.counterHtlcId, isNotNull);

    final Hash counterHtlcId = Hash.parse(joinedSwap.counterHtlcId!);
    final HtlcInfo onChainCounterHtlc = await pollDevnet<HtlcInfo>(
      () => app.zenon!.embedded.htlc.getById(counterHtlcId),
      isReady: (HtlcInfo htlc) => htlc.id == counterHtlcId,
      description: 'counter-HTLC $counterHtlcId on-chain',
    );

    expect(onChainCounterHtlc.id, counterHtlcId);
    expect(onChainCounterHtlc.tokenStandard, znnZts);
    expect(onChainCounterHtlc.amount, expectedCounterAmount);
    expect(
      onChainCounterHtlc.timeLocked,
      Address.parse(swapContext.counterpartyAddress),
    );
    expect(
      onChainCounterHtlc.hashLocked,
      Address.parse(swapContext.initiatorAddress),
    );
    expect(onChainCounterHtlc.hashType, initialSwap.hashType);
    expect(
      FormatUtils.encodeHexString(onChainCounterHtlc.hashLock),
      initialSwap.hashLock,
    );

    await waitForConfirmedHtlcContractReceive(
      counterHtlcId,
      description:
          'confirmed HTLC contract receive block for counter-HTLC '
          '$counterHtlcId',
    );

    swapContext
      ..counterSwap = joinedSwap
      ..counterHtlcId = counterHtlcId
      ..counterSwapAmount = expectedCounterAmount;
  } finally {
    await tester.pumpWidget(const SizedBox.shrink());
  }
}

class _JoinSwapDialogHost extends StatefulWidget {
  const _JoinSwapDialogHost({required this.onDialogResult});

  final void Function(String? swapId) onDialogResult;

  @override
  State<_JoinSwapDialogHost> createState() => _JoinSwapDialogHostState();
}

class _JoinSwapDialogHostState extends State<_JoinSwapDialogHost> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      unawaited(
        showDialog<String>(
          context: context,
          builder: (BuildContext _) => const Dialog(
            child: SizedBox(width: 680, child: JoinP2pSwapModal()),
          ),
        ).then(widget.onDialogResult),
      );
    });
  }

  @override
  Widget build(BuildContext context) => const Scaffold(body: SizedBox.shrink());
}
