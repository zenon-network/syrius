import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/account_chain_stats/account_chain_stats.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

import '../../helpers/hydrated_bloc.dart';

class MockZenon extends Mock implements Zenon {}

class MockLedgerApi extends Mock implements LedgerApi {}

class MockAccountInfo extends Mock implements AccountInfo {}

class MockAccountBlockList extends Mock implements AccountBlockList {}

class MockAccountBlock extends Mock implements AccountBlock {}

class FakeAddress extends Fake implements Address {}

void main() {
  initHydratedStorage();

  setUpAll(() {
    registerFallbackValue(FakeAddress());
  });

  group('AccountChainStatsBloc', () {
    late MockZenon mockZenon;
    late MockLedgerApi mockLedgerApi;
    late MockAccountInfo mockAccountInfo;
    late Hash firstBlockHash;

    AccountBlock mockBlock({required int blockType, required Hash hash}) {
      final MockAccountBlock block = MockAccountBlock();
      when(() => block.blockType).thenReturn(blockType);
      when(() => block.hash).thenReturn(hash);
      return block;
    }

    setUp(() {
      mockZenon = MockZenon();
      mockLedgerApi = MockLedgerApi();
      mockAccountInfo = MockAccountInfo();
      firstBlockHash = Hash.digest(<int>[1, 2, 3]);

      when(() => mockZenon.ledger).thenReturn(mockLedgerApi);
      when(
        () => mockLedgerApi.getAccountInfoByAddress(any()),
      ).thenAnswer((_) async => mockAccountInfo);
    });

    test('initial state is FetchInitial', () {
      final AccountChainStatsBloc bloc = AccountChainStatsBloc(
        zenon: mockZenon,
      );
      addTearDown(bloc.close);

      expect(bloc.state, const FetchInitial<AccountChainStats>());
    });

    blocTest<AccountChainStatsBloc, FetchState<AccountChainStats>>(
      'fetches blocks and counts each block type',
      setUp: () {
        final MockAccountBlockList page = MockAccountBlockList();
        final AccountBlock b1 = mockBlock(
          blockType: BlockTypeEnum.userSend.index,
          hash: firstBlockHash,
        );
        final AccountBlock b2 = mockBlock(
          blockType: BlockTypeEnum.userReceive.index,
          hash: Hash.digest(<int>[4]),
        );
        final AccountBlock b3 = mockBlock(
          blockType: BlockTypeEnum.userReceive.index,
          hash: Hash.digest(<int>[5]),
        );
        when(() => mockAccountInfo.blockCount).thenReturn(3);
        when(() => page.list).thenReturn(<AccountBlock>[b1, b2, b3]);
        when(
          () => mockLedgerApi.getAccountBlocksByHeight(any()),
        ).thenAnswer((_) async => page);
      },
      build: () => AccountChainStatsBloc(zenon: mockZenon),
      act: (AccountChainStatsBloc bloc) =>
          bloc.add(FetchRequestData(address: emptyAddress)),
      expect: () => <FetchState<AccountChainStats>>[
        FetchPopulated<AccountChainStats>(
          data: AccountChainStats(
            firstHash: firstBlockHash,
            blockCount: 3,
            blockTypeNumOfBlocksMap: <BlockTypeEnum, int>{
              for (final BlockTypeEnum type in BlockTypeEnum.values)
                type: switch (type) {
                  BlockTypeEnum.userSend => 1,
                  BlockTypeEnum.userReceive => 2,
                  _ => 0,
                },
            },
          ),
        ),
      ],
    );

    blocTest<AccountChainStatsBloc, FetchState<AccountChainStats>>(
      'paginates across multiple RPC pages when blockCount exceeds max page',
      setUp: () {
        final MockAccountBlockList page1 = MockAccountBlockList();
        final MockAccountBlockList page2 = MockAccountBlockList();
        final AccountBlock b1 = mockBlock(
          blockType: BlockTypeEnum.userSend.index,
          hash: firstBlockHash,
        );
        final AccountBlock b2 = mockBlock(
          blockType: BlockTypeEnum.userReceive.index,
          hash: Hash.digest(<int>[9]),
        );
        when(() => mockAccountInfo.blockCount).thenReturn(rpcMaxPageSize + 2);
        when(() => page1.list).thenReturn(<AccountBlock>[b1]);
        when(() => page2.list).thenReturn(<AccountBlock>[b2]);
        when(
          () => mockLedgerApi.getAccountBlocksByHeight(any()),
        ).thenAnswer((_) async => page1);
        when(
          () =>
              mockLedgerApi.getAccountBlocksByHeight(any(), rpcMaxPageSize + 1),
        ).thenAnswer((_) async => page2);
      },
      build: () => AccountChainStatsBloc(zenon: mockZenon),
      act: (AccountChainStatsBloc bloc) =>
          bloc.add(FetchRequestData(address: emptyAddress)),
      verify: (_) {
        verify(() => mockLedgerApi.getAccountBlocksByHeight(any())).called(1);
        verify(
          () =>
              mockLedgerApi.getAccountBlocksByHeight(any(), rpcMaxPageSize + 1),
        ).called(1);
      },
      expect: () => <Matcher>[
        isA<FetchPopulated<AccountChainStats>>()
            .having(
              (FetchPopulated<AccountChainStats> s) => s.data.blockCount,
              'blockCount',
              rpcMaxPageSize + 2,
            )
            .having(
              (FetchPopulated<AccountChainStats> s) => s.data.firstHash,
              'firstHash',
              firstBlockHash,
            ),
      ],
    );

    blocTest<AccountChainStatsBloc, FetchState<AccountChainStats>>(
      'emits FetchFailure with EmptyAccountChainException when blockCount is 0',
      setUp: () {
        when(() => mockAccountInfo.blockCount).thenReturn(0);
      },
      build: () => AccountChainStatsBloc(zenon: mockZenon),
      act: (AccountChainStatsBloc bloc) =>
          bloc.add(FetchRequestData(address: emptyAddress)),
      expect: () => <FetchState<AccountChainStats>>[
        FetchFailure<AccountChainStats>(
          exception: EmptyAccountChainException(),
        ),
      ],
    );

    blocTest<AccountChainStatsBloc, FetchState<AccountChainStats>>(
      'emits FetchFailure with FailureException on unexpected error',
      setUp: () {
        when(
          () => mockLedgerApi.getAccountInfoByAddress(any()),
        ).thenThrow(Exception('rpc down'));
      },
      build: () => AccountChainStatsBloc(zenon: mockZenon),
      act: (AccountChainStatsBloc bloc) =>
          bloc.add(FetchRequestData(address: emptyAddress)),
      expect: () => <FetchState<AccountChainStats>>[
        FetchFailure<AccountChainStats>(exception: FailureException()),
      ],
    );

    test(
      'AccountChainStats and EmptyAccountChainException serialize cleanly',
      () {
        final AccountChainStats original = AccountChainStats(
          firstHash: firstBlockHash,
          blockCount: 5,
          blockTypeNumOfBlocksMap: const <BlockTypeEnum, int>{
            BlockTypeEnum.userSend: 2,
            BlockTypeEnum.userReceive: 3,
          },
        );

        expect(AccountChainStats.fromJson(original.toJson()), original);

        final EmptyAccountChainException exception =
            EmptyAccountChainException();
        expect(SyriusException.fromJson(exception.toJson()), exception);
      },
    );

    test(
      'refreshes stats for last requested address when websocket restarts',
      () async {
        final StreamController<bool> wsController =
            StreamController<bool>.broadcast();
        addTearDown(wsController.close);

        final MockAccountBlockList page = MockAccountBlockList();
        final AccountBlock block = mockBlock(
          blockType: BlockTypeEnum.userSend.index,
          hash: firstBlockHash,
        );
        when(() => mockAccountInfo.blockCount).thenReturn(1);
        when(() => page.list).thenReturn(<AccountBlock>[block]);
        when(
          () => mockLedgerApi.getAccountBlocksByHeight(any()),
        ).thenAnswer((_) async => page);

        final AccountChainStatsBloc bloc = AccountChainStatsBloc(
          zenon: mockZenon,
          wsRestartedStream: wsController.stream,
        );
        addTearDown(bloc.close);

        bloc.add(FetchRequestData(address: emptyAddress));
        await expectLater(
          bloc.stream,
          emits(isA<FetchPopulated<AccountChainStats>>()),
        );

        wsController.add(true);
        await Future<void>.delayed(Duration.zero);
        await Future<void>.delayed(Duration.zero);

        verify(() => mockLedgerApi.getAccountInfoByAddress(any())).called(2);
      },
    );
  });
}
