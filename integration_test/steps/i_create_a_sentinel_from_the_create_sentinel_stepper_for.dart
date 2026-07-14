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

/// Usage: I create a sentinel from the Create Sentinel stepper for <sentinel_owner>
Future<void> iCreateASentinelFromTheCreateSentinelStepperFor(
  WidgetTester tester,
  String owner,
) async {
  selectDevnetSender(owner);
  final AccountInfo accountInfo = await app.zenon!.ledger
      .getAccountInfoByAddress(Address.parse(owner));

  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: BlocProvider<MultipleBalanceBloc>.value(
          value: app.sl<MultipleBalanceBloc>(),
          child: const CreateSentinelStepperPage(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  await _tapAndSettle(tester, const Key('sentinel_plasma_next_button'));
  await _completeQsrStep(tester, owner, accountInfo);
  await _tapAndSettle(tester, const Key('sentinel_znn_next_button'));

  final Finder registerButton = find.byKey(
    const Key('sentinel_register_button'),
  );
  await _pumpUntilFound(tester, registerButton);
  await tester.ensureVisible(registerButton);
  await tester.pumpAndSettle();
  final DeploySentinelBloc deploySentinelBloc = tester
      .element(registerButton)
      .read<DeploySentinelBloc>();
  final Completer<void> completer = Completer<void>();
  final StreamSubscription<DeploySentinelState> subscription =
      deploySentinelBloc.stream.listen((DeploySentinelState state) {
    if (state is DeploySentinelDone && !completer.isCompleted) {
      completer.complete();
    } else if (state is DeploySentinelFailure && !completer.isCompleted) {
      completer.completeError(state.exception);
    }
  });

  try {
    await tester.tap(registerButton);
    await _pumpUntilComplete(
      tester,
      completer.future,
      'sentinel registration success',
    );
  } finally {
    await subscription.cancel();
  }
}

Future<void> _completeQsrStep(
  WidgetTester tester,
  String owner,
  AccountInfo accountInfo,
) async {
  final Address ownerAddress = Address.parse(owner);
  final Finder qsrNextButton = find.byKey(
    const Key('sentinel_qsr_next_button'),
  );
  final Finder qsrAmountField = find.byKey(
    const Key('sentinel_qsr_amount_field'),
  );
  await _pumpUntilAnyFound(tester, <Finder>[qsrNextButton, qsrAmountField]);

  final BigInt depositedQsr = await app.zenon!.embedded.sentinel
      .getDepositedQsr(ownerAddress);
  final BigInt remainingQsr = sentinelRegisterQsrAmount > depositedQsr
      ? sentinelRegisterQsrAmount - depositedQsr
      : BigInt.zero;

  if (qsrAmountField.evaluate().isNotEmpty) {
    final TextFormField amountField = tester.widget<TextFormField>(
      qsrAmountField,
    );
    final BigInt depositAmount = amountField.controller!.text.extractDecimals(
      coinDecimals,
    );
    expect(depositAmount, remainingQsr);
    expect(
      accountInfo.getBalance(qsrZts),
      greaterThanOrEqualTo(depositAmount),
      reason: 'Sentinel owner does not have enough QSR for the slot deposit',
    );

    final Finder depositButton = find.byKey(
      const Key('sentinel_qsr_deposit_button'),
    );
    await _pumpUntilFound(tester, depositButton);
    await tester.ensureVisible(depositButton);
    await tester.pumpAndSettle();
    final SentinelDepositQsrBloc depositBloc = tester
        .element(depositButton)
        .read<SentinelDepositQsrBloc>();
    final Completer<void> completer = Completer<void>();
    final StreamSubscription<SentinelDepositQsrState> subscription =
        depositBloc.stream.listen((SentinelDepositQsrState state) {
      if (state is SentinelDepositQsrDone && !completer.isCompleted) {
        completer.complete();
      } else if (state is SentinelDepositQsrFailure &&
          !completer.isCompleted) {
        completer.completeError(state.exception);
      }
    });

    try {
      await tester.tap(depositButton);
      await _pumpUntilComplete(
        tester,
        completer.future,
        'sentinel QSR deposit success',
      );
      await _poll<BigInt>(
        () => app.zenon!.embedded.sentinel.getDepositedQsr(ownerAddress),
        isReady: (BigInt value) => value == sentinelRegisterQsrAmount,
        description: 'sentinel QSR deposit to reach the registration amount',
      );
    } finally {
      await subscription.cancel();
    }
  } else {
    expect(
      depositedQsr,
      greaterThanOrEqualTo(sentinelRegisterQsrAmount),
      reason: 'Sentinel owner does not have enough deposited QSR',
    );
  }

  await _tapAndSettle(tester, const Key('sentinel_qsr_next_button'));
}

Future<void> _tapAndSettle(WidgetTester tester, Key key) async {
  final Finder finder = find.byKey(key);
  await _pumpUntilFound(tester, finder);
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _pumpUntilAnyFound(
  WidgetTester tester,
  List<Finder> finders,
) async {
  final DateTime deadline = DateTime.now().add(const Duration(seconds: 90));
  while (finders.every((Finder finder) => finder.evaluate().isEmpty) &&
      DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 100));
  }

  expect(
    finders.any((Finder finder) => finder.evaluate().isNotEmpty),
    isTrue,
  );
}

Future<void> _pumpUntilFound(WidgetTester tester, Finder finder) async {
  final DateTime deadline = DateTime.now().add(const Duration(seconds: 90));
  while (finder.evaluate().isEmpty && DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 100));
  }

  expect(finder, findsOneWidget);
}

Future<void> _pumpUntilComplete(
  WidgetTester tester,
  Future<void> future,
  String description,
) async {
  Object? error;
  StackTrace? stackTrace;
  bool completed = false;

  unawaited(
    future.then(
      (_) {
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
    throw TimeoutException('Timed out waiting for $description');
  }
  if (error != null) {
    Error.throwWithStackTrace(error!, stackTrace!);
  }
}

Future<T> _poll<T>(
  Future<T> Function() fetch, {
  required bool Function(T value) isReady,
  required String description,
}) async {
  final DateTime deadline = DateTime.now().add(const Duration(seconds: 90));
  Object? lastError;

  while (DateTime.now().isBefore(deadline)) {
    try {
      final T value = await fetch();
      if (isReady(value)) {
        return value;
      }
    } on Object catch (error) {
      lastError = error;
    }
    await Future<void>.delayed(const Duration(seconds: 1));
  }

  throw TimeoutException(
    'Timed out waiting for $description. Last error: $lastError',
  );
}
