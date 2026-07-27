// BDD Usage comments intentionally mirror Gherkin placeholders.
// ignore_for_file: unintended_html_in_doc_comment, lines_longer_than_80_chars

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart' as app;
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// Usage: the blockchain should contain a sentinel for <sentinel_owner>
Future<void> theBlockchainShouldContainASentinelFor(
  WidgetTester tester,
  String owner,
) async {
  final Address ownerAddress = Address.parse(owner);

  final SentinelInfo? sentinelInfo = await _poll<SentinelInfo?>(
    () => app.zenon!.embedded.sentinel.getByOwner(ownerAddress),
    isReady: (SentinelInfo? sentinelInfo) =>
        sentinelInfo != null && sentinelInfo.active,
    description: 'active sentinel for owner $owner',
  );

  expect(sentinelInfo, isNotNull);
  expect(sentinelInfo!.owner, ownerAddress);
  expect(sentinelInfo.active, isTrue);
}

Future<T> _poll<T>(
  Future<T> Function() fetch, {
  required bool Function(T value) isReady,
  required String description,
}) async {
  final DateTime deadline = DateTime.now().add(const Duration(seconds: 90));
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
