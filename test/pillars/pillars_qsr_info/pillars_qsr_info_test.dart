import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/pillars/pillars.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/modular_widgets/modular_widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

import '../../helpers/hydrated_bloc.dart';

class MockZenon extends Mock implements Zenon {}

class MockEmbedded extends Mock implements EmbeddedApi {}

class MockPillarApi extends Mock implements PillarApi {}

class FakeAddress extends Fake implements Address {}

void main() {
  initHydratedStorage();

  setUpAll(() {
    registerFallbackValue(FakeAddress());
  });

  group('PillarsQsrInfoCubit', () {
    late MockZenon mockZenon;
    late MockEmbedded mockEmbedded;
    late MockPillarApi mockPillarApi;
    late PillarsQsrInfoCubit pillarsQsrInfoCubit;
    late BigInt deposit;
    late BigInt cost;
    late String testAddress;
    late PillarType testPillarType;
    late CubitFailureException exception;

    setUp(() async {
      mockZenon = MockZenon();
      mockEmbedded = MockEmbedded();
      mockPillarApi = MockPillarApi();
      deposit = BigInt.from(1000);
      cost = BigInt.from(500);
      exception = CubitFailureException();
      testAddress = emptyAddress.toString();
      testPillarType = PillarType.regularPillar;

      when(() => mockZenon.embedded).thenReturn(mockEmbedded);
      when(() => mockEmbedded.pillar).thenReturn(mockPillarApi);
      when(() => mockPillarApi.getDepositedQsr(any()))
          .thenAnswer((_) async => deposit);
      when(() => mockPillarApi.getQsrRegistrationCost())
          .thenAnswer((_) async => cost);

      pillarsQsrInfoCubit = PillarsQsrInfoCubit(mockZenon);
    });

    tearDown(() {
      pillarsQsrInfoCubit.close();
    });

    test('initial state is correct', () {
      expect(
        pillarsQsrInfoCubit.state.status,
        PillarsQsrInfoStatus.initial,
      );
    });

    group('fromJson/toJson', () {
      test('can (de)serialize initial state', () {
        const PillarsQsrInfoState initialState = PillarsQsrInfoState();

        final Map<String, dynamic>? serialized = pillarsQsrInfoCubit.toJson(
          initialState,
        );
        final PillarsQsrInfoState? deserialized =
            pillarsQsrInfoCubit.fromJson(serialized!);

        expect(deserialized, equals(initialState));
      });

      test('can (de)serialize loading state', () {
        const PillarsQsrInfoState loadingState = PillarsQsrInfoState(
          status: PillarsQsrInfoStatus.loading,
        );

        final Map<String, dynamic>? serialized = pillarsQsrInfoCubit.toJson(
          loadingState,
        );
        final PillarsQsrInfoState? deserialized =
            pillarsQsrInfoCubit.fromJson(serialized!);

        expect(deserialized, equals(loadingState));
      });

      test('can (de)serialize success state', () {
        final PillarsQsrInfoState successState = PillarsQsrInfoState(
          status: PillarsQsrInfoStatus.success,
          data: PillarsQsrInfo(deposit: deposit, cost: cost),
        );

        final Map<String, dynamic>? serialized = pillarsQsrInfoCubit.toJson(
          successState,
        );
        final PillarsQsrInfoState? deserialized =
            pillarsQsrInfoCubit.fromJson(serialized!);

        expect(deserialized, isA<PillarsQsrInfoState>());
        expect(deserialized!.status, equals(PillarsQsrInfoStatus.success));
        expect(deserialized.data, equals(successState.data));
      });

      test('can (de)serialize failure state', () {
        final PillarsQsrInfoState failureState = PillarsQsrInfoState(
          status: PillarsQsrInfoStatus.failure,
          error: exception,
        );

        final Map<String, dynamic>? serialized = pillarsQsrInfoCubit.toJson(
          failureState,
        );
        final PillarsQsrInfoState? deserialized =
            pillarsQsrInfoCubit.fromJson(serialized!);

        expect(deserialized, equals(failureState));
      });
    });

    blocTest<PillarsQsrInfoCubit, PillarsQsrInfoState>(
      'emits [loading, success] with data on successful fetch',
      build: () => pillarsQsrInfoCubit,
      act: (PillarsQsrInfoCubit cubit) =>
          cubit.getQsrManagementInfo(testPillarType, testAddress),
      expect: () => <PillarsQsrInfoState>[
        const PillarsQsrInfoState(status: PillarsQsrInfoStatus.loading),
        PillarsQsrInfoState(
          status: PillarsQsrInfoStatus.success,
          data: PillarsQsrInfo(deposit: deposit, cost: cost),
        ),
      ],
    );

    blocTest<PillarsQsrInfoCubit, PillarsQsrInfoState>(
      'emits [loading, failure] on fetch failure',
      setUp: () {
        when(() => mockPillarApi.getDepositedQsr(any())).thenThrow(exception);
      },
      build: () => pillarsQsrInfoCubit,
      act: (PillarsQsrInfoCubit cubit) =>
          cubit.getQsrManagementInfo(testPillarType, testAddress),
      expect: () => <PillarsQsrInfoState>[
        const PillarsQsrInfoState(status: PillarsQsrInfoStatus.loading),
        PillarsQsrInfoState(
          status: PillarsQsrInfoStatus.failure,
          error: exception,
        ),
      ],
    );
  });
}
