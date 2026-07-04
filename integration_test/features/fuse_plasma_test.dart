// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@Tags(['chain'])
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../integration_test/bdd_hooks/hooks.dart';
import './../steps/address_is_selected_for_plasma_fusion.dart';
import './../steps/i_fuse_qsr_to.dart';
import './../steps/the_published_fuse_block_should_match_and_qsr.dart';
import './../steps/address_should_have_at_least_plasma.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await Hooks.beforeAll();
  });
  tearDownAll(() async {
    await Hooks.afterAll();
  });

  group('''Fuse plasma''', () {
    Future<void> beforeEach(String title, [List<String>? tags]) async {
      await Hooks.beforeEach(title, tags);
    }

    Future<void> afterEach(String title, bool success,
        [List<String>? tags]) async {
      await Hooks.afterEach(title, success, tags);
    }

    testWidgets(
        '''Outline: Fusing QSR publishes the expected plasma block ('z1qp3yph55qgresyytz83anynr2f4z39x2z3ej3e', 'z1qp3yph55qgresyytz83anynr2f4z39x2z3ej3e', '120', '252000')''',
        (tester) async {
      var success = true;
      try {
        await beforeEach(
            '''Outline: Fusing QSR publishes the expected plasma block ('z1qp3yph55qgresyytz83anynr2f4z39x2z3ej3e', 'z1qp3yph55qgresyytz83anynr2f4z39x2z3ej3e', '120', '252000')''');
        await addressIsSelectedForPlasmaFusion(
            tester, 'z1qp3yph55qgresyytz83anynr2f4z39x2z3ej3e');
        await iFuseQsrTo(
            tester, '120', 'z1qp3yph55qgresyytz83anynr2f4z39x2z3ej3e');
        await thePublishedFuseBlockShouldMatchAndQsr(
            tester,
            'z1qp3yph55qgresyytz83anynr2f4z39x2z3ej3e',
            'z1qp3yph55qgresyytz83anynr2f4z39x2z3ej3e',
            '120');
        await addressShouldHaveAtLeastPlasma(
            tester, 'z1qp3yph55qgresyytz83anynr2f4z39x2z3ej3e', '252000');
      } catch (_) {
        success = false;
        rethrow;
      } finally {
        await afterEach(
          '''Outline: Fusing QSR publishes the expected plasma block ('z1qp3yph55qgresyytz83anynr2f4z39x2z3ej3e', 'z1qp3yph55qgresyytz83anynr2f4z39x2z3ej3e', '120', '252000')''',
          success,
        );
      }
    });
  });
}
