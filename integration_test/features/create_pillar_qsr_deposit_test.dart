// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@Tags(['chain'])
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../integration_test/bdd_hooks/hooks.dart';
import './../steps/address_is_prepared_for_pillar_creation_with_at_least_plasma_using_qsr_if_needed.dart';
import './../steps/i_deposit_the_required_qsr_from_address_in_the_create_pillar_stepper.dart';
import './../steps/the_published_pillar_qsr_deposit_block_should_match.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await Hooks.beforeAll();
  });
  tearDownAll(() async {
    await Hooks.afterAll();
  });

  group('''Create pillar QSR deposit''', () {
    Future<void> beforeEach(String title, [List<String>? tags]) async {
      await Hooks.beforeEach(title, tags);
    }

    Future<void> afterEach(String title, bool success,
        [List<String>? tags]) async {
      await Hooks.afterEach(title, success, tags);
    }

    testWidgets(
        '''Outline: Depositing QSR for pillar creation publishes the expected block ('z1qp3yph55qgresyytz83anynr2f4z39x2z3ej3e', '252000', '120')''',
        (tester) async {
      var success = true;
      try {
        await beforeEach(
            '''Outline: Depositing QSR for pillar creation publishes the expected block ('z1qp3yph55qgresyytz83anynr2f4z39x2z3ej3e', '252000', '120')''');
        await addressIsPreparedForPillarCreationWithAtLeastPlasmaUsingQsrIfNeeded(
            tester,
            'z1qp3yph55qgresyytz83anynr2f4z39x2z3ej3e',
            '252000',
            '120');
        await iDepositTheRequiredQsrFromAddressInTheCreatePillarStepper(
            tester, 'z1qp3yph55qgresyytz83anynr2f4z39x2z3ej3e');
        await thePublishedPillarQsrDepositBlockShouldMatch(
            tester, 'z1qp3yph55qgresyytz83anynr2f4z39x2z3ej3e');
      } catch (_) {
        success = false;
        rethrow;
      } finally {
        await afterEach(
          '''Outline: Depositing QSR for pillar creation publishes the expected block ('z1qp3yph55qgresyytz83anynr2f4z39x2z3ej3e', '252000', '120')''',
          success,
        );
      }
    });
  });
}
