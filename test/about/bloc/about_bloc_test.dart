import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/about/about.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class _MockZenon extends Mock implements Zenon {}

class _MockLedgerApi extends Mock implements LedgerApi {}

class _MockStatsApi extends Mock implements StatsApi {}

class _MockMomentum extends Mock implements Momentum {}

class _MockProcessInfo extends Mock implements ProcessInfo {}

class _MockOsInfo extends Mock implements OsInfo {}

void main() {
  group('AboutBloc', () {
    late _MockZenon mockZenon;
    late _MockLedgerApi mockLedgerApi;
    late _MockStatsApi mockStatsApi;
    late _MockMomentum mockMomentum;
    late _MockProcessInfo mockProcessInfo;
    late _MockOsInfo mockOsInfo;

    setUp(() {
      mockZenon = _MockZenon();
      mockLedgerApi = _MockLedgerApi();
      mockStatsApi = _MockStatsApi();
      mockMomentum = _MockMomentum();
      mockProcessInfo = _MockProcessInfo();
      mockOsInfo = _MockOsInfo();

      when(() => mockZenon.ledger).thenReturn(mockLedgerApi);
      when(() => mockZenon.stats).thenReturn(mockStatsApi);
      when(
        () => mockLedgerApi.getFrontierMomentum(),
      ).thenAnswer((_) async => mockMomentum);
      when(
        () => mockStatsApi.processInfo(),
      ).thenAnswer((_) async => mockProcessInfo);
      when(() => mockStatsApi.osInfo()).thenAnswer((_) async => mockOsInfo);
    });

    test('initial state is AboutInitial', () {
      final AboutBloc bloc = AboutBloc(zenon: mockZenon);
      addTearDown(bloc.close);
      expect(bloc.state, equals(const AboutInitial()));
    });

    blocTest<AboutBloc, AboutState>(
      'emits [AboutLoading, AboutPopulated] without calling networkInfo',
      build: () => AboutBloc(zenon: mockZenon),
      act: (AboutBloc bloc) => bloc.add(const AboutRequested()),
      expect: () => <dynamic>[
        const AboutLoading(),
        isA<AboutPopulated>()
            .having(
              (AboutPopulated s) => s.nodeInfo.frontierMomentum,
              'frontierMomentum',
              same(mockMomentum),
            )
            .having(
              (AboutPopulated s) => s.nodeInfo.processInfo,
              'processInfo',
              same(mockProcessInfo),
            )
            .having(
              (AboutPopulated s) => s.nodeInfo.osInfo,
              'osInfo',
              same(mockOsInfo),
            )
            .having((AboutPopulated s) => s.nodeError, 'nodeError', isNull),
      ],
      verify: (_) {
        verify(() => mockLedgerApi.getFrontierMomentum()).called(1);
        verify(() => mockStatsApi.processInfo()).called(1);
        verify(() => mockStatsApi.osInfo()).called(1);
        verifyNever(() => mockStatsApi.networkInfo());
      },
    );

    test(
      'fetches frontierMomentum, processInfo, and osInfo in parallel',
      () async {
        final Completer<Momentum> momentumCompleter = Completer<Momentum>();
        final Completer<ProcessInfo> processCompleter =
            Completer<ProcessInfo>();
        final Completer<OsInfo> osCompleter = Completer<OsInfo>();

        when(
          () => mockLedgerApi.getFrontierMomentum(),
        ).thenAnswer((_) => momentumCompleter.future);
        when(
          () => mockStatsApi.processInfo(),
        ).thenAnswer((_) => processCompleter.future);
        when(
          () => mockStatsApi.osInfo(),
        ).thenAnswer((_) => osCompleter.future);

        final AboutBloc bloc = AboutBloc(zenon: mockZenon);
        addTearDown(bloc.close);

        bloc.add(const AboutRequested());
        await Future<void>.delayed(Duration.zero);

        // All three RPCs must have started concurrently before any completes.
        verify(() => mockLedgerApi.getFrontierMomentum()).called(1);
        verify(() => mockStatsApi.processInfo()).called(1);
        verify(() => mockStatsApi.osInfo()).called(1);

        momentumCompleter.complete(mockMomentum);
        processCompleter.complete(mockProcessInfo);
        osCompleter.complete(mockOsInfo);
        await Future<void>.delayed(const Duration(milliseconds: 20));

        expect(
          bloc.state,
          equals(
            AboutPopulated(
              nodeInfo: AboutNodeInfo(
                frontierMomentum: mockMomentum,
                processInfo: mockProcessInfo,
                osInfo: mockOsInfo,
              ),
            ),
          ),
        );
      },
    );

    blocTest<AboutBloc, AboutState>(
      'emits partial AboutPopulated when one RPC throws SyriusException',
      setUp: () {
        when(
          () => mockStatsApi.processInfo(),
        ).thenThrow(SyriusException('Custom RPC error'));
      },
      build: () => AboutBloc(zenon: mockZenon),
      act: (AboutBloc bloc) => bloc.add(const AboutRequested()),
      expect: () => <dynamic>[
        const AboutLoading(),
        isA<AboutPopulated>()
            .having(
              (AboutPopulated s) => s.nodeInfo.frontierMomentum,
              'frontierMomentum',
              same(mockMomentum),
            )
            .having(
              (AboutPopulated s) => s.nodeInfo.processInfo,
              'processInfo',
              isNull,
            )
            .having(
              (AboutPopulated s) => s.nodeInfo.osInfo,
              'osInfo',
              same(mockOsInfo),
            )
            .having(
              (AboutPopulated s) => s.nodeError?.message,
              'nodeError.message',
              equals('Custom RPC error'),
            ),
      ],
      errors: () => <dynamic>[isA<SyriusException>()],
    );

    blocTest<AboutBloc, AboutState>(
      'emits AboutFailure preserving SyriusException when all node RPCs fail',
      setUp: () {
        when(
          () => mockLedgerApi.getFrontierMomentum(),
        ).thenThrow(SyriusException('Node offline'));
        when(
          () => mockStatsApi.processInfo(),
        ).thenThrow(Exception('process error'));
        when(() => mockStatsApi.osInfo()).thenThrow(Exception('os error'));
      },
      build: () => AboutBloc(zenon: mockZenon),
      act: (AboutBloc bloc) => bloc.add(const AboutRequested()),
      expect: () => <dynamic>[
        const AboutLoading(),
        isA<AboutFailure>().having(
          (AboutFailure s) => s.exception.message,
          'exception.message',
          equals('Node offline'),
        ),
      ],
      errors: () => <dynamic>[
        isA<SyriusException>(),
        isA<Exception>(),
        isA<Exception>(),
      ],
    );

    blocTest<AboutBloc, AboutState>(
      'maps unexpected exceptions to FailureException when all node RPCs fail',
      setUp: () {
        when(
          () => mockLedgerApi.getFrontierMomentum(),
        ).thenThrow(Exception('rpc timeout'));
        when(
          () => mockStatsApi.processInfo(),
        ).thenThrow(Exception('rpc timeout'));
        when(() => mockStatsApi.osInfo()).thenThrow(Exception('rpc timeout'));
      },
      build: () => AboutBloc(zenon: mockZenon),
      act: (AboutBloc bloc) => bloc.add(const AboutRequested()),
      expect: () => <dynamic>[
        const AboutLoading(),
        isA<AboutFailure>().having(
          (AboutFailure s) => s.exception,
          'exception',
          isA<FailureException>(),
        ),
      ],
      errors: () => <dynamic>[
        isA<Exception>(),
        isA<Exception>(),
        isA<Exception>(),
      ],
    );

    test('drops overlapping AboutRequested events while in flight', () async {
      final Completer<Momentum> completer = Completer<Momentum>();
      when(
        () => mockLedgerApi.getFrontierMomentum(),
      ).thenAnswer((_) => completer.future);

      final AboutBloc bloc = AboutBloc(zenon: mockZenon);
      addTearDown(bloc.close);

      final List<AboutState> emitted = <AboutState>[];
      final StreamSubscription<AboutState> sub = bloc.stream.listen(
        emitted.add,
      );
      addTearDown(sub.cancel);

      bloc
        ..add(const AboutRequested())
        ..add(const AboutRequested());
      await Future<void>.delayed(Duration.zero);

      completer.complete(mockMomentum);
      await Future<void>.delayed(const Duration(milliseconds: 20));

      expect(emitted.length, 2);
      expect(emitted.first, equals(const AboutLoading()));
      expect(emitted.last, isA<AboutPopulated>());
      verify(() => mockLedgerApi.getFrontierMomentum()).called(1);
    });
  });
}
