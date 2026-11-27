// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@Tags(['chain'])
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../integration_test/bdd_hooks/hooks.dart';
import './../steps/two_funded_devnet_participants_are_prepared_for_a_p2p_htlc_swap.dart';
import './../steps/the_initiator_starts_a_p2p_htlc_swap_of_znn_from_the_start_p2p_swap_modal.dart';
import './../steps/the_blockchain_should_contain_the_created_initial_htlc_with_the_submitted_swap_parameters.dart';
import './../steps/the_counterparty_joins_the_p2p_htlc_swap_with_znn_from_the_join_p2p_swap_modal.dart';
import './../steps/the_initiator_completes_the_p2p_htlc_swap_from_the_p2p_swap_modal.dart';
import './../steps/the_counterparty_wallet_automatically_unlocks_the_initial_htlc.dart';
import './../steps/the_blockchain_should_record_the_unlocked_htlc_swap_for_both_participants.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await Hooks.beforeAll();
  });
  tearDownAll(() async {
    await Hooks.afterAll();
  });

  group('''P2P Swap HTLC''', () {
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
      '''Outline: Creating, joining, and completing an HTLC swap through the P2P Swap UI ('0.25', '0.15')''',
      (tester) async {
        var success = true;
        try {
          await beforeEach(
            '''Outline: Creating, joining, and completing an HTLC swap through the P2P Swap UI ('0.25', '0.15')''',
          );
          await twoFundedDevnetParticipantsArePreparedForAP2pHtlcSwap(tester);
          await theInitiatorStartsAP2pHtlcSwapOfZnnFromTheStartP2pSwapModal(
            tester,
            '0.25',
          );
          await theBlockchainShouldContainTheCreatedInitialHtlcWithTheSubmittedSwapParameters(
            tester,
          );
          await theCounterpartyJoinsTheP2pHtlcSwapWithZnnFromTheJoinP2pSwapModal(
            tester,
            '0.15',
          );
          await theInitiatorCompletesTheP2pHtlcSwapFromTheP2pSwapModal(tester);
          await theCounterpartyWalletAutomaticallyUnlocksTheInitialHtlc(tester);
          await theBlockchainShouldRecordTheUnlockedHtlcSwapForBothParticipants(
            tester,
          );
        } catch (_) {
          success = false;
          rethrow;
        } finally {
          await afterEach(
            '''Outline: Creating, joining, and completing an HTLC swap through the P2P Swap UI ('0.25', '0.15')''',
            success,
          );
        }
      },
    );
  });
}
