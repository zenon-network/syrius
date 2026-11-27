import 'dart:async';
import 'dart:ui' show Size;

import 'package:flutter_test/flutter_test.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart' as app;
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

import 'devnet_test_context.dart';

/// Genesis Pillar 1 owner address with pre-fused devnet plasma for test setup.
const String kDevnetPlasmaFuserAddress =
    'z1qq6eg8n43g032hanpsfp02qcdmv7zfj3y2lt5d';

/// Minimum plasma target for fast devnet contract calls without slow PoW.
const int kDevnetMinPlasma = 84000;

/// QSR amount fused during test setup when an address needs plasma
/// (50 QSR = 105,000 plasma on Zenon).
const String kDevnetSetupQsrFuseAmount = '50';

/// Ensures [targetAddress] has at least [requiredPlasma] on devnet by fusing
/// QSR from [kDevnetPlasmaFuserAddress] when needed.
Future<void> ensureDevnetPlasma(
  String targetAddress, {
  int requiredPlasma = kDevnetMinPlasma,
  String fuseAmountQsr = kDevnetSetupQsrFuseAmount,
  Future<void> Function()? prepareFuserWallet,
}) async {
  final Address parsedTarget = Address.parse(targetAddress);
  final PlasmaInfo currentPlasma = await app.zenon!.embedded.plasma.get(
    parsedTarget,
  );
  if (currentPlasma.currentPlasma >= requiredPlasma) {
    return;
  }

  final BigInt fuseAmount = fuseAmountQsr.extractDecimals(coinDecimals);
  final String? previousSelected = kSelectedAddress;
  if (prepareFuserWallet != null) {
    await prepareFuserWallet();
  } else {
    selectDevnetSender(kDevnetPlasmaFuserAddress);
  }
  try {
    final AccountBlockUtils accountBlockUtils = AccountBlockUtils(
      publishSuccessNotification: false,
    );
    await accountBlockUtils.createAccountBlock(
      app.zenon!.embedded.plasma.fuse(parsedTarget, fuseAmount),
      'fuse plasma for devnet bdd test',
      address: Address.parse(kDevnetPlasmaFuserAddress),
      waitForRequiredPlasma: true,
    );
  } finally {
    if (prepareFuserWallet == null && previousSelected != null) {
      selectDevnetSender(previousSelected);
    }
  }

  await pollDevnet<PlasmaInfo>(
    () => app.zenon!.embedded.plasma.get(parsedTarget),
    isReady: (PlasmaInfo info) => info.currentPlasma >= requiredPlasma,
    description: '$targetAddress plasma to reach $requiredPlasma',
  );
}

/// Configures a desktop-sized test viewport so `showCustomDialog` and modal
/// forms render at desktop proportions rather than `flutter-tester`'s 800x600
/// default, and restores the viewport on teardown.
void configureDesktopTestViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1400, 1000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

/// Polls [fetch] every second until [isReady] returns true or [timeout]
/// elapses.
Future<T> pollDevnet<T>(
  Future<T> Function() fetch, {
  required bool Function(T value) isReady,
  required String description,
  Duration timeout = const Duration(seconds: 150),
}) async {
  final DateTime deadline = DateTime.now().add(timeout);
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

/// Pumps frames until [finder] matches a widget.
Future<void> pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  String? description,
  Duration timeout = const Duration(seconds: 90),
}) async {
  final DateTime deadline = DateTime.now().add(timeout);
  while (finder.evaluate().isEmpty && DateTime.now().isBefore(deadline)) {
    await tester.pump(const Duration(milliseconds: 100));
  }

  expect(
    finder,
    findsOneWidget,
    reason: description ?? 'Expected widget $finder to appear',
  );
}

/// Pumps frames while waiting for [future] to complete.
Future<T> pumpUntilComplete<T>(
  WidgetTester tester,
  Future<T> future,
  String description, {
  Duration timeout = const Duration(seconds: 90),
}) async {
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

  final DateTime deadline = DateTime.now().add(timeout);
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
