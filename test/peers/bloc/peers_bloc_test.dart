import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/peers/peers.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class MockZenon extends Mock implements Zenon {}

class MockStatsApi extends Mock implements StatsApi {}

void main() {
  group('PeersBloc', () {
    late MockZenon mockZenon;
    late MockStatsApi mockStatsApi;
    late Peer peerA;
    late Peer peerB;
    late NetworkInfo networkInfo;

    setUp(() {
      mockZenon = MockZenon();
      mockStatsApi = MockStatsApi();
      peerA = Peer.fromJson(<String, dynamic>{
        'ip': '10.0.0.2',
        'publicKey': 'pk_z',
      });
      peerB = Peer.fromJson(<String, dynamic>{
        'ip': '10.0.0.1',
        'publicKey': 'pk_a',
      });
      networkInfo = NetworkInfo.fromJson(<String, dynamic>{
        'numPeers': 2,
        'self': <String, dynamic>{'ip': '127.0.0.1', 'publicKey': 'self'},
        'peers': <Map<String, dynamic>>[
          <String, dynamic>{'ip': peerA.ip, 'publicKey': peerA.publicKey},
          <String, dynamic>{'ip': peerB.ip, 'publicKey': peerB.publicKey},
        ],
      });

      when(() => mockZenon.stats).thenReturn(mockStatsApi);
      when(
        () => mockStatsApi.networkInfo(),
      ).thenAnswer((_) async => networkInfo);
    });

    test('initial state is PeersInitial', () {
      final PeersBloc bloc = PeersBloc(zenon: mockZenon);
      addTearDown(bloc.close);

      expect(bloc.state, const PeersInitial());
    });

    blocTest<PeersBloc, PeersState>(
      'emits [loading, populated] when PeersRequested succeeds',
      build: () => PeersBloc(zenon: mockZenon),
      act: (PeersBloc bloc) => bloc.add(const PeersRequested()),
      expect: () => <Matcher>[
        isA<PeersLoading>(),
        isA<PeersPopulated>().having(
          (PeersPopulated s) => s.peers.map((Peer p) => p.ip).toList(),
          'peer IPs',
          <String>['10.0.0.2', '10.0.0.1'],
        ),
      ],
    );

    blocTest<PeersBloc, PeersState>(
      'sorts peers by IP ascending then descending when toggled twice',
      build: () => PeersBloc(zenon: mockZenon),
      act: (PeersBloc bloc) async {
        bloc
          ..add(const PeersRequested())
          ..add(const PeersSortToggled(column: PeersSortColumn.ip))
          ..add(const PeersSortToggled(column: PeersSortColumn.ip));
      },
      expect: () => <Matcher>[
        isA<PeersLoading>(),
        isA<PeersPopulated>().having(
          (PeersPopulated s) => s.peers.map((Peer p) => p.ip).toList(),
          'initial IPs',
          <String>['10.0.0.2', '10.0.0.1'],
        ),
        isA<PeersPopulated>()
            .having(
              (PeersPopulated s) => s.peers.map((Peer p) => p.ip).toList(),
              'ascending IPs',
              <String>['10.0.0.1', '10.0.0.2'],
            )
            .having(
              (PeersPopulated s) => s.sortAscending,
              'sortAscending',
              false,
            ),
        isA<PeersPopulated>()
            .having(
              (PeersPopulated s) => s.peers.map((Peer p) => p.ip).toList(),
              'descending IPs',
              <String>['10.0.0.2', '10.0.0.1'],
            )
            .having(
              (PeersPopulated s) => s.sortAscending,
              'sortAscending',
              true,
            ),
      ],
    );

    blocTest<PeersBloc, PeersState>(
      'sorts peers by publicKey and preserves sort on refresh',
      setUp: () {
        int callCount = 0;
        final NetworkInfo refreshedInfo = NetworkInfo.fromJson(
          <String, dynamic>{
            'numPeers': 3,
            'self': <String, dynamic>{'ip': '127.0.0.1', 'publicKey': 'self'},
            'peers': <Map<String, dynamic>>[
              <String, dynamic>{'ip': peerA.ip, 'publicKey': peerA.publicKey},
              <String, dynamic>{'ip': '10.0.0.3', 'publicKey': 'pk_m'},
              <String, dynamic>{'ip': peerB.ip, 'publicKey': peerB.publicKey},
            ],
          },
        );
        when(() => mockStatsApi.networkInfo()).thenAnswer((_) async {
          callCount++;
          return callCount == 1 ? networkInfo : refreshedInfo;
        });
      },
      build: () => PeersBloc(zenon: mockZenon),
      act: (PeersBloc bloc) async {
        bloc
          ..add(const PeersRequested())
          ..add(const PeersSortToggled(column: PeersSortColumn.publicKey))
          ..add(const PeersRequested());
      },
      expect: () => <Matcher>[
        isA<PeersLoading>(),
        isA<PeersPopulated>(),
        isA<PeersPopulated>().having(
          (PeersPopulated s) => s.peers.map((Peer p) => p.publicKey).toList(),
          'sorted publicKeys',
          <String>['pk_a', 'pk_z'],
        ),
        isA<PeersPopulated>().having(
          (PeersPopulated s) => s.peers.map((Peer p) => p.publicKey).toList(),
          'preserved sort after refresh',
          <String>['pk_a', 'pk_m', 'pk_z'],
        ),
      ],
    );

    blocTest<PeersBloc, PeersState>(
      'emits failure when networkInfo throws',
      setUp: () {
        when(() => mockStatsApi.networkInfo()).thenThrow(StateError('offline'));
      },
      build: () => PeersBloc(zenon: mockZenon),
      act: (PeersBloc bloc) => bloc.add(const PeersRequested()),
      expect: () => <Matcher>[
        isA<PeersLoading>(),
        isA<PeersFailure>().having(
          (PeersFailure s) => s.exception,
          'exception',
          isA<FailureException>(),
        ),
      ],
    );

    test(
      'refreshes peers when websocket restarted stream emits true',
      () async {
        final StreamController<bool> wsController =
            StreamController<bool>.broadcast();
        addTearDown(wsController.close);

        final PeersBloc bloc = PeersBloc(
          zenon: mockZenon,
          wsRestartedStream: wsController.stream,
        );
        addTearDown(bloc.close);

        wsController.add(true);
        await expectLater(bloc.stream, emitsThrough(isA<PeersPopulated>()));
        verify(() => mockStatsApi.networkInfo()).called(1);
      },
    );

    test(
      'applies latest sort settings if user toggles sort during refresh',
      () async {
        final Completer<NetworkInfo> refreshCompleter =
            Completer<NetworkInfo>();
        int callCount = 0;
        final NetworkInfo refreshedInfo = NetworkInfo.fromJson(
          <String, dynamic>{
            'numPeers': 3,
            'self': <String, dynamic>{'ip': '127.0.0.1', 'publicKey': 'self'},
            'peers': <Map<String, dynamic>>[
              <String, dynamic>{'ip': '10.0.0.2', 'publicKey': 'pk_z'},
              <String, dynamic>{'ip': '10.0.0.3', 'publicKey': 'pk_m'},
              <String, dynamic>{'ip': '10.0.0.1', 'publicKey': 'pk_a'},
            ],
          },
        );
        when(() => mockStatsApi.networkInfo()).thenAnswer((_) {
          callCount++;
          return callCount == 1
              ? Future<NetworkInfo>.value(networkInfo)
              : refreshCompleter.future;
        });

        final PeersBloc bloc = PeersBloc(zenon: mockZenon);
        addTearDown(bloc.close);

        bloc.add(const PeersRequested());
        await expectLater(bloc.stream, emitsThrough(isA<PeersPopulated>()));

        // Start refresh while unsorted, then toggle IP sort while RPC awaits.
        bloc.add(const PeersRequested());
        await Future<void>.delayed(Duration.zero);
        bloc.add(const PeersSortToggled(column: PeersSortColumn.ip));
        await Future<void>.delayed(Duration.zero);

        refreshCompleter.complete(refreshedInfo);
        await expectLater(
          bloc.stream,
          emitsThrough(
            isA<PeersPopulated>()
                .having(
                  (PeersPopulated s) => s.sortColumn,
                  'sortColumn',
                  PeersSortColumn.ip,
                )
                .having(
                  (PeersPopulated s) => s.peers.map((Peer p) => p.ip).toList(),
                  'sorted refreshed IPs',
                  <String>['10.0.0.1', '10.0.0.2', '10.0.0.3'],
                ),
          ),
        );
      },
    );

    test(
      'preserves selected sort preference even when a concurrent refresh fails',
      () async {
        final Completer<NetworkInfo> failingRefresh = Completer<NetworkInfo>();
        final Completer<NetworkInfo> succeedingRefresh =
            Completer<NetworkInfo>();
        int callCount = 0;
        final NetworkInfo refreshedInfo = NetworkInfo.fromJson(
          <String, dynamic>{
            'numPeers': 3,
            'self': <String, dynamic>{'ip': '127.0.0.1', 'publicKey': 'self'},
            'peers': <Map<String, dynamic>>[
              <String, dynamic>{'ip': '10.0.0.2', 'publicKey': 'pk_z'},
              <String, dynamic>{'ip': '10.0.0.3', 'publicKey': 'pk_m'},
              <String, dynamic>{'ip': '10.0.0.1', 'publicKey': 'pk_a'},
            ],
          },
        );
        when(() => mockStatsApi.networkInfo()).thenAnswer((_) {
          callCount++;
          if (callCount == 1) {
            return Future<NetworkInfo>.value(networkInfo);
          }
          if (callCount == 2) {
            return failingRefresh.future;
          }
          return succeedingRefresh.future;
        });

        final PeersBloc bloc = PeersBloc(zenon: mockZenon);
        addTearDown(bloc.close);

        bloc
          ..add(const PeersRequested())
          ..add(const PeersSortToggled(column: PeersSortColumn.ip));
        await expectLater(
          bloc.stream,
          emitsThrough(
            isA<PeersPopulated>().having(
              (PeersPopulated s) => s.sortColumn,
              'sorted by ip',
              PeersSortColumn.ip,
            ),
          ),
        );

        // Trigger two overlapping refreshes; first fails, second succeeds.
        bloc
          ..add(const PeersRequested())
          ..add(const PeersRequested());
        await Future<void>.delayed(Duration.zero);

        failingRefresh.completeError(StateError('transient error'));
        await expectLater(bloc.stream, emitsThrough(isA<PeersFailure>()));

        succeedingRefresh.complete(refreshedInfo);
        await expectLater(
          bloc.stream,
          emitsThrough(
            isA<PeersPopulated>()
                .having(
                  (PeersPopulated s) => s.sortColumn,
                  'preserved sortColumn',
                  PeersSortColumn.ip,
                )
                .having(
                  (PeersPopulated s) => s.peers.map((Peer p) => p.ip).toList(),
                  'still sorted by IP',
                  <String>['10.0.0.1', '10.0.0.2', '10.0.0.3'],
                ),
          ),
        );
      },
    );

    test(
      'isLoadingListenable tracks populated and overlapping refreshes',
      () async {
        final Completer<NetworkInfo> refreshCompleter =
            Completer<NetworkInfo>();
        final Completer<void> refreshStarted = Completer<void>();
        int callCount = 0;

        when(() => mockStatsApi.networkInfo()).thenAnswer((_) {
          callCount++;
          if (callCount == 1) {
            return Future<NetworkInfo>.value(networkInfo);
          }
          if (!refreshStarted.isCompleted) {
            refreshStarted.complete();
          }
          return refreshCompleter.future;
        });

        final PeersBloc bloc = PeersBloc(zenon: mockZenon);
        addTearDown(bloc.close);

        bloc.add(const PeersRequested());
        await expectLater(bloc.stream, emitsThrough(isA<PeersPopulated>()));
        expect(bloc.isLoadingListenable.value, isFalse);

        // Refresh from PeersPopulated keeps state populated while exposing
        // loading via isLoadingListenable.
        final Completer<void> loadingCleared = Completer<void>();
        void onLoadingChanged() {
          if (!bloc.isLoadingListenable.value && !loadingCleared.isCompleted) {
            loadingCleared.complete();
          }
        }

        bloc.add(const PeersRequested());
        await refreshStarted.future.timeout(const Duration(seconds: 5));
        expect(bloc.state, isA<PeersPopulated>());
        expect(bloc.isLoadingListenable.value, isTrue);

        bloc.isLoadingListenable.addListener(onLoadingChanged);
        addTearDown(() {
          if (!bloc.isClosed) {
            bloc.isLoadingListenable.removeListener(onLoadingChanged);
          }
        });
        refreshCompleter.complete(networkInfo);
        await loadingCleared.future.timeout(const Duration(seconds: 5));

        expect(bloc.isLoadingListenable.value, isFalse);
      },
    );
  });
}
