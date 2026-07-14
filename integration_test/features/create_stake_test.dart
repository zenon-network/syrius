// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@Tags(['chain'])
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../integration_test/bdd_hooks/hooks.dart';
import './../steps/address_has_funds_for_staking_znn.dart';
import './../steps/i_create_a_month_stake_of_znn_from.dart';
import './../steps/the_blockchain_should_contain_that_month_stake_of_znn_from.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await Hooks.beforeAll();
  });
  tearDownAll(() async {
    await Hooks.afterAll();
  });

  group('''Create stake''', () {
    Future<void> beforeEach(String title, [List<String>? tags]) async {
      await Hooks.beforeEach(title, tags);
    }

    Future<void> afterEach(String title, bool success,
        [List<String>? tags]) async {
      await Hooks.afterEach(title, success, tags);
    }

    testWidgets(
        '''Outline: Creating a stake from the wallet UI is recorded on-chain ('z1qq6eg8n43g032hanpsfp02qcdmv7zfj3y2lt5d', '3', '100')''',
        (tester) async {
      var success = true;
      try {
        await beforeEach(
            '''Outline: Creating a stake from the wallet UI is recorded on-chain ('z1qq6eg8n43g032hanpsfp02qcdmv7zfj3y2lt5d', '3', '100')''');
        await addressHasFundsForStakingZnn(
            tester, 'z1qq6eg8n43g032hanpsfp02qcdmv7zfj3y2lt5d', '100');
        await iCreateAMonthStakeOfZnnFrom(
            tester, '3', '100', 'z1qq6eg8n43g032hanpsfp02qcdmv7zfj3y2lt5d');
        await theBlockchainShouldContainThatMonthStakeOfZnnFrom(
            tester, '3', '100', 'z1qq6eg8n43g032hanpsfp02qcdmv7zfj3y2lt5d');
      } catch (_) {
        success = false;
        rethrow;
      } finally {
        await afterEach(
          '''Outline: Creating a stake from the wallet UI is recorded on-chain ('z1qq6eg8n43g032hanpsfp02qcdmv7zfj3y2lt5d', '3', '100')''',
          success,
        );
      }
    });
  });
}
