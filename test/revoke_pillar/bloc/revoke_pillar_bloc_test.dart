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
class MockZenonAddressUtils extends Mock implements ZenonAddressUtils {}
class MockAccountBlockTemplate extends Mock implements AccountBlockTemplate {}

void main() {
  initHydratedStorage();
  setUpAll(() {
    registerFallbackValue(AccountBlockTemplate(blockType: 1));
  });

  group('RevokePillarBloc', () {
    late MockZenon zenon;
    late MockEmbedded embedded;
    late MockPillarApi pillarApi;
    late MockAccountBlockUtils accountBlockUtils;
    late MockZenonAddressUtils zenonAddressUtils;
    late RevokePillarBloc bloc;
    late AccountBlockTemplate template;

    setUp(() {
      zenon = MockZenon();
      embedded = MockEmbedded();
      pillarApi = MockPillarApi();
      accountBlockUtils = MockAccountBlockUtils();
      zenonAddressUtils = MockZenonAddressUtils();
      template = MockAccountBlockTemplate();

      when(() => zenon.embedded).thenReturn(embedded);
      when(() => embedded.pillar).thenReturn(pillarApi);
      when(() => pillarApi.revoke(any())).thenReturn(template);
      when(
        () => accountBlockUtils.createAccountBlock(
          any(),
          any(),
          waitForRequiredPlasma: any(named: 'waitForRequiredPlasma'),
        ),
      ).thenAnswer((_) async => template);
      when(() => zenonAddressUtils.refreshBalance()).thenAnswer((_) {});

      bloc = RevokePillarBloc(
        accountBlockUtils: accountBlockUtils,
        zenon: zenon,
        zenonAddressUtils: zenonAddressUtils,
      );
    });

    test('initial state is correct', () {
      expect(bloc.state, const RevokePillarInitial());
    });

    blocTest<RevokePillarBloc, RevokePillarState>(
      'emits [loading, done] on success',
      build: () => bloc,
      act: (RevokePillarBloc bloc) =>
          bloc.add(const RevokePillarRequested(pillarName: 'pillar')),
      verify: (_) {
        verify(() => zenonAddressUtils.refreshBalance()).called(1);
      },
      expect: () => <RevokePillarState>[
        const RevokePillarLoading(),
        const RevokePillarDone(),
      ],
    );

    blocTest<RevokePillarBloc, RevokePillarState>(
      'emits [loading, failure] on SyriusException',
      setUp: () {
        when(() => pillarApi.revoke(any())).thenThrow(FailureException());
      },
      build: () => bloc,
      act: (RevokePillarBloc bloc) =>
          bloc.add(const RevokePillarRequested(pillarName: 'pillar')),
      expect: () => <Matcher>[
        isA<RevokePillarLoading>(),
        isA<RevokePillarFailure>().having(
          (RevokePillarFailure s) => s.exception,
          'exception',
          isA<FailureException>(),
        ),
      ],
    );
  });
}
