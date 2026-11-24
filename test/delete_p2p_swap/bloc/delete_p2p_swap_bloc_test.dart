import 'package:bloc/bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';

class MockP2pSwapRepository extends Mock
    implements P2pSwapRepository<HtlcSwap> {}

class _RecordingBlocObserver extends BlocObserver {
  final List<Object> errors = <Object>[];

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    errors.add(error);
    super.onError(bloc, error, stackTrace);
  }
}

void main() {
  group('DeleteP2pSwapBloc', () {
    const String swapId = 'swap-id';

    late MockP2pSwapRepository swapRepository;

    DeleteP2pSwapBloc buildBloc() =>
        DeleteP2pSwapBloc(swapRepository: swapRepository);

    setUp(() {
      swapRepository = MockP2pSwapRepository();
      when(() => swapRepository.deleteSwap(swapId)).thenAnswer((_) async {});
    });

    test('initial state is correct', () {
      final DeleteP2pSwapBloc bloc = buildBloc();
      addTearDown(bloc.close);

      expect(bloc.state, const DeleteP2pSwapInitial());
    });

    blocTest<DeleteP2pSwapBloc, DeleteP2pSwapState>(
      'deletes the swap and emits [loading, done]',
      build: buildBloc,
      act: (DeleteP2pSwapBloc bloc) =>
          bloc.add(const DeleteP2pSwapRequested(swapId: swapId)),
      expect: () => const <DeleteP2pSwapState>[
        DeleteP2pSwapLoading(),
        DeleteP2pSwapDone(),
      ],
      verify: (_) {
        verify(() => swapRepository.deleteSwap(swapId)).called(1);
      },
    );

    blocTest<DeleteP2pSwapBloc, DeleteP2pSwapState>(
      'preserves a SyriusException from the repository',
      setUp: () {
        when(
          () => swapRepository.deleteSwap(swapId),
        ).thenThrow(SyriusException('Unable to delete swap.'));
      },
      build: buildBloc,
      act: (DeleteP2pSwapBloc bloc) =>
          bloc.add(const DeleteP2pSwapRequested(swapId: swapId)),
      expect: () => <Matcher>[
        isA<DeleteP2pSwapLoading>(),
        isA<DeleteP2pSwapFailure>().having(
          (DeleteP2pSwapFailure state) => state.exception.message,
          'message',
          'Unable to delete swap.',
        ),
      ],
    );

    blocTest<DeleteP2pSwapBloc, DeleteP2pSwapState>(
      'converts an unexpected error to FailureException',
      setUp: () {
        when(
          () => swapRepository.deleteSwap(swapId),
        ).thenThrow(StateError('boom'));
      },
      build: buildBloc,
      act: (DeleteP2pSwapBloc bloc) =>
          bloc.add(const DeleteP2pSwapRequested(swapId: swapId)),
      expect: () => <Matcher>[
        isA<DeleteP2pSwapLoading>(),
        isA<DeleteP2pSwapFailure>().having(
          (DeleteP2pSwapFailure state) => state.exception,
          'exception',
          isA<FailureException>(),
        ),
      ],
    );

    test(
      'sanitizes unexpected delete errors before reporting to BlocObserver',
      () async {
        const String sensitiveDetail = 'sensitive-delete-detail';
        final BlocObserver previousObserver = Bloc.observer;
        final _RecordingBlocObserver observer = _RecordingBlocObserver();
        Bloc.observer = observer;
        addTearDown(() => Bloc.observer = previousObserver);

        when(
          () => swapRepository.deleteSwap(swapId),
        ).thenThrow(StateError(sensitiveDetail));

        final DeleteP2pSwapBloc bloc = buildBloc()
          ..add(const DeleteP2pSwapRequested(swapId: swapId));
        addTearDown(bloc.close);

        await expectLater(
          bloc.stream,
          emitsThrough(isA<DeleteP2pSwapFailure>()),
        );

        expect(observer.errors, hasLength(1));
        expect(observer.errors.single, isA<RedactedSwapError>());
        expect(observer.errors.single.toString(), 'StateError');
        expect(
          observer.errors.single.toString(),
          isNot(contains(sensitiveDetail)),
        );
      },
    );
  });
}
