// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@Tags(['chain'])
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../integration_test/bdd_hooks/hooks.dart';
import '../../integration_test/steps/is_prepared_for_issuing_a_token.dart';
import '../../integration_test/steps/i_create_a_token_with_name_symbol_website_mintable_burnable_decimals_max_supply_total_supply_utility_from_the_create_token_stepper.dart';
import '../../integration_test/steps/the_returned_issue_block_from_should_contain_and.dart';

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
      '''Outline: Creating a token through the stepper issues the expected token ('z1qq6eg8n43g032hanpsfp02qcdmv7zfj3y2lt5d', 'newToken', 'TKK', 'testing.com', 'true', 'true', '3', '100', '90', 'false')''',
      (tester) async {
        var success = true;
        try {
          await beforeEach(
            '''Outline: Creating a token through the stepper issues the expected token ('z1qq6eg8n43g032hanpsfp02qcdmv7zfj3y2lt5d', 'newToken', 'TKK', 'testing.com', 'true', 'true', '3', '100', '90', 'false')''',
          );
          await isPreparedForIssuingAToken(
            tester,
            'z1qq6eg8n43g032hanpsfp02qcdmv7zfj3y2lt5d',
          );
          await iCreateATokenWithNameSymbolWebsiteMintableBurnableDecimalsMaxSupplyTotalSupplyUtilityFromTheCreateTokenStepper(
            tester,
            'newToken',
            'TKK',
            'testing.com',
            'true',
            'true',
            '3',
            '100',
            '90',
            'false',
          );
          await theReturnedIssueBlockFromShouldContainAnd(
            tester,
            'z1qq6eg8n43g032hanpsfp02qcdmv7zfj3y2lt5d',
            'newToken',
            'TKK',
            'testing.com',
            'true',
            'true',
            '3',
            '100',
            '90',
            'false',
          );
        } catch (_) {
          success = false;
          rethrow;
        } finally {
          await afterEach(
            '''Outline: Creating a token through the stepper issues the expected token ('z1qq6eg8n43g032hanpsfp02qcdmv7zfj3y2lt5d', 'newToken', 'TKK', 'testing.com', 'true', 'true', '3', '100', '90', 'false')''',
            success,
          );
        }
      },
    );
  });
}
