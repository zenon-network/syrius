// BDD Usage comments intentionally mirror Gherkin placeholders.
// ignore_for_file: unintended_html_in_doc_comment, lines_longer_than_80_chars

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenon_syrius_wallet_flutter/l10n/app_localizations.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart' as app;
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/utils/extensions.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

import '../support/devnet_test_context.dart';

/// Usage: I send <amount> ZNN from <sender> address to <recipient> address from the Send screen
Future<void> iSendZnnFromAddressToAddressFromTheSendScreen(
  WidgetTester tester,
  String amount,
  String sender,
  String recipient,
) async {
  final DevnetTestContext context = app.sl<DevnetTestContext>();
  selectDevnetSender(sender);
  final Address expectedSenderAddress = Address.parse(sender);
  final BigInt blockchainAmount = amount.extractDecimals(coinDecimals);
  final SendTransactionBloc sendTransactionBloc = SendTransactionBloc();

  final AccountInfo accountInfo = await app.zenon!.ledger
      .getAccountInfoByAddress(expectedSenderAddress);
  expect(
    accountInfo.getBalance(znnZts),
    greaterThanOrEqualTo(blockchainAmount),
    reason: 'Devnet sender does not have enough ZNN for the test transfer',
  );

  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: BlocProvider<SendTransactionBloc>.value(
          value: sendTransactionBloc,
          child: SendPopulated(
            balances: <String, AccountInfo>{
              expectedSenderAddress.toString(): accountInfo,
            },
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  await tester.enterText(
    find.byKey(const Key('send_recipient_field')),
    recipient,
  );
  await tester.enterText(find.byKey(const Key('send_amount_field')), amount);
  await tester.pumpAndSettle();

  await tester.tap(find.byKey(const Key('send_submit_button')));
  await tester.pumpAndSettle();

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
            state.error ?? StateError('Send transaction failed'),
          );
        }
      });

  try {
    await tester.tap(find.byKey(const Key('dialog_yes_button')));
    context.sentBlock = await _pumpUntilComplete(
      tester,
      completer.future,
    );
  } finally {
    await subscription.cancel();
  }
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
    throw TimeoutException('Timed out waiting for send transaction success');
  }
  if (error != null) {
    Error.throwWithStackTrace(error!, stackTrace!);
  }
  return result as T;
}
