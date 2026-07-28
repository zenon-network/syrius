// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@Tags(['chain'])
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../integration_test/bdd_hooks/hooks.dart';
import './../steps/the_devnet_token_owner_is_prepared_for_issuing_newtoken.dart';
import './../steps/i_create_newtoken_from_the_create_token_stepper.dart';
import './../steps/the_blockchain_should_contain_newtoken_with_the_submitted_stepper_data.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await Hooks.beforeAll();
  });
  tearDownAll(() async {
    await Hooks.afterAll();
  });

  group('''Create token stepper''', () {
    Future<void> beforeEach(String title, [List<String>? tags]) async {
      await Hooks.beforeEach(title, tags);
    }

    Future<void> afterEach(
      String title,
      bool success, [
      List<String>? tags,
    ]) async {
      await Hooks.afterEach(title, success, tags);
    }

    testWidgets(
      '''Creating a token through the stepper issues the expected token''',
      (tester) async {
        var success = true;
        try {
          await beforeEach(
            '''Creating a token through the stepper issues the expected token''',
          );
          await theDevnetTokenOwnerIsPreparedForIssuingNewtoken(tester);
          await iCreateNewtokenFromTheCreateTokenStepper(tester);
          await theBlockchainShouldContainNewtokenWithTheSubmittedStepperData(
            tester,
          );
        } catch (_) {
          success = false;
          rethrow;
        } finally {
          await afterEach(
            '''Creating a token through the stepper issues the expected token''',
            success,
          );
        }
      },
    );
  });
}
