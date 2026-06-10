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

class MockStakeApi extends Mock implements StakeApi {}

class MockAccountBlockUtils extends Mock implements AccountBlockUtils {}

class MockZenonAddressUtils extends Mock implements ZenonAddressUtils {}

class MockAccountBlockTemplate extends Mock implements AccountBlockTemplate {}

void main() {
  initHydratedStorage();

  setUpAll(() {
    registerFallbackValue(AccountBlockTemplate(blockType: 1));
    registerFallbackValue(emptyHash);
  });

  group('CancelStakeBloc', () {
    late MockZenon zenon;
    late MockEmbedded embedded;
    late MockStakeApi stakeApi;
    late MockAccountBlockUtils accountBlockUtils;
    late MockZenonAddressUtils zenonAddressUtils;
    late CancelStakeBloc bloc;
    late AccountBlockTemplate template;

    setUp(() {
      zenon = MockZenon();
      embedded = MockEmbedded();
      stakeApi = MockStakeApi();
      accountBlockUtils = MockAccountBlockUtils();
      zenonAddressUtils = MockZenonAddressUtils();
      template = MockAccountBlockTemplate();

      when(() => zenon.embedded).thenReturn(embedded);
      when(() => embedded.stake).thenReturn(stakeApi);
      when(() => stakeApi.cancel(any())).thenReturn(template);
      when(
        () => accountBlockUtils.createAccountBlock(
          any(),
          any(),
          waitForRequiredPlasma: any(named: 'waitForRequiredPlasma'),
        ),
      ).thenAnswer((_) async => template);
      when(() => zenonAddressUtils.refreshBalance()).thenAnswer((_) {});

      bloc = CancelStakeBloc(
        accountBlockUtils: accountBlockUtils,
        zenon: zenon,
        zenonAddressUtils: zenonAddressUtils,
      );
    });

    test('initial state is correct', () {
      expect(bloc.state, const CancelStakeInitial());
    });

    blocTest<CancelStakeBloc, CancelStakeState>(
      'emits [loading, done] on success',
      build: () => bloc,
      act: (CancelStakeBloc bloc) => bloc.add(
        CancelStakeRequested(stakeHash: emptyHash),
      ),
      verify: (_) {
        verify(() => zenonAddressUtils.refreshBalance()).called(1);
      },
      expect: () => <CancelStakeState>[
        const CancelStakeLoading(),
        const CancelStakeDone(),
      ],
    );

    blocTest<CancelStakeBloc, CancelStakeState>(
      'emits [loading, failure] on SyriusException',
      setUp: () {
        when(() => stakeApi.cancel(any())).thenThrow(FailureException());
      },
      build: () => bloc,
      act: (CancelStakeBloc bloc) => bloc.add(
        CancelStakeRequested(stakeHash: emptyHash),
      ),
      expect: () => <Matcher>[
        isA<CancelStakeLoading>(),
        isA<CancelStakeFailure>().having(
          (CancelStakeFailure s) => s.exception,
          'exception',
          isA<FailureException>(),
        ),
      ],
    );
  });
}
