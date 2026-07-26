import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenon_syrius_wallet_flutter/l10n/app_localizations.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart' as app;
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

import '../support/devnet_test_context.dart';

/// Usage: I create NewToken from the Create Token stepper
Future<void> iCreateNewtokenFromTheCreateTokenStepper(
  WidgetTester tester,
) async {
  final DevnetTestContext context = app.sl<DevnetTestContext>();
  selectDevnetSender(DevnetTestContext.testTokenOwnerAddress);

  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: BlocProvider<MultipleBalanceBloc>.value(
          value: app.sl<MultipleBalanceBloc>(),
          child: BlocProvider<AllTokensBloc>(
            create: (_) => AllTokensBloc(zenon: app.zenon!),
            child: const CreateTokenStepperPage(),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  await _tapAndSettle(tester, const Key('token_plasma_next_button'));
  await _tapAndSettle(tester, const Key('token_znn_next_button'));

  await _enterText(
    tester,
    const Key('token_name_field'),
    DevnetTestContext.testTokenName,
  );
  await _enterText(
    tester,
    const Key('token_symbol_field'),
    DevnetTestContext.testTokenSymbol,
  );
  await _enterText(
    tester,
    const Key('token_domain_field'),
    DevnetTestContext.testTokenDomain,
  );
  await _tapAndSettle(tester, const Key('token_details_next_button'));

  await _setCheckbox(
    tester,
    const Key('token_mintable_checkbox'),
    value: true,
  );
  await _setCheckbox(
    tester,
    const Key('token_burnable_checkbox'),
    value: true,
  );
  await _tapAndSettle(tester, const Key('token_options_next_button'));

  await _pumpUntilFound(
    tester,
    find.byKey(const Key('token_decimals_slider')),
  );
  final Slider decimalsSlider = tester.widget<Slider>(
    find.byKey(const Key('token_decimals_slider')),
  );
  decimalsSlider.onChanged!(DevnetTestContext.testTokenDecimals.toDouble());
  await tester.pumpAndSettle();

  await _enterText(
    tester,
    const Key('token_max_supply_field'),
    DevnetTestContext.testTokenMaxSupply,
  );
  await _enterText(
    tester,
    const Key('token_total_supply_field'),
    DevnetTestContext.testTokenTotalSupply,
  );
  await _tapAndSettle(tester, const Key('token_metrics_next_button'));

  final Finder utilityCheckbox = find.byKey(
    const Key('token_utility_checkbox'),
  );
  await _pumpUntilFound(tester, utilityCheckbox);
  expect(tester.widget<Checkbox>(utilityCheckbox).value, isTrue);

  final Finder createButtonContainer = find.byKey(
    const Key('token_create_button'),
  );
  await _pumpUntilFound(tester, createButtonContainer);
  await tester.ensureVisible(createButtonContainer);
  await tester.pumpAndSettle();
  final Finder createButton = find.descendant(
    of: createButtonContainer,
    matching: find.byType(LoadingButton),
  );
  expect(createButton, findsOneWidget);

  final IssueTokenBloc issueTokenBloc = tester
      .element(createButton)
      .read<IssueTokenBloc>();
  final Completer<AccountBlockTemplate> completer =
      Completer<AccountBlockTemplate>();
  final StreamSubscription<IssueTokenState> subscription = issueTokenBloc.stream
      .listen((IssueTokenState state) {
        if (state is IssueTokenDone && !completer.isCompleted) {
          completer.complete(state.accountBlock);
        } else if (state is IssueTokenFailure && !completer.isCompleted) {
          completer.completeError(state.exception);
        }
      });

  try {
    await tester.tap(createButton);
    context.issueTokenBlock = await _pumpUntilComplete(
      tester,
      completer.future,
      'token issuance success',
    );
  } finally {
    await subscription.cancel();
  }

  await tester.pump();
  expect(find.byType(TokenCreatedSuccess), findsOneWidget);
}

Future<void> _enterText(WidgetTester tester, Key key, String value) async {
  final Finder finder = find.byKey(key);
  await _pumpUntilFound(tester, finder);
  await tester.ensureVisible(finder);
  await tester.enterText(finder, value);
  await tester.pumpAndSettle();
}

Future<void> _setCheckbox(
  WidgetTester tester,
  Key key, {
  required bool value,
}) async {
  final Finder finder = find.byKey(key);
  await _pumpUntilFound(tester, finder);
  await tester.ensureVisible(finder);
  if (tester.widget<Checkbox>(finder).value != value) {
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }
  expect(tester.widget<Checkbox>(finder).value, value);
}

Future<void> _tapAndSettle(WidgetTester tester, Key key) async {
  final Finder finder = find.byKey(key);
  await _pumpUntilFound(tester, finder);
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
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
