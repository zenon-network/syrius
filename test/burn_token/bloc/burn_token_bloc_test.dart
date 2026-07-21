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

  group('BurnTokenBloc', () {
    final BigInt amount = BigInt.one;

    late MockZenon zenon;
    late MockEmbedded embedded;
    late MockTokenApi tokenApi;
    late MockToken token;
    late MockAccountBlockUtils accountBlockUtils;
    late MockZenonAddressUtils zenonAddressUtils;
    late MockAccountBlockTemplate transactionParams;
    late MockAccountBlockTemplate response;
    late BurnTokenBloc bloc;

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
        () => tokenApi.burnToken(znnZts, amount),
      ).thenReturn(transactionParams);
      when(
        () => accountBlockUtils.createAccountBlock(
          transactionParams,
          'burn token',
          waitForRequiredPlasma: true,
        ),
      ).thenAnswer((_) async => response);
      when(() => zenonAddressUtils.refreshBalance()).thenAnswer((_) {});

      bloc = BurnTokenBloc(
        accountBlockUtils: accountBlockUtils,
        zenon: zenon,
        zenonAddressUtils: zenonAddressUtils,
      );
    });

    test('initial state is correct', () {
      expect(bloc.state, const BurnTokenInitial());
    });

    blocTest<BurnTokenBloc, BurnTokenState>(
      'emits [loading, done] on success',
      build: () => bloc,
      act: (BurnTokenBloc bloc) => bloc.add(
        BurnTokenRequested(amount: amount, token: token),
      ),
      verify: (_) {
        verify(() => tokenApi.burnToken(znnZts, amount)).called(1);
        verify(
          () => accountBlockUtils.createAccountBlock(
            transactionParams,
            'burn token',
            waitForRequiredPlasma: true,
          ),
        ).called(1);
        verify(() => zenonAddressUtils.refreshBalance()).called(1);
      },
      expect: () => <BurnTokenState>[
        const BurnTokenLoading(),
        BurnTokenDone(accountBlock: response),
      ],
    );

    blocTest<BurnTokenBloc, BurnTokenState>(
      'emits [loading, failure] on SyriusException',
      setUp: () {
        when(
          () => accountBlockUtils.createAccountBlock(
            transactionParams,
            'burn token',
            waitForRequiredPlasma: true,
          ),
        ).thenThrow(FailureException());
      },
      build: () => bloc,
      act: (BurnTokenBloc bloc) => bloc.add(
        BurnTokenRequested(amount: amount, token: token),
      ),
      expect: () => <Matcher>[
        isA<BurnTokenLoading>(),
        isA<BurnTokenFailure>().having(
          (BurnTokenFailure state) => state.exception,
          'exception',
          isA<FailureException>(),
        ),
      ],
    );

    blocTest<BurnTokenBloc, BurnTokenState>(
      'emits [loading, failure] on generic exception',
      setUp: () {
        when(
          () => accountBlockUtils.createAccountBlock(
            transactionParams,
            'burn token',
            waitForRequiredPlasma: true,
          ),
        ).thenThrow(Exception('boom'));
      },
      build: () => bloc,
      act: (BurnTokenBloc bloc) => bloc.add(
        BurnTokenRequested(amount: amount, token: token),
      ),
      expect: () => <Matcher>[
        isA<BurnTokenLoading>(),
        isA<BurnTokenFailure>().having(
          (BurnTokenFailure state) => state.exception,
          'exception',
          isA<FailureException>(),
        ),
      ],
    );
  });
}
