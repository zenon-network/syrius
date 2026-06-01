import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/tokens/cubit/tokens_cubit.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/exceptions/exceptions.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

import '../../helpers/hydrated_bloc.dart';

class MockZenon extends Mock implements Zenon {}

class MockEmbedded extends Mock implements EmbeddedApi {}

class MockTokenApi extends Mock implements TokenApi {}

class MockTokenList extends Mock implements TokenList {}

class MockToken extends Mock implements Token {}

void main() {
  initHydratedStorage();

  group('TokensCubit', () {
    late MockZenon mockZenon;
    late MockEmbedded mockEmbedded;
    late MockTokenApi mockTokenApi;
    late MockTokenList mockTokenList;
    late MockToken token;
    late TokensCubit cubit;

    setUp(() {
      mockZenon = MockZenon();
      mockEmbedded = MockEmbedded();
      mockTokenApi = MockTokenApi();
      mockTokenList = MockTokenList();
      token = MockToken();

      when(() => token.toJson()).thenReturn(<String, dynamic>{
        'name': 'token',
        'symbol': 'TKN',
        'domain': 'zenon.network',
        'totalSupply': '1',
        'decimals': 8,
        'owner': emptyAddress.toString(),
        'tokenStandard': znnZts.toString(),
        'maxSupply': '1',
        'isBurnable': false,
        'isMintable': false,
        'isUtility': true,
      });
      when(() => mockZenon.embedded).thenReturn(mockEmbedded);
      when(() => mockEmbedded.token).thenReturn(mockTokenApi);
      when(() => mockTokenList.list).thenReturn(<Token>[token]);
      when(() => mockTokenApi.getAll()).thenAnswer((_) async => mockTokenList);

      cubit = TokensCubit(zenon: mockZenon);
    });

    test('initial state is initial', () {
      expect(cubit.state, const TokensState.initial());
    });

    blocTest<TokensCubit, TokensState>(
      'emits success when fetch returns tokens',
      build: () => cubit,
      act: (TokensCubit cubit) => cubit.fetch(),
      verify: (_) {
        verify(() => mockTokenApi.getAll()).called(1);
      },
      expect: () => <TokensState>[
        TokensState(
          status: TokensStatus.success,
          data: <Token>[token],
        ),
      ],
    );

    blocTest<TokensCubit, TokensState>(
      'emits failure when fetch throws',
      setUp: () {
        when(() => mockTokenApi.getAll()).thenThrow(Exception('boom'));
      },
      build: () => cubit,
      act: (TokensCubit cubit) => cubit.fetch(),
      expect: () => <Matcher>[
        isA<TokensState>()
            .having((TokensState s) => s.status, 'status', TokensStatus.initial)
            .having(
              (TokensState s) => s.error,
              'error',
              isA<FailureException>(),
            ),
      ],
    );
  });
}
