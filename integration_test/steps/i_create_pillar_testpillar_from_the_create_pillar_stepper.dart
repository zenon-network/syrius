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

/// Usage: I create pillar testPillar from the Create Pillar stepper
Future<void> iCreatePillarTestpillarFromTheCreatePillarStepper(
  WidgetTester tester,
) async {
  final DevnetTestContext context = app.sl<DevnetTestContext>();
  selectDevnetSender(DevnetTestContext.testPillarOwnerAddress);

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

  await _tapAndSettle(tester, const Key('pillar_plasma_next_button'));
  await _completeQsrStep(tester, context);
  await _tapAndSettle(tester, const Key('pillar_znn_next_button'));

  await _pumpUntilFound(tester, find.byKey(const Key('pillar_name_field')));
  await tester.enterText(
    find.byKey(const Key('pillar_name_field')),
    DevnetTestContext.testPillarName,
  );
  await tester.enterText(
    find.byKey(const Key('pillar_reward_address_field')),
    DevnetTestContext.testPillarRewardAddress,
  );
  await tester.enterText(
    find.byKey(const Key('pillar_producer_address_field')),
    DevnetTestContext.testPillarProducerAddress,
  );
  _setSliderValue(
    tester,
    const Key('pillar_momentum_reward_slider'),
    DevnetTestContext.testPillarMomentumReward,
  );
  _setSliderValue(
    tester,
    const Key('pillar_delegation_reward_slider'),
    DevnetTestContext.testPillarDelegationReward,
  );
  await tester.pumpAndSettle();

  final Finder registerButton = find.byKey(const Key('pillar_register_button'));
  await _pumpUntilFound(tester, registerButton);
  await tester.ensureVisible(registerButton);
  await tester.pumpAndSettle();
  final DeployPillarBloc deployPillarBloc = tester
      .element(registerButton)
      .read<DeployPillarBloc>();
  final Completer<AccountBlockTemplate> completer =
      Completer<AccountBlockTemplate>();
  final StreamSubscription<DeployPillarState> subscription = deployPillarBloc
      .stream
      .listen((DeployPillarState state) {
        if (state is DeployPillarDone && !completer.isCompleted) {
          completer.complete(state.accountBlock);
        } else if (state is DeployPillarFailure && !completer.isCompleted) {
          completer.completeError(state.exception);
        }
      });

  try {
    await tester.tap(registerButton);
    context.deployPillarBlock = await _pumpUntilComplete(
      tester,
      completer.future,
      'pillar registration success',
    );
  } finally {
    await subscription.cancel();
  }
}

Future<void> _completeQsrStep(
  WidgetTester tester,
  DevnetTestContext context,
) async {
  final Finder qsrNextButton = find.byKey(const Key('pillar_qsr_next_button'));
  final Finder qsrAmountField = find.byKey(
    const Key('pillar_qsr_amount_field'),
  );
  await _pumpUntilAnyFound(tester, <Finder>[qsrNextButton, qsrAmountField]);

  if (qsrAmountField.evaluate().isNotEmpty) {
    final TextFormField amountField = tester.widget<TextFormField>(
      qsrAmountField,
    );
    final BigInt depositAmount = amountField.controller!.text.extractDecimals(
      coinDecimals,
    );
    expect(depositAmount, greaterThan(BigInt.zero));

    final Finder depositButton = find.byKey(
      const Key('pillar_qsr_deposit_button'),
    );
    await _pumpUntilFound(tester, depositButton);
    context.pillarQsrDepositAmount = depositAmount;

    await tester.tap(depositButton);
    await tester.pump();
    await _pumpUntilFound(tester, qsrNextButton);
  }

  await _tapAndSettle(tester, const Key('pillar_qsr_next_button'));
}

Future<void> _tapAndSettle(WidgetTester tester, Key key) async {
  final Finder finder = find.byKey(key);
  await _pumpUntilFound(tester, finder);
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

void _setSliderValue(WidgetTester tester, Key key, int value) {
  final Slider slider = tester.widget<Slider>(find.byKey(key));
  slider.onChanged!(value.toDouble());
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
