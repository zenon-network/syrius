import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

import '../../helpers/hydrated_bloc.dart';

class MockZenon extends Mock implements Zenon {}

class MockEmbedded extends Mock implements EmbeddedApi {}

class MockPlasmaApi extends Mock implements PlasmaApi {}

class MockLedger extends Mock implements LedgerApi {}

class MockMomentum extends Mock implements Momentum {}

class FakeAddress extends Fake implements Address {}

void main() {
  initHydratedStorage();

  setUpAll(() {
    registerFallbackValue(FakeAddress());
  });

  group('FusedPlasmaBloc', () {
    const int pageSize = 2;
    late MockZenon mockZenon;
    late MockEmbedded mockEmbedded;
    late MockPlasmaApi mockPlasmaApi;
    late MockLedger mockLedger;
    late MockMomentum mockMomentum;
    late FusedPlasmaBloc bloc;
    late FusionEntry fusionEntry;
    late FusionEntryList fusionEntryList;

    setUp(() {
      mockZenon = MockZenon();
      mockEmbedded = MockEmbedded();
      mockPlasmaApi = MockPlasmaApi();
      mockLedger = MockLedger();
      mockMomentum = MockMomentum();
      fusionEntry = FusionEntry(
        beneficiary: emptyAddress,
        expirationHeight: 10,
        id: emptyHash,
        qsrAmount: BigInt.one,
      );
      fusionEntryList = FusionEntryList.fromJson(<String, dynamic>{
        'qsrAmount': BigInt.one.toString(),
        'count': 1,
        'list': <Map<String, dynamic>>[fusionEntry.toJson()],
      });

      when(() => mockZenon.embedded).thenReturn(mockEmbedded);
      when(() => mockZenon.ledger).thenReturn(mockLedger);
      when(() => mockEmbedded.plasma).thenReturn(mockPlasmaApi);
      when(
        () => mockPlasmaApi.getEntriesByAddress(
          any(),
          pageIndex: any(named: 'pageIndex'),
          pageSize: any(named: 'pageSize'),
        ),
      ).thenAnswer((_) async => fusionEntryList);
      when(() => mockLedger.getFrontierMomentum()).thenAnswer(
        (_) async => mockMomentum,
      );
      when(() => mockMomentum.height).thenReturn(11);

      bloc = FusedPlasmaBloc(zenon: mockZenon, pageSize: pageSize);
    });

    test('initial state is initial', () {
      expect(bloc.state, const InfiniteListState<FusionEntryWrapper>.initial());
    });

    blocTest<FusedPlasmaBloc, InfiniteListState<FusionEntryWrapper>>(
      'requested emits success and wraps revocable entries',
      build: () => bloc,
      act: (FusedPlasmaBloc bloc) =>
          bloc.add(InfiniteListRequested(address: emptyAddress)),
      verify: (_) {
        verify(
          () => mockPlasmaApi.getEntriesByAddress(
            emptyAddress,
            pageSize: pageSize,
          ),
        ).called(1);
        verify(() => mockLedger.getFrontierMomentum()).called(1);
        expect(bloc.lastMomentumHeight, 11);
        expect(bloc.state.data!.single.isRevocable, isTrue);
        expect(bloc.state.data!.single.fusionEntry.id, emptyHash);
      },
      expect: () => <Matcher>[
        isA<InfiniteListState<FusionEntryWrapper>>()
            .having(
              (InfiniteListState<FusionEntryWrapper> s) => s.status,
              'status',
              InfiniteListStatus.success,
            )
            .having(
              (InfiniteListState<FusionEntryWrapper> s) => s.hasReachedMax,
              'hasReachedMax',
              isTrue,
            ),
      ],
    );

    blocTest<FusedPlasmaBloc, InfiniteListState<FusionEntryWrapper>>(
      'requested emits failure when api throws',
      setUp: () {
        when(
          () => mockPlasmaApi.getEntriesByAddress(
            any(),
            pageIndex: any(named: 'pageIndex'),
            pageSize: any(named: 'pageSize'),
          ),
        ).thenThrow(Exception('boom'));
      },
      build: () => bloc,
      act: (FusedPlasmaBloc bloc) =>
          bloc.add(InfiniteListRequested(address: emptyAddress)),
      expect: () => <Matcher>[
        isA<InfiniteListState<FusionEntryWrapper>>().having(
          (InfiniteListState<FusionEntryWrapper> s) => s.status,
          'status',
          InfiniteListStatus.failure,
        ),
      ],
    );
  });
}
