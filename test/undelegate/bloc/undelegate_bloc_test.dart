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
class MockPillarApi extends Mock implements PillarApi {}
class MockAccountBlockUtils extends Mock implements AccountBlockUtils {}
class MockAccountBlockTemplate extends Mock implements AccountBlockTemplate {}
class FakeAddress extends Fake implements Address {}

void main() {
  initHydratedStorage();
  setUpAll(() {
    registerFallbackValue(FakeAddress());
    registerFallbackValue(AccountBlockTemplate(blockType: 1));
  });

  group('UndelegateBloc', () {
    late MockZenon zenon;
    late MockEmbedded embedded;
    late MockPillarApi pillarApi;
    late MockAccountBlockUtils accountBlockUtils;
    late UndelegateBloc bloc;
    late AccountBlockTemplate template;

    setUp(() {
      zenon = MockZenon();
      embedded = MockEmbedded();
      pillarApi = MockPillarApi();
      accountBlockUtils = MockAccountBlockUtils();
      template = MockAccountBlockTemplate();

      when(() => zenon.embedded).thenReturn(embedded);
      when(() => embedded.pillar).thenReturn(pillarApi);
      when(() => pillarApi.undelegate()).thenReturn(template);
      when(
        () => accountBlockUtils.createAccountBlock(
          any(),
          any(),
          address: any(named: 'address'),
          waitForRequiredPlasma: any(named: 'waitForRequiredPlasma'),
        ),
      ).thenAnswer((_) async => template);

      bloc = UndelegateBloc(accountBlockUtils: accountBlockUtils, zenon: zenon);
    });

    test('initial state is correct', () {
      expect(bloc.state, const UndelegateInitial());
    });

    blocTest<UndelegateBloc, UndelegateState>(
      'emits loading and calls dependencies on success',
      build: () => bloc,
      act: (UndelegateBloc bloc) =>
          bloc.add(UndelegateRequested(address: emptyAddress)),
      expect: () => <UndelegateState>[
        const UndelegateLoading(),
      ],
    );

    blocTest<UndelegateBloc, UndelegateState>(
      'emits [loading, failure] on SyriusException',
      setUp: () {
        when(() => pillarApi.undelegate()).thenThrow(FailureException());
      },
      build: () => bloc,
      act: (UndelegateBloc bloc) =>
          bloc.add(UndelegateRequested(address: emptyAddress)),
      expect: () => <Matcher>[
        isA<UndelegateLoading>(),
        isA<UndelegateFailure>().having(
          (UndelegateFailure s) => s.exception,
          'exception',
          isA<FailureException>(),
        ),
      ],
    );
  });
}
