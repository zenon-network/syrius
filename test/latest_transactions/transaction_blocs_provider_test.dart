import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/zts_utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/main_app_container.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

import '../helpers/hydrated_bloc.dart';

class _MockZenon extends Mock implements Zenon {}

class _MockWsClient extends Mock implements WsClient {}

class _MockLedger extends Mock implements LedgerApi {}

class _FakeAddress extends Fake implements Address {}

AccountBlock _buildAccountBlock(int height) {
  final String hashHex = height.toRadixString(16).padLeft(64, '0');
  return AccountBlock.fromJson(<String, dynamic>{
    'descendantBlocks': const <AccountBlock>[],
    'basePlasma': 1000,
    'usedPlasma': 500,
    'changesHash': emptyHash.toString(),
    'confirmationDetail': <String, dynamic>{
      'numConfirmations': 12,
      'momentumHeight': 1000 + height,
      'momentumHash': emptyHash.toString(),
      'momentumTimestamp': 1700000000 + height,
    },
    'version': 1,
    'chainIdentifier': 1,
    'blockType': 2,
    'hash': hashHex,
    'previousHash': emptyHash.toString(),
    'height': height,
    'momentumAcknowledged': <String, dynamic>{
      'hash': emptyHash.toString(),
      'height': 999 + height,
    },
    'address': emptyAddress.toString(),
    'toAddress': emptyAddress.toString(),
    'amount': '${height}00000000',
    'tokenStandard': znnTokenStandard,
    'fromBlockHash': emptyHash.toString(),
    'data': null,
    'fusedPlasma': 0,
    'difficulty': 0,
    'nonce': '1',
    'publicKey': null,
    'signature': null,
    'token': kZnnCoin.toJson(),
    'pairedAccountBlock': null,
  });
}

void main() {
  initHydratedStorage();

  setUpAll(() {
    registerFallbackValue(_FakeAddress());
  });

  group('LatestTransactionsBloc and PendingTransactionsBloc singleton provider '
      'lifecycle', () {
    late _MockZenon mockZenon;
    late _MockWsClient mockWsClient;
    late _MockLedger mockLedger;
    late LatestTransactionsBloc latestTransactionsBloc;
    late PendingTransactionsBloc pendingTransactionsBloc;
    late MultipleBalanceBloc multipleBalanceBloc;
    late NotificationsBloc notificationsBloc;

    late LatestTransactionsBloc? previousLatestTransactionsBloc;
    late PendingTransactionsBloc? previousPendingTransactionsBloc;
    late MultipleBalanceBloc? previousMultipleBalanceBloc;
    late NotificationsBloc? previousNotificationsBloc;
    late Zenon? previousZenon;

    const String testAddressStr = 'z1qqjnwjjpnue8xmmpanz6csze6tcmtzzdtfsww7';
    final Address testAddress = Address.parse(testAddressStr);
    final AccountBlock latestBlock = _buildAccountBlock(1);
    final AccountBlock pendingBlock = _buildAccountBlock(2);

    setUp(() async {
      mockZenon = _MockZenon();
      mockWsClient = _MockWsClient();
      mockLedger = _MockLedger();

      when(() => mockZenon.wsClient).thenReturn(mockWsClient);
      when(() => mockZenon.ledger).thenReturn(mockLedger);
      when(
        () => mockWsClient.restartedStream,
      ).thenAnswer((_) => const Stream<bool>.empty());
      when(
        () => mockLedger.getAccountBlocksByPage(
          any(),
          pageIndex: any(named: 'pageIndex'),
          pageSize: any(named: 'pageSize'),
        ),
      ).thenAnswer(
        (_) async => AccountBlockList(
          count: 1,
          list: <AccountBlock>[latestBlock],
          more: false,
        ),
      );
      when(
        () => mockLedger.getUnreceivedBlocksByAddress(
          any(),
          pageIndex: any(named: 'pageIndex'),
          pageSize: any(named: 'pageSize'),
        ),
      ).thenAnswer(
        (_) async => AccountBlockList(
          count: 1,
          list: <AccountBlock>[pendingBlock],
          more: false,
        ),
      );

      previousZenon = zenon;
      zenon = mockZenon;

      previousLatestTransactionsBloc = sl.isRegistered<LatestTransactionsBloc>()
          ? sl<LatestTransactionsBloc>()
          : null;
      if (previousLatestTransactionsBloc != null) {
        await sl.unregister<LatestTransactionsBloc>();
      }
      latestTransactionsBloc = LatestTransactionsBloc(zenon: mockZenon);
      sl.registerSingleton<LatestTransactionsBloc>(latestTransactionsBloc);

      previousPendingTransactionsBloc =
          sl.isRegistered<PendingTransactionsBloc>()
          ? sl<PendingTransactionsBloc>()
          : null;
      if (previousPendingTransactionsBloc != null) {
        await sl.unregister<PendingTransactionsBloc>();
      }
      pendingTransactionsBloc = PendingTransactionsBloc(zenon: mockZenon);
      sl.registerSingleton<PendingTransactionsBloc>(pendingTransactionsBloc);

      previousMultipleBalanceBloc = sl.isRegistered<MultipleBalanceBloc>()
          ? sl<MultipleBalanceBloc>()
          : null;
      if (previousMultipleBalanceBloc != null) {
        await sl.unregister<MultipleBalanceBloc>();
      }
      multipleBalanceBloc = MultipleBalanceBloc(zenon: mockZenon);
      sl.registerSingleton<MultipleBalanceBloc>(multipleBalanceBloc);

      previousNotificationsBloc = sl.isRegistered<NotificationsBloc>()
          ? sl<NotificationsBloc>()
          : null;
      if (previousNotificationsBloc != null) {
        await sl.unregister<NotificationsBloc>();
      }
      notificationsBloc = NotificationsBloc();
      sl.registerSingleton<NotificationsBloc>(notificationsBloc);
    });

    tearDown(() async {
      if (sl.isRegistered<LatestTransactionsBloc>()) {
        await sl.unregister<LatestTransactionsBloc>();
      }
      if (previousLatestTransactionsBloc != null) {
        sl.registerSingleton<LatestTransactionsBloc>(
          previousLatestTransactionsBloc!,
        );
      }
      if (sl.isRegistered<PendingTransactionsBloc>()) {
        await sl.unregister<PendingTransactionsBloc>();
      }
      if (previousPendingTransactionsBloc != null) {
        sl.registerSingleton<PendingTransactionsBloc>(
          previousPendingTransactionsBloc!,
        );
      }
      if (sl.isRegistered<MultipleBalanceBloc>()) {
        await sl.unregister<MultipleBalanceBloc>();
      }
      if (previousMultipleBalanceBloc != null) {
        sl.registerSingleton<MultipleBalanceBloc>(previousMultipleBalanceBloc!);
      }
      if (sl.isRegistered<NotificationsBloc>()) {
        await sl.unregister<NotificationsBloc>();
      }
      if (previousNotificationsBloc != null) {
        sl.registerSingleton<NotificationsBloc>(previousNotificationsBloc!);
      }
      zenon = previousZenon;
      await latestTransactionsBloc.close();
      await pendingTransactionsBloc.close();
      await multipleBalanceBloc.close();
      await notificationsBloc.close();
    });

    testWidgets(
      'disposing and remounting MyApp provider subtree does not close '
      'singleton LatestTransactionsBloc or PendingTransactionsBloc',
      (WidgetTester tester) async {
        LatestTransactionsBloc? firstLatest;
        PendingTransactionsBloc? firstPending;
        LatestTransactionsBloc? secondLatest;
        PendingTransactionsBloc? secondPending;

        await tester.pumpWidget(
          MultiBlocProvider(
            providers: buildMyAppBlocProviders(),
            child: Builder(
              builder: (BuildContext context) {
                firstLatest = context.read<LatestTransactionsBloc>();
                firstPending = context.read<PendingTransactionsBloc>();
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        expect(firstLatest, same(latestTransactionsBloc));
        expect(firstPending, same(pendingTransactionsBloc));
        expect(latestTransactionsBloc.isClosed, isFalse);
        expect(pendingTransactionsBloc.isClosed, isFalse);

        // Dispose the provider subtree.
        await tester.pumpWidget(const SizedBox.shrink());

        expect(latestTransactionsBloc.isClosed, isFalse);
        expect(pendingTransactionsBloc.isClosed, isFalse);

        // Remount and verify both singletons remain open and process events.
        await tester.pumpWidget(
          MultiBlocProvider(
            providers: buildMyAppBlocProviders(),
            child: Builder(
              builder: (BuildContext context) {
                secondLatest = context.read<LatestTransactionsBloc>();
                secondPending = context.read<PendingTransactionsBloc>();
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        expect(secondLatest, same(latestTransactionsBloc));
        expect(secondPending, same(pendingTransactionsBloc));

        final (InfiniteListState<AccountBlock>, InfiniteListState<AccountBlock>)
        results = (await tester.runAsync(() async {
          final Future<InfiniteListState<AccountBlock>> latestFetched =
              latestTransactionsBloc.stream
                  .firstWhere(
                    (InfiniteListState<AccountBlock> s) =>
                        s.status == InfiniteListStatus.success,
                  )
                  .timeout(const Duration(seconds: 5));
          final Future<InfiniteListState<AccountBlock>> pendingFetched =
              pendingTransactionsBloc.stream
                  .firstWhere(
                    (InfiniteListState<AccountBlock> s) =>
                        s.status == InfiniteListStatus.success,
                  )
                  .timeout(const Duration(seconds: 5));

          latestTransactionsBloc.add(
            InfiniteListRequested(address: testAddress),
          );
          pendingTransactionsBloc.add(
            InfiniteListRequested(address: testAddress),
          );

          return (await latestFetched, await pendingFetched);
        }))!;

        expect(results.$1.data, hasLength(1));
        expect(results.$1.data!.single.height, 1);
        expect(results.$2.data, hasLength(1));
        expect(results.$2.data!.single.height, 2);
      },
    );

    testWidgets(
      'disposing and remounting MainAppContainer provider subtree does not '
      'close singleton LatestTransactionsBloc or PendingTransactionsBloc',
      (WidgetTester tester) async {
        LatestTransactionsBloc? firstLatest;
        PendingTransactionsBloc? firstPending;
        LatestTransactionsBloc? secondLatest;
        PendingTransactionsBloc? secondPending;

        await tester.pumpWidget(
          MultiBlocProvider(
            providers: buildMainAppContainerBlocProviders(),
            child: Builder(
              builder: (BuildContext context) {
                firstLatest = context.read<LatestTransactionsBloc>();
                firstPending = context.read<PendingTransactionsBloc>();
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        expect(firstLatest, same(latestTransactionsBloc));
        expect(firstPending, same(pendingTransactionsBloc));
        expect(latestTransactionsBloc.isClosed, isFalse);
        expect(pendingTransactionsBloc.isClosed, isFalse);

        // Simulate MainAppContainer disposal (e.g. wallet reset / route swap).
        await tester.pumpWidget(const SizedBox.shrink());

        expect(latestTransactionsBloc.isClosed, isFalse);
        expect(pendingTransactionsBloc.isClosed, isFalse);

        // Remount MainAppContainer providers and verify both singletons work.
        await tester.pumpWidget(
          MultiBlocProvider(
            providers: buildMainAppContainerBlocProviders(),
            child: Builder(
              builder: (BuildContext context) {
                secondLatest = context.read<LatestTransactionsBloc>();
                secondPending = context.read<PendingTransactionsBloc>();
                return const SizedBox.shrink();
              },
            ),
          ),
        );

        expect(secondLatest, same(latestTransactionsBloc));
        expect(secondPending, same(pendingTransactionsBloc));
        expect(latestTransactionsBloc.isClosed, isFalse);
        expect(pendingTransactionsBloc.isClosed, isFalse);

        final (InfiniteListState<AccountBlock>, InfiniteListState<AccountBlock>)
        results = (await tester.runAsync(() async {
          final Future<InfiniteListState<AccountBlock>> latestFetched =
              latestTransactionsBloc.stream
                  .firstWhere(
                    (InfiniteListState<AccountBlock> s) =>
                        s.status == InfiniteListStatus.success,
                  )
                  .timeout(const Duration(seconds: 5));
          final Future<InfiniteListState<AccountBlock>> pendingFetched =
              pendingTransactionsBloc.stream
                  .firstWhere(
                    (InfiniteListState<AccountBlock> s) =>
                        s.status == InfiniteListStatus.success,
                  )
                  .timeout(const Duration(seconds: 5));

          requestInitialTransactionsForAddress(testAddressStr);

          return (await latestFetched, await pendingFetched);
        }))!;

        expect(results.$1.data, hasLength(1));
        expect(results.$1.data!.single.height, 1);
        expect(results.$2.data, hasLength(1));
        expect(results.$2.data!.single.height, 2);
      },
    );

    test('requestInitialTransactionsForAddress safely no-ops when address is '
        'null or empty', () async {
      requestInitialTransactionsForAddress(null);
      requestInitialTransactionsForAddress('');
      await Future<void>.delayed(Duration.zero);

      verifyNever(
        () => mockLedger.getAccountBlocksByPage(
          any(),
          pageIndex: any(named: 'pageIndex'),
          pageSize: any(named: 'pageSize'),
        ),
      );
      verifyNever(
        () => mockLedger.getUnreceivedBlocksByAddress(
          any(),
          pageIndex: any(named: 'pageIndex'),
          pageSize: any(named: 'pageSize'),
        ),
      );
    });
  });
}
