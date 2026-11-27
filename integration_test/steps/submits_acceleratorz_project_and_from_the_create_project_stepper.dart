// BDD Usage comments intentionally mirror Gherkin placeholders.
// ignore_for_file: unintended_html_in_doc_comment, lines_longer_than_80_chars

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zenon_syrius_wallet_flutter/l10n/app_localizations.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart' as app;
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

import '../support/accelerator_devnet_helpers.dart';
import '../support/devnet_test_context.dart';

/// Usage: <owner_address> submits Accelerator-Z project <name>, <description>, <url>, <znn_funds>, and <qsr_funds> from the Create Project stepper
Future<void> submitsAcceleratorzProjectAndFromTheCreateProjectStepper(
  WidgetTester tester,
  String ownerAddress,
  String name,
  String description,
  String url,
  String znnFunds,
  String qsrFunds,
) async {
  final AcceleratorDevnetContext acceleratorContext =
      requireAcceleratorDevnetContext();
  selectDevnetSender(ownerAddress);

  StreamSubscription<CreateProjectState>? subscription;
  try {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: BlocProvider<MultipleBalanceBloc>.value(
            value: app.sl<MultipleBalanceBloc>(),
            child: const CreateProjectStepperPage(),
          ),
        ),
      ),
    );
    await tester.pump();

    final Finder step1Continue = find.byKey(
      const Key('create_project_step1_continue_button'),
    );
    await pumpUntilAcceleratorFound(
      tester,
      step1Continue,
      description: 'Create Project step 1 Continue button',
    );
    await tester.ensureVisible(step1Continue);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(step1Continue);
    await tester.pump(const Duration(milliseconds: 200));

    final Finder nameField = find.byKey(const Key('create_project_name_field'));
    await pumpUntilAcceleratorFound(
      tester,
      nameField,
      description: 'Create Project name input field',
    );
    await tester.enterText(nameField, name);
    await tester.enterText(
      find.byKey(const Key('create_project_description_field')),
      description,
    );
    await tester.enterText(
      find.byKey(const Key('create_project_url_field')),
      url,
    );
    await tester.enterText(
      find.byKey(const Key('create_project_znn_amount_field')),
      znnFunds,
    );
    await tester.enterText(
      find.byKey(const Key('create_project_qsr_amount_field')),
      qsrFunds,
    );
    await tester.pump(const Duration(milliseconds: 200));

    final Finder step2Continue = find.byKey(
      const Key('create_project_step2_continue_button'),
    );
    await pumpUntilAcceleratorFound(
      tester,
      step2Continue,
      description: 'Create Project step 2 Continue button',
    );
    await tester.ensureVisible(step2Continue);
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(step2Continue);
    await tester.pump(const Duration(milliseconds: 200));

    final Finder submitContainer = find.byKey(
      const Key('create_project_submit_button'),
    );
    await pumpUntilAcceleratorFound(
      tester,
      submitContainer,
      description: 'Create Project Submit button',
    );
    final Finder submitButton = find.descendant(
      of: submitContainer,
      matching: find.byType(LoadingButton),
    );
    await tester.ensureVisible(submitButton);
    await tester.pump(const Duration(milliseconds: 100));

    final CreateProjectBloc createProjectBloc = tester
        .element(submitContainer)
        .read<CreateProjectBloc>();
    final Completer<AccountBlockTemplate> completer =
        Completer<AccountBlockTemplate>();
    subscription = createProjectBloc.stream.listen((CreateProjectState state) {
      if (state is CreateProjectDone && !completer.isCompleted) {
        completer.complete(state.accountBlock);
      } else if (state is CreateProjectFailure && !completer.isCompleted) {
        completer.completeError(state.exception);
      }
    });

    await tester.tap(submitButton);
    final AccountBlockTemplate publishedBlock =
        await pumpUntilAcceleratorComplete<AccountBlockTemplate>(
          tester,
          completer.future,
          'CreateProjectBloc submission',
        );

    acceleratorContext
      ..createProjectBlock = publishedBlock
      ..projectId = publishedBlock.hash;
  } finally {
    await subscription?.cancel();
    await tester.pumpWidget(const SizedBox.shrink());
  }
}
