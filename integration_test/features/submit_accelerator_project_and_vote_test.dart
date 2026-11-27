// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@Tags(['chain'])
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../../integration_test/bdd_hooks/hooks.dart';
import './../steps/is_prepared_for_submitting_an_acceleratorz_project.dart';
import './../steps/submits_acceleratorz_project_and_from_the_create_project_stepper.dart';
import './../steps/the_blockchain_should_contain_the_submitted_acceleratorz_project_with_and.dart';
import './../steps/pillar_producer_votes_yes_and_pillar_owner_votes_no_on_the_submitted_acceleratorz_project.dart';
import './../steps/the_blockchain_should_record_the_yes_vote_from_and_no_vote_from_on_the_submitted_acceleratorz_project.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await Hooks.beforeAll();
  });
  tearDownAll(() async {
    await Hooks.afterAll();
  });

  group('''Submit Accelerator-Z project and vote''', () {
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
      '''Outline: Submitting an Accelerator-Z project and casting Pillar votes through the UI ('z1qpeet8dcjg0m6x6m3tg437wnc42aa2nez2fzth', 'Devnet Accel Z', 'Verify Accelerator-Z create and vote', 'https://zenon.network', '10', '100', 'z1qq9n7fpaqd8lpcljandzmx4xtku9w4ftwyg0mq', 'dev1', 'z1qqleq9qc2u3039fly4ld5qgngdeapa3yks0e3l', 'dev2')''',
      (tester) async {
        var success = true;
        try {
          await beforeEach(
            '''Outline: Submitting an Accelerator-Z project and casting Pillar votes through the UI ('z1qpeet8dcjg0m6x6m3tg437wnc42aa2nez2fzth', 'Devnet Accel Z', 'Verify Accelerator-Z create and vote', 'https://zenon.network', '10', '100', 'z1qq9n7fpaqd8lpcljandzmx4xtku9w4ftwyg0mq', 'dev1', 'z1qqleq9qc2u3039fly4ld5qgngdeapa3yks0e3l', 'dev2')''',
          );
          await isPreparedForSubmittingAnAcceleratorzProject(
            tester,
            'z1qpeet8dcjg0m6x6m3tg437wnc42aa2nez2fzth',
          );
          await submitsAcceleratorzProjectAndFromTheCreateProjectStepper(
            tester,
            'z1qpeet8dcjg0m6x6m3tg437wnc42aa2nez2fzth',
            'Devnet Accel Z',
            'Verify Accelerator-Z create and vote',
            'https://zenon.network',
            '10',
            '100',
          );
          await theBlockchainShouldContainTheSubmittedAcceleratorzProjectWithAnd(
            tester,
            'Devnet Accel Z',
            'Verify Accelerator-Z create and vote',
            'https://zenon.network',
            '10',
            '100',
          );
          await pillarProducerVotesYesAndPillarOwnerVotesNoOnTheSubmittedAcceleratorzProject(
            tester,
            'z1qq9n7fpaqd8lpcljandzmx4xtku9w4ftwyg0mq',
            'z1qqleq9qc2u3039fly4ld5qgngdeapa3yks0e3l',
          );
          await theBlockchainShouldRecordTheYesVoteFromAndNoVoteFromOnTheSubmittedAcceleratorzProject(
            tester,
            'dev1',
            'dev2',
          );
        } catch (_) {
          success = false;
          rethrow;
        } finally {
          await afterEach(
            '''Outline: Submitting an Accelerator-Z project and casting Pillar votes through the UI ('z1qpeet8dcjg0m6x6m3tg437wnc42aa2nez2fzth', 'Devnet Accel Z', 'Verify Accelerator-Z create and vote', 'https://zenon.network', '10', '100', 'z1qq9n7fpaqd8lpcljandzmx4xtku9w4ftwyg0mq', 'dev1', 'z1qqleq9qc2u3039fly4ld5qgngdeapa3yks0e3l', 'dev2')''',
            success,
          );
        }
      },
    );
  });
}
