import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/pillars/pillars.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

import '../../helpers/hydrated_bloc.dart';

class MockZenon extends Mock implements Zenon {}

class MockEmbedded extends Mock implements EmbeddedApi {}

class MockPillarApi extends Mock implements PillarApi {}

class MockAccountBlockUtils extends Mock implements AccountBlockUtils {}

class MockZenonAddressUtils extends Mock implements ZenonAddressUtils {}

class FakeAccountBlockTemplate extends Fake implements AccountBlockTemplate {}

void main() {
  initHydratedStorage();

  registerFallbackValue(FakeAccountBlockTemplate());

  group('PillarsWithdrawQsrCubit', () {
    late MockZenon mockZenon;
    late MockEmbedded mockEmbedded;
    late MockPillarApi mockPillarApi;
    late MockAccountBlockUtils mockAccountBlockUtils;
    late MockZenonAddressUtils mockZenonAddressUtils;
    late PillarsWithdrawQsrCubit pillarsWithdrawQsrCubit;
    late AccountBlockTemplate testAccountBlockTemplate;
    late String testAddress;
    late FailureException exception;

    setUp(() {
      mockZenon = MockZenon();
      mockEmbedded = MockEmbedded();
      mockPillarApi = MockPillarApi();
      mockAccountBlockUtils = MockAccountBlockUtils();
      mockZenonAddressUtils = MockZenonAddressUtils();
      testAccountBlockTemplate = AccountBlockTemplate(blockType: 1);
      testAddress = emptyAddress.toString();
      exception = FailureException();

      when(() => mockZenon.embedded).thenReturn(mockEmbedded);
      when(() => mockEmbedded.pillar).thenReturn(mockPillarApi);
      when(() => mockPillarApi.withdrawQsr())
          .thenReturn(testAccountBlockTemplate);
      when(
        () => mockAccountBlockUtils.createAccountBlock(
          any(),
          any(),
          waitForRequiredPlasma: any(named: 'waitForRequiredPlasma'),
        ),
      ).thenAnswer((_) async => testAccountBlockTemplate);
      when(() => mockZenonAddressUtils.refreshBalance())
          .thenAnswer((_) async {});

      pillarsWithdrawQsrCubit = PillarsWithdrawQsrCubit(
        zenon: mockZenon,
        accountBlockUtilsHelper: mockAccountBlockUtils,
        zenonAddressUtilsHelper: mockZenonAddressUtils,
      );
    });

    tearDown(() {
      pillarsWithdrawQsrCubit.close();
    });

    test('initial state is correct', () {
      expect(
        pillarsWithdrawQsrCubit.state.status,
        PillarsWithdrawQsrStatus.initial,
      );
    });

    group('fromJson/toJson', () {
      test('can (de)serialize initial state', () {
        const PillarsWithdrawQsrState initialState = PillarsWithdrawQsrState();

        final Map<String, dynamic>? serialized =
            pillarsWithdrawQsrCubit.toJson(initialState);

        final PillarsWithdrawQsrState? deserialized =
            pillarsWithdrawQsrCubit.fromJson(serialized!);

        expect(deserialized, equals(initialState));
      });

      test('can (de)serialize loading state', () {
        const PillarsWithdrawQsrState loadingState = PillarsWithdrawQsrState(
          status: PillarsWithdrawQsrStatus.loading,
        );

        final Map<String, dynamic>? serialized =
            pillarsWithdrawQsrCubit.toJson(loadingState);
        final PillarsWithdrawQsrState? deserialized =
            pillarsWithdrawQsrCubit.fromJson(serialized!);

        expect(deserialized, equals(loadingState));
      });

      test('can (de)serialize success state', () {
        final PillarsWithdrawQsrState successState = PillarsWithdrawQsrState(
          status: PillarsWithdrawQsrStatus.success,
          data: testAccountBlockTemplate,
        );

        final Map<String, dynamic>? serialized =
            pillarsWithdrawQsrCubit.toJson(successState);

        final PillarsWithdrawQsrState? deserialized =
            pillarsWithdrawQsrCubit.fromJson(serialized!);

        expect(deserialized, isA<PillarsWithdrawQsrState>());
        expect(deserialized!.status, equals(PillarsWithdrawQsrStatus.success));
        expect(deserialized.data, equals(successState.data));
      });

      test('can (de)serialize failure state', () {
        final PillarsWithdrawQsrState failureState = PillarsWithdrawQsrState(
          status: PillarsWithdrawQsrStatus.failure,
          error: exception,
        );

        final Map<String, dynamic>? serialized =
            pillarsWithdrawQsrCubit.toJson(failureState);

        final PillarsWithdrawQsrState? deserialized =
            pillarsWithdrawQsrCubit.fromJson(serialized!);

        expect(deserialized, equals(failureState));
      });
    });

    blocTest<PillarsWithdrawQsrCubit, PillarsWithdrawQsrState>(
      'emits [loading, success] on successful QSR withdrawal',
      build: () => pillarsWithdrawQsrCubit,
      act: (PillarsWithdrawQsrCubit cubit) => cubit.withdrawQsr(testAddress),
      expect: () => <PillarsWithdrawQsrState>[
        const PillarsWithdrawQsrState(status: PillarsWithdrawQsrStatus.loading),
        PillarsWithdrawQsrState(
          status: PillarsWithdrawQsrStatus.success,
          data: testAccountBlockTemplate,
        ),
      ],
    );

    blocTest<PillarsWithdrawQsrCubit, PillarsWithdrawQsrState>(
      'emits [loading, failure] on QSR withdrawal failure',
      setUp: () {
        when(
          () => mockAccountBlockUtils.createAccountBlock(
            any(),
            any(),
            waitForRequiredPlasma: any(named: 'waitForRequiredPlasma'),
          ),
        ).thenThrow(exception);
      },
      build: () => pillarsWithdrawQsrCubit,
      act: (PillarsWithdrawQsrCubit cubit) => cubit.withdrawQsr(testAddress),
      expect: () => <PillarsWithdrawQsrState>[
        const PillarsWithdrawQsrState(status: PillarsWithdrawQsrStatus.loading),
        PillarsWithdrawQsrState(
          status: PillarsWithdrawQsrStatus.failure,
          error: exception,
        ),
      ],
    );
  });
}
