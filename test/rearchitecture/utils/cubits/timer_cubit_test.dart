import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/cubits/timer_cubit.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/exceptions/exceptions.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

import '../../../helpers/hydrated_bloc.dart';

class _RecordingBlocObserver extends BlocObserver {
  final List<Object> errors = <Object>[];

  @override
  void onError(BlocBase<dynamic> bloc, Object error, StackTrace stackTrace) {
    errors.add(error);
    super.onError(bloc, error, stackTrace);
  }
}

class MockZenon extends Mock implements Zenon {}

class MockWsClient extends Mock implements WsClient {}

class TestTimerState extends TimerState<int> {
  const TestTimerState({super.status, super.data, super.error});

  factory TestTimerState.fromJson(Map<String, dynamic> json) => TestTimerState(
    status: TimerStatus.values.firstWhere(
      (TimerStatus s) => s.name == json['status'],
    ),
    data: json['data'] as int?,
    error: json['error'] == null
        ? null
        : SyriusException.fromJson(json['error'] as Map<String, dynamic>),
  );

  @override
  TimerState<int> copyWith({
    TimerStatus? status,
    int? data,
    SyriusException? error,
  }) {
    return TestTimerState(
      status: status ?? this.status,
      data: data ?? this.data,
      error: error ?? this.error,
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'status': status.name,
    'data': data,
    'error': error?.toJson(),
  };
}

class TestTimerCubit extends TimerCubit<int, TestTimerState> {
  TestTimerCubit({
    required super.zenon,
    required this.fetchCallback,
    super.refreshInterval = const Duration(days: 1),
  }) : super(initialState: const TestTimerState());

  final Future<int> Function() fetchCallback;

  @override
  Future<int> fetch() => fetchCallback();

  @override
  TestTimerState? fromJson(Map<String, dynamic> json) =>
      TestTimerState.fromJson(json);

  @override
  Map<String, dynamic>? toJson(TestTimerState state) => state.toJson();
}

void main() {
  initHydratedStorage();

  group('TimerCubit', () {
    late MockZenon mockZenon;
    late MockWsClient mockWsClient;

    setUp(() {
      mockZenon = MockZenon();
      mockWsClient = MockWsClient();
      when(() => mockZenon.wsClient).thenReturn(mockWsClient);
      when(() => mockWsClient.isClosed()).thenReturn(false);
    });

    test('initial state is initial', () {
      final TestTimerCubit cubit = TestTimerCubit(
        zenon: mockZenon,
        fetchCallback: () async => 1,
      );
      addTearDown(cubit.close);
      expect(cubit.state.status, TimerStatus.initial);
    });

    blocTest<TestTimerCubit, TestTimerState>(
      'emits loading then success when fetch succeeds',
      build: () =>
          TestTimerCubit(zenon: mockZenon, fetchCallback: () async => 10),
      act: (TestTimerCubit cubit) => cubit.fetchDataPeriodically(),
      expect: () => <TestTimerState>[
        const TestTimerState(status: TimerStatus.loading),
        const TestTimerState(status: TimerStatus.success, data: 10),
      ],
    );

    blocTest<TestTimerCubit, TestTimerState>(
      'emits loading then failure with SyriusException',
      build: () => TestTimerCubit(
        zenon: mockZenon,
        fetchCallback: () async => throw FailureException(),
      ),
      act: (TestTimerCubit cubit) => cubit.fetchDataPeriodically(),
      expect: () => <Matcher>[
        isA<TestTimerState>().having(
          (TestTimerState s) => s.status,
          'status',
          TimerStatus.loading,
        ),
        isA<TestTimerState>()
            .having(
              (TestTimerState s) => s.status,
              'status',
              TimerStatus.failure,
            )
            .having(
              (TestTimerState s) => s.error,
              'error',
              isA<FailureException>(),
            ),
      ],
    );

    blocTest<TestTimerCubit, TestTimerState>(
      'emits loading then failure when ws client is closed',
      setUp: () {
        when(() => mockWsClient.isClosed()).thenReturn(true);
      },
      build: () =>
          TestTimerCubit(zenon: mockZenon, fetchCallback: () async => 10),
      act: (TestTimerCubit cubit) => cubit.fetchDataPeriodically(),
      expect: () => <Matcher>[
        isA<TestTimerState>().having(
          (TestTimerState s) => s.status,
          'status',
          TimerStatus.loading,
        ),
        isA<TestTimerState>().having(
          (TestTimerState s) => s.status,
          'status',
          TimerStatus.failure,
        ),
      ],
    );

    test(
      'does not throw, emit, or leak timers when fetch completes after close',
      () async {
        final Completer<int> completer = Completer<int>();
        final List<TestTimerState> emittedStates = <TestTimerState>[];
        final TestTimerCubit cubit = TestTimerCubit(
          zenon: mockZenon,
          fetchCallback: () => completer.future,
        );
        final StreamSubscription<TestTimerState> subscription = cubit.stream
            .listen(emittedStates.add);
        addTearDown(subscription.cancel);

        final Future<void> fetchFuture = cubit.fetchDataPeriodically();
        await Future<void>.delayed(Duration.zero);

        await cubit.close();
        completer.complete(42);

        await expectLater(fetchFuture, completes);
        expect(emittedStates, <TestTimerState>[
          const TestTimerState(status: TimerStatus.loading),
        ]);
        expect(cubit.isTimerActive, isFalse);
      },
    );

    test('does not throw, emit, or leak timers when fetch fails with '
        'SyriusException after close', () async {
      final Completer<int> completer = Completer<int>();
      final List<TestTimerState> emittedStates = <TestTimerState>[];
      final TestTimerCubit cubit = TestTimerCubit(
        zenon: mockZenon,
        fetchCallback: () => completer.future,
      );
      final StreamSubscription<TestTimerState> subscription = cubit.stream
          .listen(emittedStates.add);
      addTearDown(subscription.cancel);

      final Future<void> fetchFuture = cubit.fetchDataPeriodically();
      await Future<void>.delayed(Duration.zero);

      await cubit.close();
      completer.completeError(FailureException());

      await expectLater(fetchFuture, completes);
      expect(emittedStates, <TestTimerState>[
        const TestTimerState(status: TimerStatus.loading),
      ]);
      expect(cubit.isTimerActive, isFalse);
    });

    test('does not throw, emit, report errors, or leak timers when fetch fails '
        'with an unexpected error after close', () async {
      final BlocObserver previousObserver = Bloc.observer;
      final _RecordingBlocObserver observer = _RecordingBlocObserver();
      Bloc.observer = observer;
      addTearDown(() => Bloc.observer = previousObserver);

      final Completer<int> completer = Completer<int>();
      final List<TestTimerState> emittedStates = <TestTimerState>[];
      final TestTimerCubit cubit = TestTimerCubit(
        zenon: mockZenon,
        fetchCallback: () => completer.future,
      );
      final StreamSubscription<TestTimerState> subscription = cubit.stream
          .listen(emittedStates.add);
      addTearDown(subscription.cancel);

      final Future<void> fetchFuture = cubit.fetchDataPeriodically();
      await Future<void>.delayed(Duration.zero);

      await cubit.close();
      completer.completeError(StateError('unexpected failure'));

      await expectLater(fetchFuture, completes);
      expect(emittedStates, <TestTimerState>[
        const TestTimerState(status: TimerStatus.loading),
      ]);
      expect(observer.errors, isEmpty);
      expect(cubit.isTimerActive, isFalse);
    });

    test(
      'does nothing when fetchDataPeriodically is called after close',
      () async {
        int fetchCalls = 0;
        final TestTimerCubit cubit = TestTimerCubit(
          zenon: mockZenon,
          fetchCallback: () async {
            fetchCalls++;
            return 1;
          },
        );

        await cubit.close();
        await cubit.fetchDataPeriodically();

        expect(fetchCalls, 0);
        expect(cubit.isTimerActive, isFalse);
      },
    );

    test('schedules periodic refresh and cancels timer on close', () async {
      int fetchCalls = 0;
      final Completer<void> secondFetchCompleted = Completer<void>();
      final TestTimerCubit cubit = TestTimerCubit(
        zenon: mockZenon,
        refreshInterval: const Duration(milliseconds: 25),
        fetchCallback: () async {
          fetchCalls++;
          if (fetchCalls == 2 && !secondFetchCompleted.isCompleted) {
            secondFetchCompleted.complete();
          }
          return fetchCalls;
        },
      );
      addTearDown(cubit.close);

      await cubit.fetchDataPeriodically();
      expect(fetchCalls, 1);
      expect(cubit.isTimerActive, isTrue);

      await secondFetchCompleted.future.timeout(const Duration(seconds: 2));
      await Future<void>.delayed(Duration.zero);
      expect(fetchCalls, 2);
      expect(cubit.isTimerActive, isTrue);

      await cubit.close();
      expect(cubit.isTimerActive, isFalse);

      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(fetchCalls, 2);
    });
  });
}
