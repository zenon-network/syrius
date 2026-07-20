import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

import '../../helpers/hydrated_bloc.dart';

class MockZenon extends Mock implements Zenon {}

class MockEmbedded extends Mock implements EmbeddedApi {}

class MockTokenApi extends Mock implements TokenApi {}

class MockTokenList extends Mock implements TokenList {}

class MockToken extends Mock implements Token {}

void main() {
  initHydratedStorage();

  group('TokenMapBloc', () {
    const int pageSize = 2;
    late MockZenon zenon;
    late MockEmbedded embedded;
    late MockTokenApi tokenApi;
    late MockTokenList tokenList;
    late MockToken token;
    late TokenMapBloc bloc;

    setUp(() {
      zenon = MockZenon();
      embedded = MockEmbedded();
      tokenApi = MockTokenApi();
      tokenList = MockTokenList();
      token = MockToken();

      when(() => token.toJson()).thenReturn(<String, dynamic>{
        'name': 'Token',
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
      when(() => zenon.embedded).thenReturn(embedded);
      when(() => embedded.token).thenReturn(tokenApi);
      when(() => tokenList.list).thenReturn(<Token>[token]);
      when(
        () => tokenApi.getAll(
          pageIndex: any(named: 'pageIndex'),
          pageSize: any(named: 'pageSize'),
        ),
      ).thenAnswer((_) async => tokenList);

      bloc = TokenMapBloc(zenon: zenon, pageSize: pageSize);
    });

    test('initial state is initial', () {
      expect(bloc.state, const InfiniteListState<Token>.initial());
    });

    blocTest<TokenMapBloc, InfiniteListState<Token>>(
      'requested emits success with the first token page',
      build: () => bloc,
      act: (TokenMapBloc bloc) => bloc.add(const InfiniteListRequested()),
      verify: (_) {
        verify(
          () => tokenApi.getAll(
            pageIndex: 0,
            pageSize: pageSize,
          ),
        ).called(1);
      },
      expect: () => <InfiniteListState<Token>>[
        InfiniteListState<Token>(
          status: InfiniteListStatus.success,
          data: <Token>[token],
          hasReachedMax: true,
        ),
      ],
    );

    blocTest<TokenMapBloc, InfiniteListState<Token>>(
      'requested emits failure when the API throws',
      setUp: () {
        when(
          () => tokenApi.getAll(
            pageIndex: any(named: 'pageIndex'),
            pageSize: any(named: 'pageSize'),
          ),
        ).thenThrow(Exception('boom'));
      },
      build: () => bloc,
      act: (TokenMapBloc bloc) => bloc.add(const InfiniteListRequested()),
      expect: () => <Matcher>[
        isA<InfiniteListState<Token>>().having(
          (InfiniteListState<Token> state) => state.status,
          'status',
          InfiniteListStatus.failure,
        ),
      ],
    );
  });
}
