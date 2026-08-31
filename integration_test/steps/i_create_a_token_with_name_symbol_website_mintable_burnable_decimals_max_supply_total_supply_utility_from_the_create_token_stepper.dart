// BDD Usage comments intentionally mirror Gherkin placeholders.
// ignore_for_file: unintended_html_in_doc_comment, non_constant_identifier_names

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

/// Usage: I create a token with name <token_name>, symbol <token_symbol>, website <website>, mintable <mintable>, burnable <burnable>, decimals <decimals>, max supply <max_supply>, total supply <total_supply>, utility <utility> from the Create Token stepper
Future<void>
iCreateATokenWithNameSymbolWebsiteMintableBurnableDecimalsMaxSupplyTotalSupplyUtilityFromTheCreateTokenStepper(
  WidgetTester tester,
  dynamic token_name,
  dynamic token_symbol,
  dynamic website,
  dynamic mintable,
  dynamic burnable,
  dynamic decimals,
  dynamic max_supply,
  dynamic total_supply,
  dynamic utility,
) async {
  final DevnetTestContext context = app.sl<DevnetTestContext>();
  final String tokenName = token_name as String;
  final String tokenSymbol = token_symbol as String;
  final String tokenWebsite = website as String;
  final bool isMintable = bool.parse(mintable as String);
  final bool isBurnable = bool.parse(burnable as String);
  final int tokenDecimals = int.parse(decimals as String);
  final String maxSupply = max_supply as String;
  final String totalSupply = total_supply as String;
  final bool isUtility = bool.parse(utility as String);

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
    tokenName,
  );
  await _enterText(
    tester,
    const Key('token_symbol_field'),
    tokenSymbol,
  );
  await _enterText(
    tester,
    const Key('token_domain_field'),
    tokenWebsite,
  );
  await _tapAndSettle(tester, const Key('token_details_next_button'));

  await _setCheckbox(
    tester,
    const Key('token_mintable_checkbox'),
    value: isMintable,
  );
  await _setCheckbox(
    tester,
    const Key('token_burnable_checkbox'),
    value: isBurnable,
  );
  await _tapAndSettle(tester, const Key('token_options_next_button'));

  await _pumpUntilFound(
    tester,
    find.byKey(const Key('token_decimals_slider')),
  );
  final Slider decimalsSlider = tester.widget<Slider>(
    find.byKey(const Key('token_decimals_slider')),
  );
  decimalsSlider.onChanged!(tokenDecimals.toDouble());
  await tester.pumpAndSettle();

  await _enterText(
    tester,
    const Key('token_max_supply_field'),
    maxSupply,
  );
  await _enterText(
    tester,
    const Key('token_total_supply_field'),
    totalSupply,
  );
  await _tapAndSettle(tester, const Key('token_metrics_next_button'));

  await _setCheckbox(
    tester,
    const Key('token_utility_checkbox'),
    value: isUtility,
  );

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
