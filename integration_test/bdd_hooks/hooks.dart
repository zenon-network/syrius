// bdd_widget_test defines hook signatures with a positional success flag.
// ignore_for_file: avoid_positional_boolean_parameters

import 'dart:async';

import '../support/devnet_test_context.dart';

abstract class Hooks {
  const Hooks._();

  static Future<void> beforeAll() async {
    await initializeDevnetIntegrationTests();
  }

  static FutureOr<void> beforeEach(String title, [List<String>? tags]) {
    resetDevnetScenarioState();
  }

  static FutureOr<void> afterEach(
    String title,
    bool success, [
    List<String>? tags,
  ]) {}

  static FutureOr<void> afterAll() => disposeDevnetIntegrationTests();
}
