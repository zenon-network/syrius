import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/update_phase_stepper/update_phase_stepper.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/exceptions/exceptions.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class _MockZenon extends Mock implements Zenon {}

class _MockEmbeddedApi extends Mock implements EmbeddedApi {}

class _MockAcceleratorApi extends Mock implements AcceleratorApi {}

class _MockAccountBlockUtils extends Mock implements AccountBlockUtils {}

class _MockAccountBlockTemplate extends Mock implements AccountBlockTemplate {}

void main() {
  final Hash projectId = Hash.digest(List<int>.filled(32, 2));
  final Address owner = Address.fromPublicKey(List<int>.filled(32, 6));

  setUpAll(() {
    registerFallbackValue(AccountBlockTemplate(blockType: 1));
    registerFallbackValue(emptyAddress);
    registerFallbackValue(projectId);
    registerFallbackValue(BigInt.zero);
  });

  group('UpdatePhaseBloc', () {
    late _MockZenon zenon;
    late _MockEmbeddedApi embedded;
    late _MockAcceleratorApi acceleratorApi;
    late _MockAccountBlockUtils accountBlockUtils;
    late _MockAccountBlockTemplate template;
    late _MockAccountBlockTemplate response;

    setUp(() {
      zenon = _MockZenon();
      embedded = _MockEmbeddedApi();
      acceleratorApi = _MockAcceleratorApi();
      accountBlockUtils = _MockAccountBlockUtils();
      template = _MockAccountBlockTemplate();
      response = _MockAccountBlockTemplate();

      when(() => zenon.embedded).thenReturn(embedded);
      when(() => embedded.accelerator).thenReturn(acceleratorApi);
      when(
        () => acceleratorApi.updatePhase(
          any(),
          any(),
          any(),
          any(),
          any(),
          any(),
        ),
      ).thenReturn(template);
    });

    test('initial state is UpdatePhaseInitial', () async {
      final UpdatePhaseBloc bloc = UpdatePhaseBloc(
        accountBlockUtils: accountBlockUtils,
        zenon: zenon,
      );
      expect(bloc.state, const UpdatePhaseInitial());
      await bloc.close();
    });

    blocTest<UpdatePhaseBloc, UpdatePhaseState>(
      'emits [loading, done] on success',
      setUp: () {
        when(
          () => accountBlockUtils.createAccountBlock(
            template,
            'update phase',
            address: owner,
          ),
        ).thenAnswer((_) async => response);
      },
      build: () =>
          UpdatePhaseBloc(accountBlockUtils: accountBlockUtils, zenon: zenon),
      act: (UpdatePhaseBloc bloc) => bloc.add(
        UpdatePhaseRequested(
          address: owner,
          projectId: projectId,
          name: 'Phase 1 Revised',
          description: 'Updated deliverables',
          url: 'https://github.com/zenon-network/syrius/pull/1',
          znnFundsNeeded: BigInt.from(40),
          qsrFundsNeeded: BigInt.from(400),
        ),
      ),
      expect: () => <UpdatePhaseState>[
        const UpdatePhaseLoading(),
        UpdatePhaseDone(accountBlock: response),
      ],
      verify: (_) {
        verify(
          () => acceleratorApi.updatePhase(
            projectId,
            'Phase 1 Revised',
            'Updated deliverables',
            'https://github.com/zenon-network/syrius/pull/1',
            BigInt.from(40),
            BigInt.from(400),
          ),
        ).called(1);
      },
    );

    blocTest<UpdatePhaseBloc, UpdatePhaseState>(
      'emits [loading, failure] on error',
      setUp: () {
        when(
          () => accountBlockUtils.createAccountBlock(
            any(),
            any(),
            address: any(named: 'address'),
          ),
        ).thenThrow(Exception('boom'));
      },
      build: () =>
          UpdatePhaseBloc(accountBlockUtils: accountBlockUtils, zenon: zenon),
      act: (UpdatePhaseBloc bloc) => bloc.add(
        UpdatePhaseRequested(
          address: owner,
          projectId: projectId,
          name: 'Phase 1 Revised',
          description: 'Updated deliverables',
          url: 'https://zenon.network',
          znnFundsNeeded: BigInt.from(40),
          qsrFundsNeeded: BigInt.from(400),
        ),
      ),
      expect: () => <Matcher>[
        isA<UpdatePhaseLoading>(),
        isA<UpdatePhaseFailure>().having(
          (UpdatePhaseFailure s) => s.exception,
          'exception',
          isA<FailureException>(),
        ),
      ],
    );
  });
}
