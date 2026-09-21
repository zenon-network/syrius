import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/exceptions/exceptions.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

import '../../helpers/hydrated_bloc.dart';

class MockZenon extends Mock implements Zenon {}

class MockEmbedded extends Mock implements EmbeddedApi {}

class MockTokenApi extends Mock implements TokenApi {}

class MockToken extends Mock implements Token {}

class MockAccountBlockUtils extends Mock implements AccountBlockUtils {}

class MockZenonAddressUtils extends Mock implements ZenonAddressUtils {}

class MockAccountBlockTemplate extends Mock implements AccountBlockTemplate {}

void main() {
  initHydratedStorage();

  setUpAll(() {
    registerFallbackValue(AccountBlockTemplate(blockType: 1));
  });

  group('MintTokenBloc', () {
    final BigInt amount = BigInt.one;
    final Address beneficiaryAddress = emptyAddress;

    late MockZenon zenon;
    late MockEmbedded embedded;
    late MockTokenApi tokenApi;
    late MockToken token;
    late MockAccountBlockUtils accountBlockUtils;
    late MockZenonAddressUtils zenonAddressUtils;
    late MockAccountBlockTemplate transactionParams;
    late MockAccountBlockTemplate response;
    late MintTokenBloc bloc;

    setUp(() {
      zenon = MockZenon();
      embedded = MockEmbedded();
      tokenApi = MockTokenApi();
      token = MockToken();
      accountBlockUtils = MockAccountBlockUtils();
      zenonAddressUtils = MockZenonAddressUtils();
      transactionParams = MockAccountBlockTemplate();
      response = MockAccountBlockTemplate();

      when(() => zenon.embedded).thenReturn(embedded);
      when(() => embedded.token).thenReturn(tokenApi);
      when(() => token.tokenStandard).thenReturn(znnZts);
      when(
        () => tokenApi.mintToken(znnZts, amount, beneficiaryAddress),
      ).thenReturn(transactionParams);
      when(
        () => accountBlockUtils.createAccountBlock(
          transactionParams,
          'mint token',
          waitForRequiredPlasma: true,
        ),
      ).thenAnswer((_) async => response);
      when(() => zenonAddressUtils.refreshBalance()).thenAnswer((_) {});

      bloc = MintTokenBloc(
        accountBlockUtils: accountBlockUtils,
        zenon: zenon,
        zenonAddressUtils: zenonAddressUtils,
      );
    });

    test('initial state is correct', () {
      expect(bloc.state, const MintTokenInitial());
    });

    blocTest<MintTokenBloc, MintTokenState>(
      'emits [loading, done] on success',
      build: () => bloc,
      act: (MintTokenBloc bloc) => bloc.add(
        MintTokenRequested(
          amount: amount,
          beneficiaryAddress: beneficiaryAddress,
          token: token,
        ),
      ),
      verify: (_) {
        verify(
          () => tokenApi.mintToken(znnZts, amount, beneficiaryAddress),
        ).called(1);
        verify(
          () => accountBlockUtils.createAccountBlock(
            transactionParams,
            'mint token',
            waitForRequiredPlasma: true,
          ),
        ).called(1);
        verify(() => response.amount = amount).called(1);
        verify(() => zenonAddressUtils.refreshBalance()).called(1);
      },
      expect: () => <MintTokenState>[
        const MintTokenLoading(),
        MintTokenDone(accountBlock: response),
      ],
    );

    blocTest<MintTokenBloc, MintTokenState>(
      'emits [loading, failure] on SyriusException',
      setUp: () {
        when(
          () => accountBlockUtils.createAccountBlock(
            transactionParams,
            'mint token',
            waitForRequiredPlasma: true,
          ),
        ).thenThrow(FailureException());
      },
      build: () => bloc,
      act: (MintTokenBloc bloc) => bloc.add(
        MintTokenRequested(
          amount: amount,
          beneficiaryAddress: beneficiaryAddress,
          token: token,
        ),
      ),
      expect: () => <Matcher>[
        isA<MintTokenLoading>(),
        isA<MintTokenFailure>().having(
          (MintTokenFailure state) => state.exception,
          'exception',
          isA<FailureException>(),
        ),
      ],
    );

    blocTest<MintTokenBloc, MintTokenState>(
      'emits [loading, failure] on generic exception',
      setUp: () {
        when(
          () => accountBlockUtils.createAccountBlock(
            transactionParams,
            'mint token',
            waitForRequiredPlasma: true,
          ),
        ).thenThrow(Exception('boom'));
      },
      build: () => bloc,
      act: (MintTokenBloc bloc) => bloc.add(
        MintTokenRequested(
          amount: amount,
          beneficiaryAddress: beneficiaryAddress,
          token: token,
        ),
      ),
      expect: () => <Matcher>[
        isA<MintTokenLoading>(),
        isA<MintTokenFailure>().having(
          (MintTokenFailure state) => state.exception,
          'exception',
          isA<FailureException>(),
        ),
      ],
    );
  });
}
