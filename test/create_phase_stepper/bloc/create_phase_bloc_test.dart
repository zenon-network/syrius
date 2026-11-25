import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/create_phase_stepper/create_phase_stepper.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/exceptions/exceptions.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class _MockZenon extends Mock implements Zenon {}

class _MockEmbeddedApi extends Mock implements EmbeddedApi {}

class _MockAcceleratorApi extends Mock implements AcceleratorApi {}

class _MockAccountBlockUtils extends Mock implements AccountBlockUtils {}

class _MockAccountBlockTemplate extends Mock implements AccountBlockTemplate {}

void main() {
  final Hash projectId = Hash.digest(List<int>.filled(32, 1));
  final Address owner = Address.fromPublicKey(List<int>.filled(32, 5));

  setUpAll(() {
    registerFallbackValue(AccountBlockTemplate(blockType: 1));
    registerFallbackValue(emptyAddress);
    registerFallbackValue(projectId);
    registerFallbackValue(BigInt.zero);
  });

  group('CreatePhaseBloc', () {
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
        () => acceleratorApi.addPhase(any(), any(), any(), any(), any(), any()),
      ).thenReturn(template);
    });

    test('initial state is CreatePhaseInitial', () async {
      final CreatePhaseBloc bloc = CreatePhaseBloc(
        accountBlockUtils: accountBlockUtils,
        zenon: zenon,
      );
      expect(bloc.state, const CreatePhaseInitial());
      await bloc.close();
    });

    blocTest<CreatePhaseBloc, CreatePhaseState>(
      'emits [loading, done] on success',
      setUp: () {
        when(
          () => accountBlockUtils.createAccountBlock(
            template,
            'create phase',
            address: owner,
          ),
        ).thenAnswer((_) async => response);
      },
      build: () =>
          CreatePhaseBloc(accountBlockUtils: accountBlockUtils, zenon: zenon),
      act: (CreatePhaseBloc bloc) => bloc.add(
        CreatePhaseRequested(
          address: owner,
          projectId: projectId,
          name: 'Phase 1',
          description: 'Initial milestone',
          url: 'https://github.com/zenon-network/syrius',
          znnFundsNeeded: BigInt.from(50),
          qsrFundsNeeded: BigInt.from(500),
        ),
      ),
      expect: () => <CreatePhaseState>[
        const CreatePhaseLoading(),
        CreatePhaseDone(accountBlock: response),
      ],
      verify: (_) {
        verify(
          () => acceleratorApi.addPhase(
            projectId,
            'Phase 1',
            'Initial milestone',
            'https://github.com/zenon-network/syrius',
            BigInt.from(50),
            BigInt.from(500),
          ),
        ).called(1);
      },
    );

    blocTest<CreatePhaseBloc, CreatePhaseState>(
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
          CreatePhaseBloc(accountBlockUtils: accountBlockUtils, zenon: zenon),
      act: (CreatePhaseBloc bloc) => bloc.add(
        CreatePhaseRequested(
          address: owner,
          projectId: projectId,
          name: 'Phase 1',
          description: 'Desc',
          url: 'https://zenon.network',
          znnFundsNeeded: BigInt.from(50),
          qsrFundsNeeded: BigInt.from(500),
        ),
      ),
      expect: () => <Matcher>[
        isA<CreatePhaseLoading>(),
        isA<CreatePhaseFailure>().having(
          (CreatePhaseFailure s) => s.exception,
          'exception',
          isA<FailureException>(),
        ),
      ],
    );
  });
}
