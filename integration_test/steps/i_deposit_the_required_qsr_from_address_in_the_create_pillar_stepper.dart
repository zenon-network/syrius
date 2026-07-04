// BDD Usage comments intentionally mirror Gherkin placeholders.
// ignore_for_file: unintended_html_in_doc_comment, lines_longer_than_80_chars

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenon_syrius_wallet_flutter/l10n/app_localizations.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart' as app;
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

import '../support/devnet_test_context.dart';

/// Usage: I deposit the required QSR from <sender> address in the Create Pillar stepper
Future<void> iDepositTheRequiredQsrFromAddressInTheCreatePillarStepper(
  WidgetTester tester,
  String sender,
) async {
  final DevnetTestContext context = app.sl<DevnetTestContext>();
  selectDevnetSender(sender);

  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: BlocProvider<MultipleBalanceBloc>.value(
          value: app.sl<MultipleBalanceBloc>(),
          child: const CreatePillarStepperPage(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  await _pumpUntilFound(
    tester,
    find.byKey(const Key('pillar_plasma_next_button')),
  );
  await tester.tap(find.byKey(const Key('pillar_plasma_next_button')));
  await tester.pumpAndSettle();

  final Finder qsrAmountField = find.byKey(
    const Key('pillar_qsr_amount_field'),
  );
  await _pumpUntilFound(tester, qsrAmountField);
  final TextFormField amountField = tester.widget<TextFormField>(
    qsrAmountField,
  );
  final String amountText = amountField.controller!.text;
  final BigInt depositAmount = amountText.extractDecimals(coinDecimals);
  expect(depositAmount, greaterThan(BigInt.zero));

  final Finder depositButton = find.byKey(
    const Key('pillar_qsr_deposit_button'),
  );
  await _pumpUntilFound(tester, depositButton);

  final BuildContext buttonContext = tester.element(depositButton);
  if (!buttonContext.mounted) {
    throw StateError('Create Pillar deposit button context is not mounted');
  }
  final PillarDepositQsrBloc depositBloc = buttonContext
      .read<PillarDepositQsrBloc>();
  final Completer<AccountBlockTemplate> completer =
      Completer<AccountBlockTemplate>();
  final StreamSubscription<PillarDepositQsrState> subscription = depositBloc
      .stream
      .listen((PillarDepositQsrState state) {
        if (state is PillarDepositQsrDone && !completer.isCompleted) {
          completer.complete(state.accountBlock);
        } else if (state is PillarDepositQsrFailure && !completer.isCompleted) {
          completer.completeError(state.exception);
        }
      });

  try {
    await tester.tap(depositButton);
    context
      ..pillarQsrDepositAmount = depositAmount
      ..pillarQsrDepositBlock = await _pumpUntilComplete(
        tester,
        completer.future,
      );
  } finally {
    await subscription.cancel();
  }
}

Future<void> _pumpUntilFound(WidgetTester tester, Finder finder) async {
  final DateTime deadline = DateTime.now().add(const Duration(seconds: 90));
  while (finder.evaluate().isEmpty && DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 100));
  }

  expect(finder, findsOneWidget);
}

Future<T> _pumpUntilComplete<T>(WidgetTester tester, Future<T> future) async {
  T? result;
  Object? error;
  StackTrace? stackTrace;
  bool completed = false;

  unawaited(
    future.then(
      (T value) {
        result = value;
        completed = true;
      },
      onError: (Object e, StackTrace s) {
        error = e;
        stackTrace = s;
        completed = true;
      },
    ),
  );

  final DateTime deadline = DateTime.now().add(const Duration(seconds: 90));
  while (!completed && DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 100));
  }

  if (!completed) {
    throw TimeoutException('Timed out waiting for pillar QSR deposit success');
  }
  if (error != null) {
    Error.throwWithStackTrace(error!, stackTrace!);
  }
  return result as T;
}
