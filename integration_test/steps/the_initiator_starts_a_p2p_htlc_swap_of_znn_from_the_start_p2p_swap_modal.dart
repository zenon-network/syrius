// BDD Usage comments intentionally mirror Gherkin placeholders.
// ignore_for_file: unintended_html_in_doc_comment, lines_longer_than_80_chars

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/single_child_widget.dart';
import 'package:zenon_syrius_wallet_flutter/l10n/app_localizations.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart' as app;
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

import '../support/p2p_swap_devnet_helpers.dart';

/// Usage: the initiator starts a P2P HTLC swap of <initial_amount> ZNN from the Start P2P Swap modal
Future<void> theInitiatorStartsAP2pHtlcSwapOfZnnFromTheStartP2pSwapModal(
  WidgetTester tester,
  String initialAmount,
) async {
  final P2pSwapDevnetContext swapContext = requireP2pSwapDevnetContext();
  await swapContext.activateInitiatorWallet();

  final BigInt expectedAmount = initialAmount.extractDecimals(coinDecimals);
  final StartP2pSwapBloc startP2pSwapBloc = StartP2pSwapBloc(
    accountBlockUtils: AccountBlockUtils(publishSuccessNotification: false),
    swapRepository: swapContext.initiatorRepository,
    zenon: app.zenon!,
    zenonAddressUtils: ZenonAddressUtils(),
  );

  final Completer<HtlcSwap> swapCompleter = Completer<HtlcSwap>();
  final StreamSubscription<StartP2pSwapState> subscription = startP2pSwapBloc
      .stream
      .listen((StartP2pSwapState state) {
        if (state is StartP2pSwapDone && !swapCompleter.isCompleted) {
          swapCompleter.complete(state.swap);
        } else if (state is StartP2pSwapFailure && !swapCompleter.isCompleted) {
          swapCompleter.completeError(state.exception);
        }
      });

  try {
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: <SingleChildWidget>[
          BlocProvider<MultipleBalanceBloc>.value(
            value: app.sl<MultipleBalanceBloc>(),
          ),
          BlocProvider<StartP2pSwapBloc>.value(value: startP2pSwapBloc),
        ],
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: _StartSwapDialogHost(),
        ),
      ),
    );
    await tester.pump();

    final Finder counterpartyField = find.byKey(
      const Key('start_p2p_swap_counterparty_address_field'),
    );
    await pumpUntilFound(
      tester,
      counterpartyField,
      description: 'Start P2P Swap modal counterparty field to load',
    );
    await tester.enterText(counterpartyField, swapContext.counterpartyAddress);
    await tester.enterText(
      find.byKey(const Key('start_p2p_swap_amount_field')),
      initialAmount,
    );
    await tester.pump(const Duration(milliseconds: 200));

    final Finder submitButton = find.byKey(
      const Key('start_p2p_swap_submit_button'),
    );
    await pumpUntilFound(
      tester,
      submitButton,
      description: 'Start P2P Swap submit button',
    );
    await tester.ensureVisible(submitButton);
    await tester.pump(const Duration(milliseconds: 100));
    final HtlcSwap createdSwap =
        await runIgnoringInstructionButtonCrossFadeOverflow<HtlcSwap>(() async {
          await tester.tap(submitButton);
          return await pumpUntilComplete<HtlcSwap>(
            tester,
            swapCompleter.future,
            'StartP2pSwapBloc completion',
          );
        });
    await tester.pump(const Duration(milliseconds: 200));

    final HtlcSwap? storedSwap = await swapContext.initiatorRepository
        .getSwapById(createdSwap.id);
    expect(storedSwap, createdSwap);

    swapContext
      ..initialSwap = createdSwap
      ..initialHtlcId = Hash.parse(createdSwap.initialHtlcId)
      ..initialSwapAmount = expectedAmount;
  } finally {
    await subscription.cancel();
    await tester.pumpWidget(const SizedBox.shrink());
    await startP2pSwapBloc.close();
  }
}

class _StartSwapDialogHost extends StatefulWidget {
  const _StartSwapDialogHost();

  @override
  State<_StartSwapDialogHost> createState() => _StartSwapDialogHostState();
}

class _StartSwapDialogHostState extends State<_StartSwapDialogHost> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      unawaited(
        showDialog<void>(
          context: context,
          builder: (BuildContext _) => const Dialog(
            child: SizedBox(width: 680, child: StartP2pSwapModal()),
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) => const Scaffold(body: SizedBox.shrink());
}
