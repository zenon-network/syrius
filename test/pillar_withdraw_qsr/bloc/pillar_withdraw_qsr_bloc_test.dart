import 'dart:async';

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

class FakeAddress extends Fake implements Address {}

void main() {
  initHydratedStorage();
  setUpAll(() {
    registerFallbackValue(FakeAddress());
    registerFallbackValue(AccountBlockTemplate(blockType: 1));
  });

  group('PillarWithdrawQsrBloc', () {
    late MockZenon zenon;
    late MockEmbedded embedded;
    late MockPillarApi pillarApi;
    late MockAccountBlockUtils accountBlockUtils;
    late MockZenonAddressUtils zenonAddressUtils;
    late PillarWithdrawQsrBloc bloc;
    late AccountBlockTemplate template;

    PillarWithdrawQsrBloc buildBloc({
      Duration pollInterval = Duration.zero,
      Duration confirmationTimeout = const Duration(seconds: 5),
      Duration snapshotReadTimeout = const Duration(seconds: 5),
    }) => PillarWithdrawQsrBloc(
      accountBlockUtils: accountBlockUtils,
      zenon: zenon,
      zenonAddressUtils: zenonAddressUtils,
      pollInterval: pollInterval,
      confirmationTimeout: confirmationTimeout,
      snapshotReadTimeout: snapshotReadTimeout,
    );

    Future<void> dispatchAndWaitForCompletion(
      PillarWithdrawQsrBloc target,
      PillarWithdrawQsrRequested event,
    ) async {
      final Future<PillarWithdrawQsrState> completed = target.stream
          .firstWhere(
            (PillarWithdrawQsrState state) =>
                state is PillarWithdrawQsrPopulated ||
                state is PillarWithdrawQsrFailure,
          )
          .timeout(const Duration(seconds: 2));
      target.add(event);
      await completed;
    }

    setUp(() {
      zenon = MockZenon();
      embedded = MockEmbedded();
      pillarApi = MockPillarApi();
      accountBlockUtils = MockAccountBlockUtils();
      zenonAddressUtils = MockZenonAddressUtils();
      template = MockAccountBlockTemplate();

      when(() => zenon.embedded).thenReturn(embedded);
      when(() => embedded.pillar).thenReturn(pillarApi);
      when(() => pillarApi.withdrawQsr()).thenReturn(template);
      when(
        () => pillarApi.getDepositedQsr(any()),
      ).thenAnswer((_) async => BigInt.from(150000));
      when(
        () => accountBlockUtils.createAccountBlock(
          any(),
          any(),
          address: any(named: 'address'),
          waitForRequiredPlasma: any(named: 'waitForRequiredPlasma'),
        ),
      ).thenAnswer((_) async => template);
      when(() => zenonAddressUtils.refreshBalance()).thenAnswer((_) {});

      bloc = buildBloc();
    });

    test('initial state is correct', () {
      expect(bloc.state, const PillarWithdrawQsrInitial());
    });

    blocTest<PillarWithdrawQsrBloc, PillarWithdrawQsrState>(
      'polls getDepositedQsr until withdrawn deposit decreases',
      setUp: () {
        int calls = 0;
        when(() => pillarApi.getDepositedQsr(emptyAddress)).thenAnswer((
          _,
        ) async {
          calls += 1;
          if (calls <= 2) {
            return BigInt.from(150000);
          }
          if (calls == 3) {
            throw Exception('transient RPC error');
          }
          return BigInt.zero;
        });
      },
      build: buildBloc,
      act: (PillarWithdrawQsrBloc bloc) => dispatchAndWaitForCompletion(
        bloc,
        PillarWithdrawQsrRequested(address: emptyAddress),
      ),
      expect: () => <PillarWithdrawQsrState>[
        const PillarWithdrawQsrLoading(),
        const PillarWithdrawQsrPopulated(),
      ],
      verify: (_) {
        verify(() => pillarApi.getDepositedQsr(emptyAddress)).called(4);
        verify(() => zenonAddressUtils.refreshBalance()).called(1);
      },
    );

    blocTest<PillarWithdrawQsrBloc, PillarWithdrawQsrState>(
      'polls until deposit reaches zero when initial snapshot fails',
      setUp: () {
        int calls = 0;
        when(() => pillarApi.getDepositedQsr(emptyAddress)).thenAnswer((
          _,
        ) async {
          calls += 1;
          if (calls == 1) {
            throw Exception('snapshot failed');
          }
          if (calls == 2) {
            return BigInt.from(150000);
          }
          return BigInt.zero;
        });
      },
      build: buildBloc,
      act: (PillarWithdrawQsrBloc bloc) => dispatchAndWaitForCompletion(
        bloc,
        PillarWithdrawQsrRequested(address: emptyAddress),
      ),
      expect: () => <PillarWithdrawQsrState>[
        const PillarWithdrawQsrLoading(),
        const PillarWithdrawQsrPopulated(),
      ],
      verify: (_) {
        verify(() => pillarApi.getDepositedQsr(emptyAddress)).called(3);
        verify(() => zenonAddressUtils.refreshBalance()).called(1);
      },
    );

    blocTest<PillarWithdrawQsrBloc, PillarWithdrawQsrState>(
      'polls until deposit reaches zero when initial snapshot times out',
      setUp: () {
        final Completer<BigInt> stalledSnapshot = Completer<BigInt>();
        int calls = 0;
        when(() => pillarApi.getDepositedQsr(emptyAddress)).thenAnswer((_) {
          calls += 1;
          if (calls == 1) {
            return stalledSnapshot.future;
          }
          if (calls == 2) {
            return Future<BigInt>.value(BigInt.from(150000));
          }
          return Future<BigInt>.value(BigInt.zero);
        });
      },
      build: () => buildBloc(
        snapshotReadTimeout: const Duration(milliseconds: 10),
      ),
      act: (PillarWithdrawQsrBloc bloc) => dispatchAndWaitForCompletion(
        bloc,
        PillarWithdrawQsrRequested(address: emptyAddress),
      ),
      expect: () => <PillarWithdrawQsrState>[
        const PillarWithdrawQsrLoading(),
        const PillarWithdrawQsrPopulated(),
      ],
      verify: (_) {
        verify(() => pillarApi.getDepositedQsr(emptyAddress)).called(3);
        verify(() => zenonAddressUtils.refreshBalance()).called(1);
      },
    );

    blocTest<PillarWithdrawQsrBloc, PillarWithdrawQsrState>(
      'skips confirmation polling when initial deposit is zero',
      setUp: () {
        when(
          () => pillarApi.getDepositedQsr(emptyAddress),
        ).thenAnswer((_) async => BigInt.zero);
      },
      build: buildBloc,
      act: (PillarWithdrawQsrBloc bloc) => dispatchAndWaitForCompletion(
        bloc,
        PillarWithdrawQsrRequested(address: emptyAddress),
      ),
      expect: () => <PillarWithdrawQsrState>[
        const PillarWithdrawQsrLoading(),
        const PillarWithdrawQsrPopulated(),
      ],
      verify: (_) {
        verify(() => pillarApi.getDepositedQsr(emptyAddress)).called(1);
        verify(() => zenonAddressUtils.refreshBalance()).called(1);
      },
    );

    blocTest<PillarWithdrawQsrBloc, PillarWithdrawQsrState>(
      'still emits populated when confirmation polling times out',
      build: () => buildBloc(confirmationTimeout: Duration.zero),
      act: (PillarWithdrawQsrBloc bloc) => dispatchAndWaitForCompletion(
        bloc,
        PillarWithdrawQsrRequested(address: emptyAddress),
      ),
      expect: () => <PillarWithdrawQsrState>[
        const PillarWithdrawQsrLoading(),
        const PillarWithdrawQsrPopulated(),
      ],
      verify: (_) {
        verify(() => zenonAddressUtils.refreshBalance()).called(1);
      },
    );

    blocTest<PillarWithdrawQsrBloc, PillarWithdrawQsrState>(
      'emits [loading, failure] on SyriusException',
      setUp: () {
        when(() => pillarApi.withdrawQsr()).thenThrow(FailureException());
      },
      build: () => bloc,
      act: (PillarWithdrawQsrBloc bloc) =>
          bloc.add(PillarWithdrawQsrRequested(address: emptyAddress)),
      expect: () => <Matcher>[
        isA<PillarWithdrawQsrLoading>(),
        isA<PillarWithdrawQsrFailure>().having(
          (PillarWithdrawQsrFailure s) => s.exception,
          'exception',
          isA<FailureException>(),
        ),
      ],
    );
  });
}
