import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/exceptions/exceptions.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

import '../../helpers/hydrated_bloc.dart';

class MockZenon extends Mock implements Zenon {}

class MockEmbedded extends Mock implements EmbeddedApi {}

class MockTokenApi extends Mock implements TokenApi {}

class MockAccountBlockUtils extends Mock implements AccountBlockUtils {}

class MockZenonAddressUtils extends Mock implements ZenonAddressUtils {}

class MockAccountBlockTemplate extends Mock implements AccountBlockTemplate {}

class MockBox extends Mock implements Box<dynamic> {}

void main() {
  initHydratedStorage();

  setUpAll(() {
    registerFallbackValue(AccountBlockTemplate(blockType: 1));
    registerFallbackValue(emptyAddress);
    registerFallbackValue(BigInt.zero);
  });

  group('IssueTokenBloc', () {
    late MockZenon zenon;
    late MockEmbedded embedded;
    late MockTokenApi tokenApi;
    late MockAccountBlockUtils accountBlockUtils;
    late MockZenonAddressUtils zenonAddressUtils;
    late MockAccountBlockTemplate template;
    late MockAccountBlockTemplate response;
    late MockBox favoriteTokensBox;
    late NewTokenData tokenData;
    late IssueTokenBloc bloc;

    setUp(() {
      zenon = MockZenon();
      embedded = MockEmbedded();
      tokenApi = MockTokenApi();
      accountBlockUtils = MockAccountBlockUtils();
      zenonAddressUtils = MockZenonAddressUtils();
      template = MockAccountBlockTemplate();
      response = MockAccountBlockTemplate();
      favoriteTokensBox = MockBox();
      tokenData = NewTokenData()
        ..address = emptyAddress.toString()
        ..tokenName = 'Token'
        ..tokenSymbol = 'TKN'
        ..tokenDomain = 'testing.com'
        ..totalSupply = BigInt.one
        ..maxSupply = BigInt.one
        ..decimals = 0
        ..isMintable = false
        ..isOwnerBurnOnly = false
        ..isUtility = true;

      when(() => zenon.embedded).thenReturn(embedded);
      when(() => embedded.token).thenReturn(tokenApi);
      when(
        () => tokenApi.issueToken(
          any(),
          any(),
          any(),
          any(),
          any(),
          any(),
          any(),
          any(),
          any(),
        ),
      ).thenReturn(template);
      when(() => response.tokenStandard).thenReturn(znnZts);
      when(
        () => accountBlockUtils.createAccountBlock(
          any(),
          any(),
          address: any(named: 'address'),
          waitForRequiredPlasma: any(named: 'waitForRequiredPlasma'),
        ),
      ).thenAnswer((_) async => response);
      when(() => favoriteTokensBox.add(any())).thenAnswer((_) async => 0);
      when(() => zenonAddressUtils.refreshBalance()).thenAnswer((_) {});

      bloc = IssueTokenBloc(
        accountBlockUtils: accountBlockUtils,
        favoriteTokensBox: favoriteTokensBox,
        zenon: zenon,
        zenonAddressUtils: zenonAddressUtils,
      );
    });

    test('initial state is correct', () {
      expect(bloc.state, const IssueTokenInitial());
    });

    blocTest<IssueTokenBloc, IssueTokenState>(
      'emits [loading, done] on success',
      build: () => bloc,
      act: (IssueTokenBloc bloc) => bloc.add(
        IssueTokenRequested(tokenData: tokenData),
      ),
      verify: (_) {
        verify(
          () => tokenApi.issueToken(
            tokenData.tokenName,
            tokenData.tokenSymbol,
            tokenData.tokenDomain,
            tokenData.totalSupply,
            tokenData.maxSupply,
            tokenData.decimals,
            tokenData.isMintable!,
            tokenData.isOwnerBurnOnly!,
            tokenData.isUtility!,
          ),
        ).called(1);
        verify(() => favoriteTokensBox.add(znnZts.toString())).called(1);
        verify(() => zenonAddressUtils.refreshBalance()).called(1);
      },
      expect: () => <IssueTokenState>[
        const IssueTokenLoading(),
        IssueTokenDone(accountBlock: response),
      ],
    );

    blocTest<IssueTokenBloc, IssueTokenState>(
      'emits [loading, failure] on SyriusException',
      setUp: () {
        when(
          () => accountBlockUtils.createAccountBlock(
            any(),
            any(),
            address: any(named: 'address'),
            waitForRequiredPlasma: any(named: 'waitForRequiredPlasma'),
          ),
        ).thenThrow(FailureException());
      },
      build: () => bloc,
      act: (IssueTokenBloc bloc) => bloc.add(
        IssueTokenRequested(tokenData: tokenData),
      ),
      expect: () => <Matcher>[
        isA<IssueTokenLoading>(),
        isA<IssueTokenFailure>().having(
          (IssueTokenFailure state) => state.exception,
          'exception',
          isA<FailureException>(),
        ),
      ],
    );

    blocTest<IssueTokenBloc, IssueTokenState>(
      'emits [loading, failure] on generic exception',
      setUp: () {
        when(
          () => accountBlockUtils.createAccountBlock(
            any(),
            any(),
            address: any(named: 'address'),
            waitForRequiredPlasma: any(named: 'waitForRequiredPlasma'),
          ),
        ).thenThrow(Exception('boom'));
      },
      build: () => bloc,
      act: (IssueTokenBloc bloc) => bloc.add(
        IssueTokenRequested(tokenData: tokenData),
      ),
      expect: () => <Matcher>[
        isA<IssueTokenLoading>(),
        isA<IssueTokenFailure>().having(
          (IssueTokenFailure state) => state.exception,
          'exception',
          isA<FailureException>(),
        ),
      ],
    );
  });
}
