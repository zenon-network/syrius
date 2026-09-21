import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/l10n/app_localizations.dart';
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class MockIssueTokenBloc extends MockBloc<IssueTokenEvent, IssueTokenState>
    implements IssueTokenBloc {}

class MockFavoriteTokensRepository extends Mock
    implements FavoriteTokensRepository {}

class MockAccountBlockTemplate extends Mock implements AccountBlockTemplate {}

void main() {
  group('IssueTokenStep', () {
    late MockIssueTokenBloc issueTokenBloc;
    late MockFavoriteTokensRepository favoriteTokensRepository;
    late ValueNotifier<NewTokenData> tokenData;

    setUp(() {
      issueTokenBloc = MockIssueTokenBloc();
      favoriteTokensRepository = MockFavoriteTokensRepository();
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
          favoriteTokensRepository: favoriteTokensRepository,
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

    testWidgets('adds an issued token to favorites before completing', (
      WidgetTester tester,
    ) async {
      final MockAccountBlockTemplate accountBlock = MockAccountBlockTemplate();
      final TokenStandard newTokenStandard = TokenStandard.parse(
        'zts1zdl4pmr425t0j97v4eu0du',
      );
      final List<String> calls = <String>[];
      when(() => accountBlock.tokenStandard).thenReturn(znnZts);
      when(
        () => favoriteTokensRepository.add(newTokenStandard),
      ).thenAnswer((_) async => calls.add('favorite'));
      whenListen(
        issueTokenBloc,
        Stream<IssueTokenState>.value(
          IssueTokenDone(
            accountBlock: accountBlock,
            newTokenStandard: newTokenStandard,
          ),
        ),
        initialState: const IssueTokenInitial(),
      );
      await _pumpIssueTokenStep(
        tester,
        issueTokenBloc: issueTokenBloc,
        favoriteTokensRepository: favoriteTokensRepository,
        tokenData: tokenData,
        onIssuePressed: () {},
        onIssueDone: () => calls.add('done'),
      );
      await tester.pumpAndSettle();

      verify(
        () => favoriteTokensRepository.add(newTokenStandard),
      ).called(1);
      expect(calls, <String>['favorite', 'done']);
    });
  });
}

Future<void> _pumpIssueTokenStep(
  WidgetTester tester, {
  required IssueTokenBloc issueTokenBloc,
  required FavoriteTokensRepository favoriteTokensRepository,
  required ValueNotifier<NewTokenData> tokenData,
  required VoidCallback onIssuePressed,
  VoidCallback? onIssueDone,
}) async {
  await tester.pumpWidget(
    RepositoryProvider<FavoriteTokensRepository>.value(
      value: favoriteTokensRepository,
      child: BlocProvider<IssueTokenBloc>.value(
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
                onIssueDone: onIssueDone ?? () {},
                onIssuePressed: onIssuePressed,
                tokenData: tokenData,
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}
