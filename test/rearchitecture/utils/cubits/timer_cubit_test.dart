import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/cubits/timer_cubit.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/exceptions/exceptions.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

import '../../../helpers/hydrated_bloc.dart';

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
  }) : super(
         initialState: const TestTimerState(),
         refreshInterval: const Duration(days: 1),
       );

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
      expect(cubit.state.status, TimerStatus.initial);
    });

    blocTest<TestTimerCubit, TestTimerState>(
      'emits loading then success when fetch succeeds',
      build: () => TestTimerCubit(
        zenon: mockZenon,
        fetchCallback: () async => 10,
      ),
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
      build: () => TestTimerCubit(
        zenon: mockZenon,
        fetchCallback: () async => 10,
      ),
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
  });
}
