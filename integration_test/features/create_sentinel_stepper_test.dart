// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@Tags(['chain'])
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../integration_test/bdd_hooks/hooks.dart';
import './../steps/devnet_sentinel_owner_is_prepared_for_creating_a_sentinel.dart';
import './../steps/i_create_a_sentinel_from_the_create_sentinel_stepper_for.dart';
import './../steps/the_blockchain_should_contain_a_sentinel_for.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await Hooks.beforeAll();
  });
  tearDownAll(() async {
    await Hooks.afterAll();
  });

  group('''Create sentinel stepper''', () {
    Future<void> beforeEach(String title, [List<String>? tags]) async {
      await Hooks.beforeEach(title, tags);
    }

    Future<void> afterEach(String title, bool success,
        [List<String>? tags]) async {
      await Hooks.afterEach(title, success, tags);
    }

    testWidgets(
        '''Outline: Creating a sentinel through the stepper registers the expected sentinel ('z1qq6eg8n43g032hanpsfp02qcdmv7zfj3y2lt5d')''',
        (tester) async {
      var success = true;
      try {
        await beforeEach(
            '''Outline: Creating a sentinel through the stepper registers the expected sentinel ('z1qq6eg8n43g032hanpsfp02qcdmv7zfj3y2lt5d')''');
        await devnetSentinelOwnerIsPreparedForCreatingASentinel(
            tester, 'z1qq6eg8n43g032hanpsfp02qcdmv7zfj3y2lt5d');
        await iCreateASentinelFromTheCreateSentinelStepperFor(
            tester, 'z1qq6eg8n43g032hanpsfp02qcdmv7zfj3y2lt5d');
        await theBlockchainShouldContainASentinelFor(
            tester, 'z1qq6eg8n43g032hanpsfp02qcdmv7zfj3y2lt5d');
      } catch (_) {
        success = false;
        rethrow;
      } finally {
        await afterEach(
          '''Outline: Creating a sentinel through the stepper registers the expected sentinel ('z1qq6eg8n43g032hanpsfp02qcdmv7zfj3y2lt5d')''',
          success,
        );
      }
    });
  });
}
