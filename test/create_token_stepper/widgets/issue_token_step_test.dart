import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/l10n/app_localizations.dart';
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';

class MockIssueTokenBloc extends MockBloc<IssueTokenEvent, IssueTokenState>
    implements IssueTokenBloc {}

void main() {
  group('IssueTokenStep', () {
    late MockIssueTokenBloc issueTokenBloc;
    late ValueNotifier<NewTokenData> tokenData;

    setUp(() {
      issueTokenBloc = MockIssueTokenBloc();
      when(() => issueTokenBloc.state).thenReturn(const IssueTokenInitial());
      tokenData = ValueNotifier<NewTokenData>(
        NewTokenData(
          address: 'z1qq6eg8n43g032hanpsfp02qcdmv7zfj3y2lt5d',
          tokenName: 'Token',
          tokenSymbol: 'TKN',
          tokenDomain: 'example.com',
          totalSupply: BigInt.one,
          decimals: 0,
          maxSupply: BigInt.one,
          isMintable: false,
          isBurnable: false,
          isUtility: true,
        ),
      );
    });

    tearDown(() async {
      tokenData.dispose();
      await issueTokenBloc.close();
    });

    testWidgets(
      'submits utility value changed by the checkbox',
      (WidgetTester tester) async {
        NewTokenData? submittedTokenData;

        await _pumpIssueTokenStep(
          tester,
          issueTokenBloc: issueTokenBloc,
          tokenData: tokenData,
          onIssuePressed: () {
            submittedTokenData = tokenData.value;
          },
        );

        await tester.tap(find.byKey(const Key('token_utility_checkbox')));
        await tester.pump();
        await tester.tap(
          find.descendant(
            of: find.byKey(const Key('token_create_button')),
            matching: find.byType(OutlinedButton),
          ),
        );

        expect(submittedTokenData, isNotNull);
        expect(submittedTokenData!.isUtility, isFalse);
      },
    );
  });
}

Future<void> _pumpIssueTokenStep(
  WidgetTester tester, {
  required IssueTokenBloc issueTokenBloc,
  required ValueNotifier<NewTokenData> tokenData,
  required VoidCallback onIssuePressed,
}) async {
  await tester.pumpWidget(
    BlocProvider<IssueTokenBloc>.value(
      value: issueTokenBloc,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SizedBox(
            width: 700,
            height: 500,
            child: IssueTokenStep(
              onBackPressed: () {},
              onIssueDone: () {},
              onIssuePressed: onIssuePressed,
              tokenData: tokenData,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}
