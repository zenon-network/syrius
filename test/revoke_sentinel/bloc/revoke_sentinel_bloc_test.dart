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

class MockSentinelApi extends Mock implements SentinelApi {}

class MockAccountBlockUtils extends Mock implements AccountBlockUtils {}

class MockZenonAddressUtils extends Mock implements ZenonAddressUtils {}

class MockAccountBlockTemplate extends Mock implements AccountBlockTemplate {}

void main() {
  initHydratedStorage();

  setUpAll(() {
    registerFallbackValue(AccountBlockTemplate(blockType: 1));
  });

  group('RevokeSentinelBloc', () {
    late MockZenon zenon;
    late MockEmbedded embedded;
    late MockSentinelApi sentinelApi;
    late MockAccountBlockUtils accountBlockUtils;
    late MockZenonAddressUtils zenonAddressUtils;
    late RevokeSentinelBloc bloc;
    late AccountBlockTemplate template;

    setUp(() {
      zenon = MockZenon();
      embedded = MockEmbedded();
      sentinelApi = MockSentinelApi();
      accountBlockUtils = MockAccountBlockUtils();
      zenonAddressUtils = MockZenonAddressUtils();
      template = MockAccountBlockTemplate();

      when(() => zenon.embedded).thenReturn(embedded);
      when(() => embedded.sentinel).thenReturn(sentinelApi);
      when(() => sentinelApi.revoke()).thenReturn(template);
      when(
        () => accountBlockUtils.createAccountBlock(
          any(),
          any(),
          waitForRequiredPlasma: any(named: 'waitForRequiredPlasma'),
        ),
      ).thenAnswer((_) async => template);
      when(() => zenonAddressUtils.refreshBalance()).thenAnswer((_) {});

      bloc = RevokeSentinelBloc(
        accountBlockUtils: accountBlockUtils,
        zenon: zenon,
        zenonAddressUtils: zenonAddressUtils,
      );
    });

    test('initial state is correct', () {
      expect(bloc.state, const RevokeSentinelInitial());
    });

    blocTest<RevokeSentinelBloc, RevokeSentinelState>(
      'emits [loading, done] on success',
      build: () => bloc,
      act: (RevokeSentinelBloc bloc) =>
          bloc.add(const RevokeSentinelRequested()),
      verify: (_) {
        verify(() => zenonAddressUtils.refreshBalance()).called(1);
      },
      expect: () => <RevokeSentinelState>[
        const RevokeSentinelLoading(),
        const RevokeSentinelDone(),
      ],
    );

    blocTest<RevokeSentinelBloc, RevokeSentinelState>(
      'emits [loading, failure] on SyriusException',
      setUp: () {
        when(() => sentinelApi.revoke()).thenThrow(FailureException());
      },
      build: () => bloc,
      act: (RevokeSentinelBloc bloc) =>
          bloc.add(const RevokeSentinelRequested()),
      expect: () => <Matcher>[
        isA<RevokeSentinelLoading>(),
        isA<RevokeSentinelFailure>().having(
          (RevokeSentinelFailure s) => s.exception,
          'exception',
          isA<FailureException>(),
        ),
      ],
    );
  });
}
