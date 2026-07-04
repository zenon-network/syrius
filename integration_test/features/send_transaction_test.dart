// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@Tags(['chain'])
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../integration_test/bdd_hooks/hooks.dart';
import './../steps/address_has_funds.dart';
import './../steps/i_send_znn_from_address_to_address_from_the_send_screen.dart';
import './../steps/the_blockchain_should_contain_that_znn_transfer_to.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await Hooks.beforeAll();
  });
  tearDownAll(() async {
    await Hooks.afterAll();
  });

  group('''Send ZNN on devnet''', () {
    Future<void> beforeEach(String title, [List<String>? tags]) async {
      await Hooks.beforeEach(title, tags);
    }

    Future<void> afterEach(String title, bool success,
        [List<String>? tags]) async {
      await Hooks.afterEach(title, success, tags);
    }

    testWidgets(
        '''Outline: Sending ZNN from the wallet UI is recorded on-chain ('z1qp3yph55qgresyytz83anynr2f4z39x2z3ej3e', 'z1qpeet8dcjg0m6x6m3tg437wnc42aa2nez2fzth', '0.001')''',
        (tester) async {
      var success = true;
      try {
        await beforeEach(
            '''Outline: Sending ZNN from the wallet UI is recorded on-chain ('z1qp3yph55qgresyytz83anynr2f4z39x2z3ej3e', 'z1qpeet8dcjg0m6x6m3tg437wnc42aa2nez2fzth', '0.001')''');
        await addressHasFunds(
            tester, 'z1qp3yph55qgresyytz83anynr2f4z39x2z3ej3e');
        await iSendZnnFromAddressToAddressFromTheSendScreen(
            tester,
            '0.001',
            'z1qp3yph55qgresyytz83anynr2f4z39x2z3ej3e',
            'z1qpeet8dcjg0m6x6m3tg437wnc42aa2nez2fzth');
        await theBlockchainShouldContainThatZnnTransferTo(
            tester, '0.001', 'z1qpeet8dcjg0m6x6m3tg437wnc42aa2nez2fzth');
      } catch (_) {
        success = false;
        rethrow;
      } finally {
        await afterEach(
          '''Outline: Sending ZNN from the wallet UI is recorded on-chain ('z1qp3yph55qgresyytz83anynr2f4z39x2z3ej3e', 'z1qpeet8dcjg0m6x6m3tg437wnc42aa2nez2fzth', '0.001')''',
          success,
        );
      }
    });
  });
}
