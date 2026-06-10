import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/exceptions/exceptions.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

import '../../helpers/hydrated_bloc.dart';

class MockZenon extends Mock implements Zenon {}

class MockEmbedded extends Mock implements EmbeddedApi {}

class MockPlasmaApi extends Mock implements PlasmaApi {}

class MockAccountBlockUtils extends Mock implements AccountBlockUtils {}

class MockZenonAddressUtils extends Mock implements ZenonAddressUtils {}

class MockAccountBlockTemplate extends Mock implements AccountBlockTemplate {}

void main() {
  initHydratedStorage();

  setUpAll(() {
    registerFallbackValue(AccountBlockTemplate(blockType: 1));
    registerFallbackValue(emptyAddress);
    registerFallbackValue(BigInt.zero);
  });

  group('FusePlasmaBloc', () {
    late MockZenon zenon;
    late MockEmbedded embedded;
    late MockPlasmaApi plasmaApi;
    late MockAccountBlockUtils accountBlockUtils;
    late MockZenonAddressUtils zenonAddressUtils;
    late FusePlasmaBloc bloc;
    late AccountBlockTemplate template;

    setUp(() {
      zenon = MockZenon();
      embedded = MockEmbedded();
      plasmaApi = MockPlasmaApi();
      accountBlockUtils = MockAccountBlockUtils();
      zenonAddressUtils = MockZenonAddressUtils();
      template = MockAccountBlockTemplate();

      when(() => zenon.embedded).thenReturn(embedded);
      when(() => embedded.plasma).thenReturn(plasmaApi);
      when(() => plasmaApi.fuse(any(), any())).thenReturn(template);
      when(
        () => accountBlockUtils.createAccountBlock(
          any(),
          any(),
          waitForRequiredPlasma: any(named: 'waitForRequiredPlasma'),
        ),
      ).thenAnswer((_) async => template);
      when(() => zenonAddressUtils.refreshBalance()).thenAnswer((_) {});

      bloc = FusePlasmaBloc(
        accountBlockUtils: accountBlockUtils,
        zenon: zenon,
        zenonAddressUtils: zenonAddressUtils,
      );
    });

    test('initial state is correct', () {
      expect(bloc.state, const FusePlasmaInitial());
    });

    blocTest<FusePlasmaBloc, FusePlasmaState>(
      'emits [loading, done] on success',
      build: () => bloc,
      act: (FusePlasmaBloc bloc) => bloc.add(
        FusePlasmaRequested(
          beneficiaryAddress: emptyAddress.toString(),
          amount: BigInt.one,
        ),
      ),
      verify: (_) {
        verify(() => zenonAddressUtils.refreshBalance()).called(1);
      },
      expect: () => <FusePlasmaState>[
        const FusePlasmaLoading(),
        FusePlasmaDone(accountBlock: template),
      ],
    );

    blocTest<FusePlasmaBloc, FusePlasmaState>(
      'emits [loading, failure] on SyriusException',
      setUp: () {
        when(() => plasmaApi.fuse(any(), any())).thenThrow(FailureException());
      },
      build: () => bloc,
      act: (FusePlasmaBloc bloc) => bloc.add(
        FusePlasmaRequested(
          beneficiaryAddress: emptyAddress.toString(),
          amount: BigInt.one,
        ),
      ),
      expect: () => <Matcher>[
        isA<FusePlasmaLoading>(),
        isA<FusePlasmaFailure>().having(
          (FusePlasmaFailure s) => s.exception,
          'exception',
          isA<FailureException>(),
        ),
      ],
    );
  });
}
