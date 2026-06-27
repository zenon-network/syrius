// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@Tags(['chain'])
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../integration_test/steps/the_devnet_node_is_running.dart';
import '../../integration_test/steps/sender_address_has_funds.dart';
import '../../integration_test/steps/i_send_znn_to_a_recipient_from_the_send_screen.dart';
import '../../integration_test/steps/the_blockchain_should_contain_that_znn_transfer.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('''Send ZNN on devnet''', () {
    testWidgets('''Sending ZNN from the wallet UI is recorded on-chain''',
        (tester) async {
      await theDevnetNodeIsRunning(tester);
      await senderAddressHasFunds(tester, 'z1qp3yph55qgresyytz83anynr2f4z39x2z3ej3e');
      await iSendZnnFromSenderAddressToRecipientAddressFromTheSendScreen(
        tester,
        '0.001',
        'z1qp3yph55qgresyytz83anynr2f4z39x2z3ej3e',
        'z1qpeet8dcjg0m6x6m3tg437wnc42aa2nez2fzth',
      );
      await theBlockchainShouldContainThatZnnTransferTo(
        tester,
        '0.001',
        'z1qpeet8dcjg0m6x6m3tg437wnc42aa2nez2fzth',
      );
    });
  });
}
