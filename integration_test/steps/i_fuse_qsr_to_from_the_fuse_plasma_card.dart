// BDD Usage comments intentionally mirror Gherkin placeholders.
// ignore_for_file: unintended_html_in_doc_comment, non_constant_identifier_names

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nested/nested.dart';
import 'package:provider/provider.dart';
import 'package:zenon_syrius_wallet_flutter/l10n/app_localizations.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart' as app;
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

import '../support/devnet_test_context.dart';

/// Usage: I fuse <amount> QSR to <fuse_address> from the Fuse Plasma card
Future<void> iFuseQsrToFromTheFusePlasmaCard(
  WidgetTester tester,
  dynamic amount,
  dynamic fuse_address,
) async {
  final DevnetTestContext context = app.sl<DevnetTestContext>();
  final String fuseAmount = amount as String;
  final String fuseAddress = fuse_address as String;

  selectDevnetSender(fuseAddress);

  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: MultiProvider(
        providers: <SingleChildWidget>[
          ChangeNotifierProvider<SelectedAddressNotifier>(
            create: (_) => SelectedAddressNotifier(),
          ),
        ],
        child: MultiBlocProvider(
          providers: <SingleChildWidget>[
            BlocProvider<MultipleBalanceBloc>.value(
              value: app.sl<MultipleBalanceBloc>(),
            ),
            BlocProvider<PlasmaBeneficiaryAddressCubit>(
              create: (_) => PlasmaBeneficiaryAddressCubit(),
            ),
            BlocProvider<PlasmaStatsBloc>.value(
              value: app.sl<PlasmaStatsBloc>(),
            ),
          ],
          child: Scaffold(
            body: FusePlasmaCard(
              plasmaStatsResults: const <PlasmaInfoWrapper>[],
              onPlasmaFused: () {},
            ),
          ),
        ),
      ),
    ),
  );
  app.sl<MultipleBalanceBloc>().add(
    MultipleBalanceFetch(addresses: <String>[fuseAddress]),
  );
  await tester.pumpAndSettle();

  await tester.enterText(
    find.byKey(const Key('fuse_plasma_amount_field')),
    fuseAmount,
  );
  await tester.enterText(
    find.byKey(const Key('fuse_plasma_beneficiary_address_field')),
    fuseAddress,
  );
  await tester.pumpAndSettle();

  final Finder submitButton = find.byKey(
    const Key('fuse_plasma_submit_button'),
  );
  await _pumpUntilFound(tester, submitButton);
  await tester.ensureVisible(submitButton);
  await tester.pumpAndSettle();

  final FusePlasmaBloc fusePlasmaBloc = tester
      .element(submitButton)
      .read<FusePlasmaBloc>();
  final Completer<AccountBlockTemplate> completer =
      Completer<AccountBlockTemplate>();
  final StreamSubscription<FusePlasmaState> subscription = fusePlasmaBloc.stream
      .listen((FusePlasmaState state) {
        if (state is FusePlasmaDone && !completer.isCompleted) {
          completer.complete(state.accountBlock);
        } else if (state is FusePlasmaFailure && !completer.isCompleted) {
          completer.completeError(state.exception);
        }
      });

  try {
    await tester.tap(submitButton);
    context
      ..plasmaFuseAmount = fuseAmount.extractDecimals(coinDecimals)
      ..plasmaFuseBlock = await _pumpUntilComplete(
        tester,
        completer.future,
        'plasma fusion success',
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
