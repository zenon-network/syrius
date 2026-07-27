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

class MockSentinelInfo extends Mock implements SentinelInfo {}

void main() {
  initHydratedStorage();

  setUpAll(() {
    registerFallbackValue(FakeAddress());
  });

  group('SentinelsByOwnerBloc', () {
    late MockZenon mockZenon;
    late MockEmbedded mockEmbedded;
    late MockSentinel mockSentinel;
    late SentinelsByOwnerBloc bloc;
    late MockSentinelInfo sentinelInfo;
    late FailureException exception;

    setUp(() {
      mockZenon = MockZenon();
      mockEmbedded = MockEmbedded();
      mockSentinel = MockSentinel();
      sentinelInfo = MockSentinelInfo();
      exception = FailureException();

      when(() => mockZenon.embedded).thenReturn(mockEmbedded);
      when(() => mockEmbedded.sentinel).thenReturn(mockSentinel);
      when(() => sentinelInfo.toJson()).thenReturn(<String, dynamic>{
        'owner': emptyAddress.toString(),
        'registrationTimestamp': 1625132800,
        'isRevocable': true,
        'revokeCooldown': 1000,
        'active': true,
      });
      when(
        () => mockSentinel.getByOwner(any()),
      ).thenAnswer((_) async => sentinelInfo);

      bloc = SentinelsByOwnerBloc(zenon: mockZenon);
    });

    test('initial state is FetchInitial', () {
      expect(bloc.state, const FetchInitial<List<SentinelInfo>>());
    });

    blocTest<SentinelsByOwnerBloc, FetchState<List<SentinelInfo>>>(
      'calls getByOwner once and emits populated state with sentinel',
      build: () => bloc,
      act: (SentinelsByOwnerBloc bloc) =>
          bloc.add(FetchRequestData(address: emptyAddress)),
      verify: (_) {
        verify(() => mockSentinel.getByOwner(emptyAddress)).called(1);
      },
      expect: () => <FetchState<List<SentinelInfo>>>[
        FetchPopulated<List<SentinelInfo>>(
          data: <SentinelInfo>[sentinelInfo],
        ),
      ],
    );

    blocTest<SentinelsByOwnerBloc, FetchState<List<SentinelInfo>>>(
      'emits populated state with empty list when getByOwner returns null',
      setUp: () {
        when(
          () => mockSentinel.getByOwner(any()),
        ).thenAnswer((_) async => null);
      },
      build: () => bloc,
      act: (SentinelsByOwnerBloc bloc) =>
          bloc.add(FetchRequestData(address: emptyAddress)),
      expect: () => <FetchState<List<SentinelInfo>>>[
        const FetchPopulated<List<SentinelInfo>>(
          data: <SentinelInfo>[],
        ),
      ],
    );

    blocTest<SentinelsByOwnerBloc, FetchState<List<SentinelInfo>>>(
      'emits failure when getByOwner throws',
      setUp: () {
        when(() => mockSentinel.getByOwner(any())).thenThrow(exception);
      },
      build: () => bloc,
      act: (SentinelsByOwnerBloc bloc) =>
          bloc.add(FetchRequestData(address: emptyAddress)),
      expect: () => <FetchState<List<SentinelInfo>>>[
        FetchFailure<List<SentinelInfo>>(exception: exception),
      ],
    );
  });
}
