import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart' as app;
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

import '../support/devnet_test_context.dart';

/// Usage: the devnet node is running
Future<void> theDevnetNodeIsRunning(WidgetTester tester) async {
  expect(
    devnetEnv('RUN_CHAIN_TESTS', 'true'),
    'true',
    reason: 'Set RUN_CHAIN_TESTS=true to run blockchain integration tests',
  );

  app.zenon ??= Zenon();
  if (app.sl.isRegistered<DevnetTestContext>()) {
    await app.sl.unregister<DevnetTestContext>();
  }
  app.sl.registerSingleton<DevnetTestContext>(DevnetTestContext());

  final String nodeUrl = devnetEnv(
    'ZNN_TEST_NODE_URL',
    DevnetTestContext.defaultNodeUrl,
  );
  final bool connected = await app.zenon!.wsClient
      .initialize(nodeUrl, retry: false)
      .timeout(const Duration(seconds: 15));

  expect(
    connected,
    isTrue,
    reason: 'Could not connect to devnet at $nodeUrl',
  );

  final Momentum momentum = await app.zenon!.ledger.getFrontierMomentum();
  expect(
    momentum.chainIdentifier,
    DevnetTestContext.chainId,
    reason:
        'Integration tests must run against docker devnet chain ID ${DevnetTestContext.chainId}',
  );
  setChainIdentifier(chainIdentifier: momentum.chainIdentifier);
}
