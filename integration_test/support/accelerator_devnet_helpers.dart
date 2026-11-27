import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart' as app;
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

import 'devnet_test_context.dart';

/// Genesis Pillar 1 owner address with pre-fused devnet plasma for setup.
const String kAcceleratorPlasmaFuserAddress =
    'z1qq6eg8n43g032hanpsfp02qcdmv7zfj3y2lt5d';

/// Minimum plasma target for fast devnet Accelerator-Z transactions.
const int kAcceleratorMinPlasma = 84000;

/// QSR amount fused during test setup when an address needs plasma
/// (50 QSR = 105,000 plasma on Zenon).
const String kAcceleratorSetupQsrFuseAmount = '50';

AcceleratorDevnetContext? _activeAcceleratorContext;

/// Returns the active [AcceleratorDevnetContext] for the running scenario.
AcceleratorDevnetContext requireAcceleratorDevnetContext() {
  final AcceleratorDevnetContext? current = _activeAcceleratorContext;
  if (current == null) {
    throw StateError(
      'AcceleratorDevnetContext has not been initialized for this scenario',
    );
  }
  return current;
}

/// Manages scenario state and global teardown for the Accelerator-Z devnet BDD
/// integration test.
class AcceleratorDevnetContext {
  /// Creates and registers a fresh [AcceleratorDevnetContext] with teardown.
  factory AcceleratorDevnetContext.create() {
    _activeAcceleratorContext?.dispose();
    final AcceleratorDevnetContext context = AcceleratorDevnetContext._(
      savedSelectedAddress: kSelectedAddress,
      savedNumOfPillars: kNumOfPillars,
    );
    _activeAcceleratorContext = context;
    addTearDown(context.dispose);
    return context;
  }

  AcceleratorDevnetContext._({
    required this._savedSelectedAddress,
    required this._savedNumOfPillars,
  });

  final String? _savedSelectedAddress;
  final int? _savedNumOfPillars;
  bool _disposed = false;

  /// Published `CreateProject` account block returned by `CreateProjectBloc`.
  AccountBlockTemplate? createProjectBlock;

  /// On-chain Accelerator-Z project identifier (`createProjectBlock.hash`).
  Hash? projectId;

  /// Confirmed on-chain [Project] fetched after submission.
  Project? submittedProject;

  /// Published producer vote block (`VoteByProdAddress`).
  AccountBlockTemplate? producerVoteBlock;

  /// Published owner vote block (`VoteByName`).
  AccountBlockTemplate? ownerVoteBlock;

  /// Restores wallet globals touched during the scenario.
  void dispose() {
    if (_disposed) {
      return;
    }
    _disposed = true;
    kSelectedAddress = _savedSelectedAddress;
    kNumOfPillars = _savedNumOfPillars;
    if (identical(_activeAcceleratorContext, this)) {
      _activeAcceleratorContext = null;
    }
  }
}

/// Ensures [targetAddress] has at least [requiredPlasma] on devnet by fusing
/// QSR from [kAcceleratorPlasmaFuserAddress] when needed.
Future<void> ensureAcceleratorPlasma(
  String targetAddress, {
  int requiredPlasma = kAcceleratorMinPlasma,
  String fuseAmountQsr = kAcceleratorSetupQsrFuseAmount,
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
  selectDevnetSender(kAcceleratorPlasmaFuserAddress);
  try {
    final AccountBlockUtils accountBlockUtils = AccountBlockUtils(
      publishSuccessNotification: false,
    );
    await accountBlockUtils.createAccountBlock(
      app.zenon!.embedded.plasma.fuse(parsedTarget, fuseAmount),
      'fuse plasma for accelerator test',
      address: Address.parse(kAcceleratorPlasmaFuserAddress),
      waitForRequiredPlasma: true,
    );
  } finally {
    if (previousSelected != null) {
      selectDevnetSender(previousSelected);
    }
  }

  await pollAccelerator<PlasmaInfo>(
    () => app.zenon!.embedded.plasma.get(parsedTarget),
    isReady: (PlasmaInfo info) => info.currentPlasma >= requiredPlasma,
    description: '$targetAddress plasma to reach $requiredPlasma',
  );
}

/// Polls [fetch] every second until [isReady] returns true or [timeout]
/// elapses.
Future<T> pollAccelerator<T>(
  Future<T> Function() fetch, {
  required bool Function(T value) isReady,
  required String description,
  Duration timeout = const Duration(seconds: 90),
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
Future<void> pumpUntilAcceleratorFound(
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
Future<T> pumpUntilAcceleratorComplete<T>(
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
