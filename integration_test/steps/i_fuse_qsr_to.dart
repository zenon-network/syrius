// BDD Usage comments intentionally mirror Gherkin placeholders.
// ignore_for_file: unintended_html_in_doc_comment

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart' as app;
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

import '../support/devnet_test_context.dart';

/// Usage: I fuse <qsr_amount> QSR to <beneficiary>
Future<void> iFuseQsrTo(
  WidgetTester tester,
  String qsrAmount,
  String beneficiary,
) async {
  final DevnetTestContext context = app.sl<DevnetTestContext>();
  final BigInt fuseAmount = qsrAmount.extractDecimals(coinDecimals);

  expect(
    fuseAmount,
    greaterThanOrEqualTo(fuseMinQsrAmount),
    reason: 'QSR fuse amount must be at least the protocol minimum',
  );

  final AccountInfo accountInfo = await app.zenon!.ledger
      .getAccountInfoByAddress(Address.parse(kSelectedAddress!));
  expect(
    accountInfo.getBalance(kQsrCoin.tokenStandard),
    greaterThanOrEqualTo(fuseAmount),
    reason: 'Selected devnet sender does not have enough QSR to fuse plasma',
  );

  final PlasmaOptionsBloc plasmaOptionsBloc = PlasmaOptionsBloc();
  final Completer<AccountBlockTemplate> completer =
      Completer<AccountBlockTemplate>();
  final StreamSubscription<AccountBlockTemplate?> subscription =
      plasmaOptionsBloc.stream.listen(
    (AccountBlockTemplate? block) {
      if (block != null && !completer.isCompleted) {
        completer.complete(block);
      }
    },
    onError: (Object error, StackTrace stackTrace) {
      if (!completer.isCompleted) {
        completer.completeError(error, stackTrace);
      }
    },
  );

  try {
    plasmaOptionsBloc.generatePlasma(beneficiary, fuseAmount);
    context.plasmaFuseAmount = fuseAmount;
    context.plasmaFuseBlock = await _pumpUntilComplete(
      tester,
      completer.future,
    );
  } finally {
    await subscription.cancel();
    plasmaOptionsBloc.dispose();
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
    throw TimeoutException('Timed out waiting for plasma fusion success');
  }
  if (error != null) {
    Error.throwWithStackTrace(error!, stackTrace!);
  }
  return result as T;
}
