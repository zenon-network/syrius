import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/pillars/pillars.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

import '../../helpers/hydrated_bloc.dart';

class MockZenon extends Mock implements Zenon {}

class MockEmbedded extends Mock implements EmbeddedApi {}

class MockPillarApi extends Mock implements PillarApi {}

class FakeAccountBlockTemplate extends Fake implements AccountBlockTemplate {}

class MockAccountBlockUtils extends Mock implements AccountBlockUtilsHelper {}

class MockZenonAddressUtils extends Mock implements ZenonAddressUtilsHelper {}

void main() {
  initHydratedStorage();

  setUpAll(() {
    registerFallbackValue(FakeAccountBlockTemplate());
  });

  group('DisassemblePillarCubit', () {
    late MockZenon mockZenon;
    late MockEmbedded mockEmbedded;
    late MockPillarApi mockPillarApi;
    late MockAccountBlockUtils mockAccountBlockUtilsHelper;
    late MockZenonAddressUtils mockZenonAddressUtils;
    late DisassemblePillarCubit disassemblePillarCubit;
    late AccountBlockTemplate testAccBlockTemplate;
    late CubitFailureException exception;

    setUp(() {
      mockZenon = MockZenon();
      mockEmbedded = MockEmbedded();
      mockPillarApi = MockPillarApi();
      mockAccountBlockUtilsHelper = MockAccountBlockUtils();
      mockZenonAddressUtils = MockZenonAddressUtils();
      testAccBlockTemplate = AccountBlockTemplate(blockType: 1);
      exception = CubitFailureException();

      when(() => mockZenon.embedded).thenReturn(mockEmbedded);
      when(() => mockEmbedded.pillar).thenReturn(mockPillarApi);
      when(() => mockZenonAddressUtils.refreshBalance())
          .thenAnswer((_) async {});

      disassemblePillarCubit = DisassemblePillarCubit(
        zenon: mockZenon,
        accountBlockUtilsHelper: mockAccountBlockUtilsHelper,
        zenonAddressUtilsHelper: mockZenonAddressUtils,
      );
    });

    tearDown(() {
      disassemblePillarCubit.close();
    });

    test('initial state is correct', () {
      expect(
        disassemblePillarCubit.state.status,
        DisassemblePillarStatus.initial,
      );
    });

    group('fromJson/toJson', () {
      test('can (de)serialize initial state', () {
        const DisassemblePillarState initialState = DisassemblePillarState();

        final Map<String, dynamic> serialized = initialState.toJson();
        final DisassemblePillarState deserialized = DisassemblePillarState
            .fromJson(serialized);

        expect(deserialized, equals(initialState));
      });

      test('can (de)serialize loading state', () {
        const DisassemblePillarState loadingState = DisassemblePillarState(
          status: DisassemblePillarStatus.loading,
        );

        final Map<String, dynamic> serialized = loadingState.toJson();
        final DisassemblePillarState deserialized = DisassemblePillarState
            .fromJson(serialized);

        expect(deserialized, equals(loadingState));
      });

      test('can (de)serialize success state', () {
        final DisassemblePillarState successState = DisassemblePillarState(
          status: DisassemblePillarStatus.success,
          data: testAccBlockTemplate,
        );

        final Map<String, dynamic> serialized = successState.toJson();
        final DisassemblePillarState deserialized = DisassemblePillarState
            .fromJson(serialized);

        expect(deserialized, isA<DisassemblePillarState>());
        expect(deserialized.status, equals(DisassemblePillarStatus.success));
        expect(deserialized.data, equals(testAccBlockTemplate));
      });

      test('can (de)serialize failure state', () {
        final DisassemblePillarState failureState = DisassemblePillarState(
          status: DisassemblePillarStatus.failure,
          error: exception,
        );

        final Map<String, dynamic> serialized = failureState.toJson();
        final DisassemblePillarState deserialized = DisassemblePillarState
            .fromJson(serialized);

        expect(deserialized, equals(failureState));
      });
    });

    group('disassemblePillar', () {
      blocTest<DisassemblePillarCubit, DisassemblePillarState>(
        'emits [loading, success] when disassemblePillar succeeds',
        setUp: () {
          when(() => mockPillarApi.revoke(any())).thenReturn(
            testAccBlockTemplate,
          );
          when(
            () => mockAccountBlockUtilsHelper.createAccountBlock(
              any(),
              any(),
              waitForRequiredPlasma: any(named: 'waitForRequiredPlasma'),
            ),
          ).thenAnswer((_) async => testAccBlockTemplate);
        },
        build: () => disassemblePillarCubit,
        act: (DisassemblePillarCubit cubit) => cubit.disassemblePillar('test'),
        expect: () => <DisassemblePillarState>[
          const DisassemblePillarState(status: DisassemblePillarStatus.loading),
          DisassemblePillarState(
            status: DisassemblePillarStatus.success,
            data: testAccBlockTemplate,
          ),
        ],
      );

      blocTest<DisassemblePillarCubit, DisassemblePillarState>(
        'emits [loading, failure] when disassemblePillar fails',
        setUp: () {
          when(() => mockPillarApi.revoke(any())).thenThrow(
            exception,
          );
        },
        build: () => disassemblePillarCubit,
        act: (DisassemblePillarCubit cubit) => cubit.disassemblePillar('test'),
        expect: () => <DisassemblePillarState>[
          const DisassemblePillarState(status: DisassemblePillarStatus.loading),
          DisassemblePillarState(
            status: DisassemblePillarStatus.failure,
            error: exception,
          ),
        ],
      );
    });
  });
}
