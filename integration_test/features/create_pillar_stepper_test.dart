// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@Tags(['chain'])
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../integration_test/bdd_hooks/hooks.dart';
import './../steps/the_devnet_pillar_owner_is_prepared_for_creating_testpillar.dart';
import './../steps/i_create_pillar_testpillar_from_the_create_pillar_stepper.dart';
import './../steps/the_blockchain_should_contain_pillar_testpillar_with_the_submitted_stepper_data.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await Hooks.beforeAll();
  });
  tearDownAll(() async {
    await Hooks.afterAll();
  });

  group('''Create pillar stepper''', () {
    Future<void> beforeEach(String title, [List<String>? tags]) async {
      await Hooks.beforeEach(title, tags);
    }

    Future<void> afterEach(String title, bool success,
        [List<String>? tags]) async {
      await Hooks.afterEach(title, success, tags);
    }

    testWidgets(
        '''Creating a pillar through the stepper registers the expected pillar''',
        (tester) async {
      var success = true;
      try {
        await beforeEach(
            '''Creating a pillar through the stepper registers the expected pillar''');
        await theDevnetPillarOwnerIsPreparedForCreatingTestpillar(tester);
        await iCreatePillarTestpillarFromTheCreatePillarStepper(tester);
        await theBlockchainShouldContainPillarTestpillarWithTheSubmittedStepperData(
            tester);
      } catch (_) {
        success = false;
        rethrow;
      } finally {
        await afterEach(
          '''Creating a pillar through the stepper registers the expected pillar''',
          success,
        );
      }
    });
  });
}
