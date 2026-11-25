import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/create_project_stepper/create_project_stepper.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/exceptions/exceptions.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class _MockZenon extends Mock implements Zenon {}

class _MockEmbeddedApi extends Mock implements EmbeddedApi {}

class _MockAcceleratorApi extends Mock implements AcceleratorApi {}

class _MockAccountBlockUtils extends Mock implements AccountBlockUtils {}

class _MockZenonAddressUtils extends Mock implements ZenonAddressUtils {}

class _MockAccountBlockTemplate extends Mock implements AccountBlockTemplate {}

void main() {
  setUpAll(() {
    registerFallbackValue(AccountBlockTemplate(blockType: 1));
    registerFallbackValue(emptyAddress);
    registerFallbackValue(BigInt.zero);
  });

  group('CreateProjectBloc', () {
    late _MockZenon zenon;
    late _MockEmbeddedApi embedded;
    late _MockAcceleratorApi acceleratorApi;
    late _MockAccountBlockUtils accountBlockUtils;
    late _MockZenonAddressUtils zenonAddressUtils;
    late _MockAccountBlockTemplate template;
    late _MockAccountBlockTemplate response;
    final Address owner = Address.fromPublicKey(List<int>.filled(32, 4));

    setUp(() {
      zenon = _MockZenon();
      embedded = _MockEmbeddedApi();
      acceleratorApi = _MockAcceleratorApi();
      accountBlockUtils = _MockAccountBlockUtils();
      zenonAddressUtils = _MockZenonAddressUtils();
      template = _MockAccountBlockTemplate();
      response = _MockAccountBlockTemplate();

      when(() => zenon.embedded).thenReturn(embedded);
      when(() => embedded.accelerator).thenReturn(acceleratorApi);
      when(
        () => acceleratorApi.createProject(any(), any(), any(), any(), any()),
      ).thenReturn(template);
      when(() => zenonAddressUtils.refreshBalance()).thenAnswer((_) {});
    });

    test('initial state is CreateProjectInitial', () async {
      final CreateProjectBloc bloc = CreateProjectBloc(
        accountBlockUtils: accountBlockUtils,
        zenon: zenon,
        zenonAddressUtils: zenonAddressUtils,
      );
      expect(bloc.state, const CreateProjectInitial());
      await bloc.close();
    });

    blocTest<CreateProjectBloc, CreateProjectState>(
      'emits [loading, done] and refreshes balance on success',
      setUp: () {
        when(
          () => accountBlockUtils.createAccountBlock(
            template,
            'creating project',
            address: owner,
          ),
        ).thenAnswer((_) async => response);
      },
      build: () => CreateProjectBloc(
        accountBlockUtils: accountBlockUtils,
        zenon: zenon,
        zenonAddressUtils: zenonAddressUtils,
      ),
      act: (CreateProjectBloc bloc) => bloc.add(
        CreateProjectRequested(
          address: owner,
          name: 'My Project',
          description: 'Builds something useful',
          url: 'https://zenon.network',
          znnFundsNeeded: BigInt.from(100),
          qsrFundsNeeded: BigInt.from(1000),
        ),
      ),
      expect: () => <CreateProjectState>[
        const CreateProjectLoading(),
        CreateProjectDone(accountBlock: response),
      ],
      verify: (_) {
        verify(
          () => acceleratorApi.createProject(
            'My Project',
            'Builds something useful',
            'https://zenon.network',
            BigInt.from(100),
            BigInt.from(1000),
          ),
        ).called(1);
        verify(() => zenonAddressUtils.refreshBalance()).called(1);
      },
    );

    blocTest<CreateProjectBloc, CreateProjectState>(
      'emits [loading, failure] on SyriusException',
      setUp: () {
        when(
          () => accountBlockUtils.createAccountBlock(
            any(),
            any(),
            address: any(named: 'address'),
          ),
        ).thenThrow(NodeNotSyncedException());
      },
      build: () => CreateProjectBloc(
        accountBlockUtils: accountBlockUtils,
        zenon: zenon,
        zenonAddressUtils: zenonAddressUtils,
      ),
      act: (CreateProjectBloc bloc) => bloc.add(
        CreateProjectRequested(
          address: owner,
          name: 'My Project',
          description: 'Desc',
          url: 'https://zenon.network',
          znnFundsNeeded: BigInt.from(100),
          qsrFundsNeeded: BigInt.from(1000),
        ),
      ),
      expect: () => <Matcher>[
        isA<CreateProjectLoading>(),
        isA<CreateProjectFailure>().having(
          (CreateProjectFailure s) => s.exception,
          'exception',
          isA<NodeNotSyncedException>(),
        ),
      ],
    );
  });
}
