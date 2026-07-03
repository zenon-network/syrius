// BDD Usage comments intentionally mirror Gherkin placeholders.
// ignore_for_file: unintended_html_in_doc_comment

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart' as app;
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// Usage: <beneficiary> address should have at least <required_plasma> plasma
Future<void> addressShouldHaveAtLeastPlasma(
  WidgetTester tester,
  String beneficiary,
  String requiredPlasma,
) async {
  final int requiredPlasmaAmount = int.parse(requiredPlasma);
  final PlasmaInfo plasmaInfo = await _poll<PlasmaInfo>(
    () => app.zenon!.embedded.plasma.get(Address.parse(beneficiary)),
    isReady: (PlasmaInfo value) =>
        value.currentPlasma >= requiredPlasmaAmount,
    description: '$beneficiary plasma to reach $requiredPlasmaAmount',
  );

  expect(plasmaInfo.currentPlasma, greaterThanOrEqualTo(requiredPlasmaAmount));
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
