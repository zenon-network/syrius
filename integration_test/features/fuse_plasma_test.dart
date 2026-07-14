// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@Tags(['chain'])
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../integration_test/bdd_hooks/hooks.dart';
import './../steps/address_has_funds_for_fusing_qsr.dart';
import './../steps/i_fuse_qsr_to_from_the_fuse_plasma_card.dart';
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

    Future<void> afterEach(
      String title,
      bool success, [
      List<String>? tags,
    ]) async {
      await Hooks.afterEach(title, success, tags);
    }

    testWidgets(
      '''Outline: Fusing QSR from the wallet UI is recorded on-chain ('z1qq6eg8n43g032hanpsfp02qcdmv7zfj3y2lt5d', '50', '105000')''',
      (tester) async {
        var success = true;
        try {
          await beforeEach(
            '''Outline: Fusing QSR from the wallet UI is recorded on-chain ('z1qq6eg8n43g032hanpsfp02qcdmv7zfj3y2lt5d', '50', '105000')''',
          );
          await addressHasFundsForFusingQsr(
            tester,
            'z1qq6eg8n43g032hanpsfp02qcdmv7zfj3y2lt5d',
            '50',
          );
          await iFuseQsrToFromTheFusePlasmaCard(
            tester,
            '50',
            'z1qq6eg8n43g032hanpsfp02qcdmv7zfj3y2lt5d',
          );
          await thePublishedFuseBlockShouldMatchAndQsr(
            tester,
            'z1qq6eg8n43g032hanpsfp02qcdmv7zfj3y2lt5d',
            'z1qq6eg8n43g032hanpsfp02qcdmv7zfj3y2lt5d',
            '50',
          );
          await addressShouldHaveAtLeastPlasma(
            tester,
            'z1qq6eg8n43g032hanpsfp02qcdmv7zfj3y2lt5d',
            '105000',
          );
        } catch (_) {
          success = false;
          rethrow;
        } finally {
          await afterEach(
            '''Outline: Fusing QSR from the wallet UI is recorded on-chain ('z1qq6eg8n43g032hanpsfp02qcdmv7zfj3y2lt5d', '50', '105000')''',
            success,
          );
        }
      },
    );
  });
}
