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

class MockAccountBlockTemplate extends Mock implements AccountBlockTemplate {}

void main() {
  initHydratedStorage();

  setUpAll(() {
    registerFallbackValue(AccountBlockTemplate(blockType: 1));
  });

  group('TransferTokenBloc', () {
    final Address newOwnerAddress = emptyAddress;

    late MockZenon zenon;
    late MockEmbedded embedded;
    late MockTokenApi tokenApi;
    late MockToken token;
    late MockAccountBlockUtils accountBlockUtils;
    late MockAccountBlockTemplate transactionParams;
    late MockAccountBlockTemplate response;
    late TransferTokenBloc bloc;

    setUp(() {
      zenon = MockZenon();
      embedded = MockEmbedded();
      tokenApi = MockTokenApi();
      token = MockToken();
      accountBlockUtils = MockAccountBlockUtils();
      transactionParams = MockAccountBlockTemplate();
      response = MockAccountBlockTemplate();

      when(() => zenon.embedded).thenReturn(embedded);
      when(() => embedded.token).thenReturn(tokenApi);
      when(() => token.tokenStandard).thenReturn(znnZts);
      when(() => token.isMintable).thenReturn(true);
      when(() => token.isBurnable).thenReturn(false);
      when(
        () => tokenApi.updateToken(
          znnZts,
          newOwnerAddress,
          true,
          false,
        ),
      ).thenReturn(transactionParams);
      when(
        () => accountBlockUtils.createAccountBlock(
          transactionParams,
          'transfer token',
          waitForRequiredPlasma: true,
        ),
      ).thenAnswer((_) async => response);

      bloc = TransferTokenBloc(
        accountBlockUtils: accountBlockUtils,
        zenon: zenon,
      );
    });

    test('initial state is correct', () {
      expect(bloc.state, const TransferTokenInitial());
    });

    blocTest<TransferTokenBloc, TransferTokenState>(
      'emits [loading, done] on success',
      build: () => bloc,
      act: (TransferTokenBloc bloc) => bloc.add(
        TransferTokenRequested(
          newOwnerAddress: newOwnerAddress,
          token: token,
        ),
      ),
      verify: (_) {
        verify(
          () => tokenApi.updateToken(
            znnZts,
            newOwnerAddress,
            true,
            false,
          ),
        ).called(1);
        verify(
          () => accountBlockUtils.createAccountBlock(
            transactionParams,
            'transfer token',
            waitForRequiredPlasma: true,
          ),
        ).called(1);
      },
      expect: () => <TransferTokenState>[
        const TransferTokenLoading(),
        TransferTokenDone(accountBlock: response),
      ],
    );

    blocTest<TransferTokenBloc, TransferTokenState>(
      'emits [loading, failure] on SyriusException',
      setUp: () {
        when(
          () => accountBlockUtils.createAccountBlock(
            transactionParams,
            'transfer token',
            waitForRequiredPlasma: true,
          ),
        ).thenThrow(FailureException());
      },
      build: () => bloc,
      act: (TransferTokenBloc bloc) => bloc.add(
        TransferTokenRequested(
          newOwnerAddress: newOwnerAddress,
          token: token,
        ),
      ),
      expect: () => <Matcher>[
        isA<TransferTokenLoading>(),
        isA<TransferTokenFailure>().having(
          (TransferTokenFailure state) => state.exception,
          'exception',
          isA<FailureException>(),
        ),
      ],
    );

    blocTest<TransferTokenBloc, TransferTokenState>(
      'emits [loading, failure] on generic exception',
      setUp: () {
        when(
          () => accountBlockUtils.createAccountBlock(
            transactionParams,
            'transfer token',
            waitForRequiredPlasma: true,
          ),
        ).thenThrow(Exception('boom'));
      },
      build: () => bloc,
      act: (TransferTokenBloc bloc) => bloc.add(
        TransferTokenRequested(
          newOwnerAddress: newOwnerAddress,
          token: token,
        ),
      ),
      expect: () => <Matcher>[
        isA<TransferTokenLoading>(),
        isA<TransferTokenFailure>().having(
          (TransferTokenFailure state) => state.exception,
          'exception',
          isA<FailureException>(),
        ),
      ],
    );
  });
}
