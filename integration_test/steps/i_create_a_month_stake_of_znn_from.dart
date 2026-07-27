// BDD Usage comments intentionally mirror Gherkin placeholders.
// ignore_for_file: unintended_html_in_doc_comment, non_constant_identifier_names

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

/// Usage: I create a <duration_months> month stake of <amount> ZNN from <stake_address>
Future<void> iCreateAMonthStakeOfZnnFrom(
  WidgetTester tester,
  dynamic duration_months,
  dynamic amount,
  dynamic stake_address,
) async {
  final DevnetTestContext context = app.sl<DevnetTestContext>();
  final String durationMonths = duration_months as String;
  final String stakeAmount = amount as String;
  final String stakeAddress = stake_address as String;
  final AccountInfo accountInfo = await app.zenon!.ledger
      .getAccountInfoByAddress(Address.parse(stakeAddress));

  selectDevnetSender(stakeAddress);

  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: BlocProvider<MultipleBalanceBloc>.value(
          value: app.sl<MultipleBalanceBloc>(),
          child: CreateStakeCard(onStakeCreated: () {}),
        ),
      ),
    ),
  );
  app.sl<MultipleBalanceBloc>().add(
    MultipleBalanceFetch(addresses: <String>[stakeAddress]),
  );
  await tester.pumpAndSettle();

  expect(
    accountInfo.getBalance(znnZts),
    greaterThanOrEqualTo(stakeAmount.extractDecimals(coinDecimals)),
    reason: 'Stake address does not have enough ZNN for the test stake',
  );

  await _selectDuration(tester, durationMonths);
  await tester.enterText(
    find.byKey(const Key('create_stake_amount_field')),
    stakeAmount,
  );
  await tester.pumpAndSettle();

  final Finder submitButton = find.byKey(
    const Key('create_stake_submit_button'),
  );
  await _pumpUntilFound(tester, submitButton);
  await tester.ensureVisible(submitButton);
  await tester.pumpAndSettle();
  final SendTransactionBloc sendTransactionBloc = tester
      .element(submitButton)
      .read<SendTransactionBloc>();
  final Completer<AccountBlockTemplate> completer =
      Completer<AccountBlockTemplate>();
  final StreamSubscription<SendTransactionState> subscription =
      sendTransactionBloc.stream.listen((SendTransactionState state) {
        if (state.status == SendTransactionStatus.success &&
            state.data != null &&
            !completer.isCompleted) {
          completer.complete(state.data);
        } else if (state.status == SendTransactionStatus.failure &&
            !completer.isCompleted) {
          completer.completeError(
            state.error ?? StateError('Stake transaction failed'),
          );
        }
      });

  try {
    await tester.tap(submitButton);
    context.stakeBlock = await _pumpUntilComplete(
      tester,
      completer.future,
      'stake transaction success',
    );
  } finally {
    await subscription.cancel();
  }
}

Future<void> _selectDuration(
  WidgetTester tester,
  String durationMonths,
) async {
  final Finder dropdown = find.byKey(
    const Key('create_stake_duration_dropdown'),
  );
  await _pumpUntilFound(tester, dropdown);
  await tester.tap(dropdown);
  await tester.pumpAndSettle();

  final Finder durationOption = find
      .text(
        '$durationMonths $stakeUnitDurationName${durationMonths == '1' ? '' : 's'}',
      )
      .last;
  await _pumpUntilFound(tester, durationOption);
  await tester.tap(durationOption);
  await tester.pumpAndSettle();
}

Future<void> _pumpUntilFound(WidgetTester tester, Finder finder) async {
  final DateTime deadline = DateTime.now().add(const Duration(seconds: 90));
  while (finder.evaluate().isEmpty && DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 100));
  }

  expect(finder, findsOneWidget);
}

Future<T> _pumpUntilComplete<T>(
  WidgetTester tester,
  Future<T> future,
  String description,
) async {
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
    throw TimeoutException('Timed out waiting for $description');
  }
  if (error != null) {
    Error.throwWithStackTrace(error!, stackTrace!);
  }
  return result as T;
}
