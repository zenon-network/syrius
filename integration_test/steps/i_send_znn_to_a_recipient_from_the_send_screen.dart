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

/// Usage: I send {'0.001'} ZNN from sender address {'z1qp3yph55qgresyytz83anynr2f4z39x2z3ej3e'} to recipient address {'z1qpeet8dcjg0m6x6m3tg437wnc42aa2nez2fzth'} from the Send screen
Future<void> iSendZnnFromSenderAddressToRecipientAddressFromTheSendScreen(
  WidgetTester tester,
  String amount,
  String senderAddress,
  String recipientAddress,
) async {
  final DevnetTestContext context = app.sl<DevnetTestContext>();
  final Address expectedSenderAddress = Address.parse(senderAddress);
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
    recipientAddress,
  );
  await tester.enterText(find.byKey(const Key('send_amount_field')), amount);
  await tester.pumpAndSettle();

  await tester.tap(find.byKey(const Key('send_submit_button')));
  await tester.pumpAndSettle();

  final Completer<AccountBlockTemplate> completer =
      Completer<AccountBlockTemplate>();
  final StreamSubscription<SendTransactionState> subscription = sendTransactionBloc.stream
      .listen((SendTransactionState state) {
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
