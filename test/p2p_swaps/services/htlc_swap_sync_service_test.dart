import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/p2p_swaps/services/htlc_swap_auto_unlock_service.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class MockHtlcSwapRepository extends Mock implements HtlcSwapRepository {}

class MockHtlcSwapAutoUnlockService extends Mock
    implements HtlcSwapAutoUnlockService {}

class MockZenon extends Mock implements Zenon {}

class MockWsClient extends Mock implements WsClient {}

class MockLedgerApi extends Mock implements LedgerApi {}

class MockHtlcSwap extends Mock implements HtlcSwap {}

void main() {
  setUpAll(() {
    registerFallbackValue(<P2pSwapState>[]);
    registerFallbackValue(<HtlcSwap>[]);
  });

  group('HtlcSwapSyncService', () {
    late MockHtlcSwapRepository swapRepository;
    late MockHtlcSwapAutoUnlockService autoUnlockService;
    late MockZenon zenon;
    late HtlcSwapSyncService handler;

    setUp(() {
      swapRepository = MockHtlcSwapRepository();
      autoUnlockService = MockHtlcSwapAutoUnlockService();
      zenon = MockZenon();
      handler = HtlcSwapSyncService(
        swapRepository: swapRepository,
        autoUnlockService: autoUnlockService,
        zenon: zenon,
      );
    });

    test('reports an active incoming swap', () async {
      final MockHtlcSwap incomingSwap = MockHtlcSwap();
      when(
        () => incomingSwap.direction,
      ).thenReturn(P2pSwapDirection.incoming);
      when(
        () => swapRepository.getSwapsByState(any()),
      ).thenAnswer((_) async => <HtlcSwap>[incomingSwap]);

      expect(await handler.hasActiveIncomingSwaps(), isTrue);

      verify(() => swapRepository.getSwapsByState(any())).called(1);
    });

    test('ignores active outgoing swaps', () async {
      final MockHtlcSwap outgoingSwap = MockHtlcSwap();
      when(
        () => outgoingSwap.direction,
      ).thenReturn(P2pSwapDirection.outgoing);
      when(
        () => swapRepository.getSwapsByState(any()),
      ).thenAnswer((_) async => <HtlcSwap>[outgoingSwap]);

      expect(await handler.hasActiveIncomingSwaps(), isFalse);
    });

    test('does not start another run while already running', () async {
      final MockWsClient wsClient = MockWsClient();
      final Completer<List<HtlcSwap>> activeSwaps = Completer<List<HtlcSwap>>();
      when(() => zenon.wsClient).thenReturn(wsClient);
      when(wsClient.isClosed).thenReturn(true);
      when(
        () => swapRepository.getSwapsByState(any()),
      ).thenAnswer((_) => activeSwaps.future);

      handler
        ..start()
        ..start();

      verify(() => swapRepository.getSwapsByState(any())).called(1);

      final Future<void> stopFuture = handler.stop();
      activeSwaps.complete(<HtlcSwap>[]);
      await stopFuture;
    });

    testWidgets(
      'stop waits for the current run and prevents rescheduling',
      (WidgetTester tester) async {
        final MockWsClient wsClient = MockWsClient();
        final Completer<List<HtlcSwap>> activeSwaps =
            Completer<List<HtlcSwap>>();
        when(() => zenon.wsClient).thenReturn(wsClient);
        when(wsClient.isClosed).thenReturn(true);
        when(
          () => swapRepository.getSwapsByState(any()),
        ).thenAnswer((_) => activeSwaps.future);

        handler.start();
        bool stopped = false;
        final Future<void> stopFuture = handler.stop().then((_) {
          stopped = true;
        });

        await tester.pump();
        expect(stopped, isFalse);

        activeSwaps.complete(<HtlcSwap>[]);
        await stopFuture;
        expect(stopped, isTrue);

        await tester.pump(const Duration(seconds: 5));
        verify(() => swapRepository.getSwapsByState(any())).called(1);
      },
    );

    test('does not poll while the injected client is closed', () async {
      final MockWsClient wsClient = MockWsClient();
      when(() => zenon.wsClient).thenReturn(wsClient);
      when(wsClient.isClosed).thenReturn(true);
      when(
        () => swapRepository.getSwapsByState(any()),
      ).thenAnswer((_) async => <HtlcSwap>[]);

      handler.start();
      await handler.stop();

      verify(() => zenon.wsClient).called(1);
      verifyNever(() => autoUnlockService.unlockNext(any()));
    });

    test('passes eligible incoming swaps to auto-unlock', () async {
      final MockWsClient wsClient = MockWsClient();
      final MockLedgerApi ledgerApi = MockLedgerApi();
      final MockHtlcSwap incomingSwap = MockHtlcSwap();
      when(() => incomingSwap.direction).thenReturn(P2pSwapDirection.incoming);
      when(() => incomingSwap.preimage).thenReturn('preimage');
      when(() => zenon.wsClient).thenReturn(wsClient);
      when(wsClient.isClosed).thenReturn(false);
      when(() => zenon.ledger).thenReturn(ledgerApi);
      when(
        () => ledgerApi.getFrontierAccountBlock(htlcAddress),
      ).thenAnswer((_) async => null);
      when(
        () => swapRepository.getLastCheckedHtlcBlockHeight(),
      ).thenAnswer((_) async => 0);
      when(() => swapRepository.getSwapsByState(any())).thenAnswer((
        invocation,
      ) {
        final List<P2pSwapState> states =
            invocation.positionalArguments.single as List<P2pSwapState>;
        if (states.length == 3 || states.contains(P2pSwapState.reclaimable)) {
          return Future<List<HtlcSwap>>.value(<HtlcSwap>[incomingSwap]);
        }
        return Future<List<HtlcSwap>>.value(<HtlcSwap>[]);
      });
      when(
        () => autoUnlockService.unlockNext(any()),
      ).thenAnswer((_) async {});

      handler.start();
      await handler.stop();

      final Iterable<HtlcSwap> candidates =
          verify(
                () => autoUnlockService.unlockNext(captureAny()),
              ).captured.single
              as Iterable<HtlcSwap>;
      expect(candidates, <HtlcSwap>[incomingSwap]);
    });

    test('does not log secret preimages on storage failure', () async {
      const String secretPreimage = 'sync-secret-preimage-abcdef012345';
      final MockWsClient wsClient = MockWsClient();
      when(() => zenon.wsClient).thenReturn(wsClient);
      when(wsClient.isClosed).thenReturn(false);
      when(() => swapRepository.getSwapsByState(any())).thenThrow(
        SqliteException(
          extendedResultCode: 13,
          message: 'disk full',
          causingStatement: 'INSERT INTO htlc_swaps VALUES (?)',
          parametersToStatement: <Object?>[secretPreimage],
        ),
      );

      final List<LogRecord> logs = <LogRecord>[];
      final StreamSubscription<LogRecord> subscription = Logger.root.onRecord
          .listen(logs.add);
      addTearDown(subscription.cancel);

      handler.start();
      await handler.stop();

      expect(logs, isNotEmpty);
      for (final LogRecord record in logs) {
        expect(record.message, isNot(contains(secretPreimage)));
        expect(record.error?.toString() ?? '', isNot(contains(secretPreimage)));
        expect(
          record.stackTrace?.toString() ?? '',
          isNot(contains(secretPreimage)),
        );
      }
    });
  });
}
