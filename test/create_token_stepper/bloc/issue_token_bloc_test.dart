import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
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
    late Hash sendBlockHash;
    late TokenStandard newTokenStandard;
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
      sendBlockHash = Hash.parse(
        '33f409250960e0c1c9f57b8a278f0937'
        '49bf8844ea0ca4f4b7b5526d05cdd3ce',
      );
      newTokenStandard = TokenStandard.parse(
        'zts1zdl4pmr425t0j97v4eu0du',
      );
      tokenData = NewTokenData(
        address: emptyAddress.toString(),
        tokenName: 'Token',
        tokenSymbol: 'TKN',
        tokenDomain: 'testing.com',
        totalSupply: BigInt.one,
        maxSupply: BigInt.one,
        decimals: 0,
        isMintable: false,
        isBurnable: false,
        isUtility: true,
      );

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
      when(() => response.hash).thenReturn(sendBlockHash);
      when(() => response.tokenStandard).thenReturn(znnZts);
      when(
        () => accountBlockUtils.createAccountBlock(
          any(),
          any(),
          address: any(named: 'address'),
          waitForRequiredPlasma: any(named: 'waitForRequiredPlasma'),
        ),
      ).thenAnswer((_) async => response);
      when(() => zenonAddressUtils.refreshBalance()).thenAnswer((_) {});

      bloc = IssueTokenBloc(
        accountBlockUtils: accountBlockUtils,
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
            tokenData.isMintable,
            tokenData.isBurnable,
            tokenData.isUtility,
          ),
        ).called(1);
        verify(() => zenonAddressUtils.refreshBalance()).called(1);
      },
      expect: () => <IssueTokenState>[
        const IssueTokenLoading(),
        IssueTokenDone(
          accountBlock: response,
          newTokenStandard: newTokenStandard,
        ),
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
