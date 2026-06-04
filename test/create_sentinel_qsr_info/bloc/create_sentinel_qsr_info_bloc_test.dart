import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

import '../../helpers/hydrated_bloc.dart';

class MockZenon extends Mock implements Zenon {}

class MockEmbedded extends Mock implements EmbeddedApi {}

class MockSentinel extends Mock implements SentinelApi {}

class FakeAddress extends Fake implements Address {}

void main() {
  initHydratedStorage();

  setUpAll(() {
    registerFallbackValue(FakeAddress());
  });

  group('CreateSentinelQsrInfoBloc', () {
    late MockZenon mockZenon;
    late MockEmbedded mockEmbedded;
    late MockSentinel mockSentinel;
    late CreateSentinelQsrInfoBloc bloc;
    late CreateSentinelQsrInfoData data;

    setUp(() {
      mockZenon = MockZenon();
      mockEmbedded = MockEmbedded();
      mockSentinel = MockSentinel();
      data = CreateSentinelQsrInfoData(
        cost: sentinelRegisterQsrAmount,
        deposit: BigInt.from(500),
      );

      when(() => mockZenon.embedded).thenReturn(mockEmbedded);
      when(() => mockEmbedded.sentinel).thenReturn(mockSentinel);
      when(
        () => mockSentinel.getDepositedQsr(any()),
      ).thenAnswer((_) async => data.deposit);

      bloc = CreateSentinelQsrInfoBloc(zenon: mockZenon);
    });

    test('initial state is FetchInitial', () {
      expect(bloc.state, const FetchInitial<CreateSentinelQsrInfoData>());
    });

    blocTest<CreateSentinelQsrInfoBloc, FetchState<CreateSentinelQsrInfoData>>(
      'calls sentinel methods once and emits populated state',
      build: () => bloc,
      act: (CreateSentinelQsrInfoBloc bloc) =>
          bloc.add(FetchRequestData(address: emptyAddress)),
      verify: (_) {
        verify(() => mockSentinel.getDepositedQsr(emptyAddress)).called(1);
      },
      expect: () => <FetchState<CreateSentinelQsrInfoData>>[
        FetchPopulated<CreateSentinelQsrInfoData>(data: data),
      ],
    );

    blocTest<CreateSentinelQsrInfoBloc, FetchState<CreateSentinelQsrInfoData>>(
      'emits failure when dependency throws',
      setUp: () {
        when(
          () => mockSentinel.getDepositedQsr(any()),
        ).thenThrow(FailureException());
      },
      build: () => bloc,
      act: (CreateSentinelQsrInfoBloc bloc) =>
          bloc.add(FetchRequestData(address: emptyAddress)),
      expect: () => <Matcher>[
        isA<FetchFailure<CreateSentinelQsrInfoData>>(),
      ],
    );
  });
}
