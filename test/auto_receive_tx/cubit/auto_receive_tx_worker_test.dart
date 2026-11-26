import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:json_rpc_2/json_rpc_2.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/l10n/app_localizations.dart';
import 'package:zenon_syrius_wallet_flutter/l10n/app_localizations_en.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/exceptions/exceptions.dart';
import 'package:zenon_syrius_wallet_flutter/utils/account_block_utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class _CustomAutoReceiveL10n extends AppLocalizationsEn {
  _CustomAutoReceiveL10n() : super('en');

  @override
  String get receiveTransactionFailed => '[L10N] Receive failed';

  @override
  String failedToReceiveTransaction(String error) =>
      '[L10N] Failed details: $error';

  @override
  String transactionReceivedOnAddress(String address) =>
      '[L10N] Received on $address';

  @override
  String transactionHashWithValue(String hash) => '[L10N] Hash: $hash';

  @override
  String get walletNotUnlocked => '[L10N] Wallet locked';
}

class _MockZenon extends Mock implements Zenon {}

class _MockStatsApi extends Mock implements StatsApi {}

class _MockLedgerApi extends Mock implements LedgerApi {}

class _MockAccountBlockUtils extends Mock implements AccountBlockUtils {}

class _MockNotificationsBloc extends Mock implements NotificationsBloc {}

class _FakeHash extends Fake implements Hash {}

class _FakeAccountBlockTemplate extends Fake implements AccountBlockTemplate {}

class _FakeAddress extends Fake implements Address {}

final Address _testAddress = Address.parse(
  'z1qqjnwjjpnue8xmmpanz6csze6tcmtzzdtfsww7',
);

AccountBlock _buildAccountBlock(String toAddressString) {
  return AccountBlock.fromJson(<String, dynamic>{
    'version': 1,
    'chainIdentifier': 1,
    'blockType': 2,
    'hash': emptyHash.toString(),
    'previousHash': emptyHash.toString(),
    'height': 1,
    'momentumAcknowledged': <String, dynamic>{
      'hash': emptyHash.toString(),
      'height': 1,
    },
    'address': _testAddress.toString(),
    'toAddress': toAddressString,
    'amount': '0',
    'tokenStandard': znnZts.toString(),
    'fromBlockHash': emptyHash.toString(),
    'descendantBlocks': const <dynamic>[],
    'data': '',
    'fusedPlasma': 0,
    'difficulty': 0,
    'nonce': '',
    'basePlasma': 0,
    'usedPlasma': 0,
    'changesHash': emptyHash.toString(),
    'publicKey': '',
    'signature': '',
    'pairedAccountBlock': null,
    'confirmationDetail': null,
  });
}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeHash());
    registerFallbackValue(_FakeAccountBlockTemplate());
    registerFallbackValue(_FakeAddress());
  });

  group('AutoReceiveTxWorker', () {
    late _MockZenon mockZenon;
    late _MockStatsApi mockStatsApi;
    late _MockLedgerApi mockLedgerApi;
    late _MockAccountBlockUtils mockAccountBlockUtils;
    late bool autoReceiveEnabled;
    late bool htlcUnlocking;
    late int refreshPendingCalls;
    late int txReceivedCalls;

    final Hash hash1 = Hash.parse(
      '1111111111111111111111111111111111111111111111111111111111111111',
    );
    final Hash hash2 = Hash.parse(
      '2222222222222222222222222222222222222222222222222222222222222222',
    );
    final AccountBlock testBlock = _buildAccountBlock(_testAddress.toString());
    final AccountBlockTemplate testTemplate = AccountBlockTemplate.receive(
      hash1,
    );

    AutoReceiveTxWorker buildWorker({
      void Function(WalletNotification notification)? onNotification,
      AppLocalizations Function()? l10nProvider,
    }) {
      return AutoReceiveTxWorker(
        zenonProvider: () => mockZenon,
        accountBlockUtilsProvider: () => mockAccountBlockUtils,
        isAutoReceiveEnabled: () => autoReceiveEnabled,
        isHtlcAutoUnlocking: () => htlcUnlocking,
        onRefreshPendingTransactions: () => refreshPendingCalls += 1,
        onTransactionReceived: () => txReceivedCalls += 1,
        addressLabelResolver: (String address) => 'Address 1',
        onNotification: onNotification,
        l10nProvider: l10nProvider,
      );
    }

    setUp(() {
      mockZenon = _MockZenon();
      mockStatsApi = _MockStatsApi();
      mockLedgerApi = _MockLedgerApi();
      mockAccountBlockUtils = _MockAccountBlockUtils();
      autoReceiveEnabled = true;
      htlcUnlocking = false;
      refreshPendingCalls = 0;
      txReceivedCalls = 0;

      when(() => mockZenon.stats).thenReturn(mockStatsApi);
      when(() => mockZenon.ledger).thenReturn(mockLedgerApi);
      when(() => mockStatsApi.syncInfo()).thenAnswer(
        (_) async => SyncInfo.fromJson(<String, dynamic>{
          'state': SyncState.syncDone.index,
          'currentHeight': 100,
          'targetHeight': 100,
        }),
      );
      when(
        () => mockLedgerApi.getAccountBlockByHash(any()),
      ).thenAnswer((_) async => testBlock);
      when(
        () => mockAccountBlockUtils.createAccountBlock(
          any(),
          any(),
          address: any(named: 'address'),
          waitForRequiredPlasma: any(named: 'waitForRequiredPlasma'),
        ),
      ).thenAnswer((_) async => testTemplate);
    });

    test('initial state is idle with empty pool', () {
      final AutoReceiveTxWorker worker = buildWorker();
      addTearDown(worker.close);

      expect(worker.state, const AutoReceiveTxState());
      expect(worker.pool, isEmpty);
      expect(worker.running, isFalse);
    });

    test(
      'addHash enqueues unique hashes when synced and ignores duplicates',
      () async {
        final AutoReceiveTxWorker worker = buildWorker();
        addTearDown(worker.close);

        await worker.addHash(hash1);
        await worker.addHash(hash1);

        expect(worker.pool, <Hash>[hash1]);
        expect(refreshPendingCalls, 1);
        expect(worker.state.pendingCount, 1);
      },
    );

    test('addHash does not enqueue when node is not synced', () async {
      when(() => mockStatsApi.syncInfo()).thenAnswer(
        (_) async => SyncInfo.fromJson(<String, dynamic>{
          'state': SyncState.syncing.index,
          'currentHeight': 10,
          'targetHeight': 1000,
        }),
      );

      final AutoReceiveTxWorker worker = buildWorker();
      addTearDown(worker.close);

      await worker.addHash(hash1);

      expect(worker.pool, isEmpty);
      expect(refreshPendingCalls, 0);
    });

    test('clearPool removes queued hashes and updates pendingCount', () async {
      final AutoReceiveTxWorker worker = buildWorker();
      addTearDown(worker.close);

      await worker.addHash(hash1);
      expect(worker.pool, hasLength(1));

      worker.clearPool();
      expect(worker.pool, isEmpty);
      expect(worker.state.pendingCount, 0);
    });

    test(
      'pool returns an unmodifiable view that cannot be mutated directly',
      () async {
        final AutoReceiveTxWorker worker = buildWorker();
        addTearDown(worker.close);

        await worker.addHash(hash1);

        expect(() => worker.pool.add(hash2), throwsUnsupportedError);
        expect(() => worker.pool.clear(), throwsUnsupportedError);
        expect(() => worker.pool.remove(hash1), throwsUnsupportedError);
        expect(worker.pool, <Hash>[hash1]);
        expect(worker.state.pendingCount, 1);
      },
    );

    test('autoReceive clears pool when disabled', () async {
      final AutoReceiveTxWorker worker = buildWorker();
      addTearDown(worker.close);

      await worker.addHash(hash1);
      autoReceiveEnabled = false;

      await worker.autoReceive();

      expect(worker.pool, isEmpty);
      verifyNever(() => mockLedgerApi.getAccountBlockByHash(any()));
    });

    test(
      'autoReceive defers without clearing pool during HTLC auto-unlock',
      () async {
        final AutoReceiveTxWorker worker = buildWorker();
        addTearDown(worker.close);

        await worker.addHash(hash1);
        htlcUnlocking = true;

        await worker.autoReceive();

        expect(worker.pool, <Hash>[hash1]);
        verifyNever(() => mockLedgerApi.getAccountBlockByHash(any()));
      },
    );

    test(
      'autoReceive drains multiple hashes sequentially and emits notifications',
      () async {
        final AutoReceiveTxWorker worker = buildWorker();
        addTearDown(worker.close);

        final List<WalletNotification> notifications = <WalletNotification>[];
        final StreamSubscription<AutoReceiveTxState> sub = worker.stream.listen(
          (AutoReceiveTxState state) {
            if (state.lastNotification != null) {
              notifications.add(state.lastNotification!);
            }
          },
        );
        addTearDown(sub.cancel);

        await worker.addHash(hash1);
        await worker.addHash(hash2);

        await worker.autoReceive();
        await Future<void>.delayed(Duration.zero);

        expect(worker.pool, isEmpty);
        expect(worker.running, isFalse);
        expect(txReceivedCalls, 2);
        expect(notifications, hasLength(2));
        expect(
          notifications.every(
            (WalletNotification n) =>
                n.type == NotificationType.paymentReceived,
          ),
          isTrue,
        );
        expect(notifications.first.title, 'Transaction received on Address 1');
      },
    );

    test(
      'autoReceive removes already-received head hash and drains next hash',
      () async {
        int attempts = 0;
        when(
          () => mockAccountBlockUtils.createAccountBlock(
            any(),
            any(),
            address: any(named: 'address'),
            waitForRequiredPlasma: any(named: 'waitForRequiredPlasma'),
          ),
        ).thenAnswer((_) async {
          attempts += 1;
          if (attempts == 1) {
            throw RpcException(
              -32000,
              'account-block from-block already received',
            );
          }
          return testTemplate;
        });

        final AutoReceiveTxWorker worker = buildWorker();
        addTearDown(worker.close);

        final List<WalletNotification> notifications = <WalletNotification>[];
        final StreamSubscription<AutoReceiveTxState> sub = worker.stream.listen(
          (AutoReceiveTxState state) {
            if (state.lastNotification != null) {
              notifications.add(state.lastNotification!);
            }
          },
        );
        addTearDown(sub.cancel);

        await worker.addHash(hash1);
        await worker.addHash(hash2);

        await worker.autoReceive();
        await Future<void>.delayed(Duration.zero);

        expect(worker.pool, isEmpty);
        expect(txReceivedCalls, 1);
        expect(notifications, hasLength(2));
        expect(notifications[0].type, NotificationType.error);
        expect(notifications[1].type, NotificationType.paymentReceived);
      },
    );

    test('autoReceive stops draining on non-duplicate RPC error', () async {
      when(
        () => mockAccountBlockUtils.createAccountBlock(
          any(),
          any(),
          address: any(named: 'address'),
          waitForRequiredPlasma: any(named: 'waitForRequiredPlasma'),
        ),
      ).thenThrow(RpcException(-32000, 'insufficient plasma'));

      final AutoReceiveTxWorker worker = buildWorker();
      addTearDown(worker.close);

      await worker.addHash(hash1);
      await worker.addHash(hash2);

      await worker.autoReceive();

      expect(worker.pool, <Hash>[hash1, hash2]);
      expect(worker.running, isFalse);
      expect(txReceivedCalls, 0);
    });

    test(
      'autoReceiveTransactionHash receives block and guards re-entrancy',
      () async {
        final Completer<AccountBlockTemplate> completer =
            Completer<AccountBlockTemplate>();
        when(
          () => mockAccountBlockUtils.createAccountBlock(
            any(),
            any(),
            address: any(named: 'address'),
            waitForRequiredPlasma: any(named: 'waitForRequiredPlasma'),
          ),
        ).thenAnswer((_) => completer.future);

        final AutoReceiveTxWorker worker = buildWorker();
        addTearDown(worker.close);

        final Future<AccountBlockTemplate?> first = worker
            .autoReceiveTransactionHash(hash1);
        await Future<void>.delayed(Duration.zero);

        final AccountBlockTemplate? concurrent = await worker
            .autoReceiveTransactionHash(hash2);
        expect(concurrent, isNull);

        completer.complete(testTemplate);
        final AccountBlockTemplate? result = await first;

        expect(result, testTemplate);
        expect(worker.running, isFalse);
        expect(txReceivedCalls, 1);
      },
    );

    test(
      'autoReceiveTransactionHash returns null and notifies on RpcException',
      () async {
        when(
          () => mockAccountBlockUtils.createAccountBlock(
            any(),
            any(),
            address: any(named: 'address'),
            waitForRequiredPlasma: any(named: 'waitForRequiredPlasma'),
          ),
        ).thenThrow(RpcException(-32000, 'rpc failed'));

        final AutoReceiveTxWorker worker = buildWorker();
        addTearDown(worker.close);

        final List<WalletNotification> notifications = <WalletNotification>[];
        final StreamSubscription<AutoReceiveTxState> sub = worker.stream.listen(
          (AutoReceiveTxState state) {
            if (state.lastNotification != null) {
              notifications.add(state.lastNotification!);
            }
          },
        );
        addTearDown(sub.cancel);

        final AccountBlockTemplate? result = await worker
            .autoReceiveTransactionHash(hash1);
        await Future<void>.delayed(Duration.zero);

        expect(result, isNull);
        expect(worker.running, isFalse);
        expect(notifications, hasLength(1));
        expect(notifications.single.type, NotificationType.error);
      },
    );

    test(
      'autoReceive forwards notifications to NotificationsBloc even with no '
      'stream subscribers (e.g. during onboarding before MainAppContainer)',
      () async {
        final _MockNotificationsBloc mockNotificationsBloc =
            _MockNotificationsBloc();
        final List<WalletNotification?> forwarded = <WalletNotification?>[];
        when(() => mockNotificationsBloc.addNotification(any())).thenAnswer((
          Invocation invocation,
        ) async {
          forwarded.add(
            invocation.positionalArguments.first as WalletNotification?,
          );
        });

        sl.registerSingleton<NotificationsBloc>(mockNotificationsBloc);
        addTearDown(sl.unregister<NotificationsBloc>);

        final AutoReceiveTxWorker worker = buildWorker();
        addTearDown(worker.close);

        await worker.addHash(hash1);
        await worker.autoReceive();

        expect(forwarded, hasLength(1));
        expect(forwarded.single?.type, NotificationType.paymentReceived);
        expect(forwarded.single?.title, 'Transaction received on Address 1');
      },
    );

    test(
      'autoReceive completes and emits state even if onNotification throws',
      () async {
        final AutoReceiveTxWorker worker = buildWorker(
          onNotification: (_) => throw StateError('notification sink failed'),
        );
        addTearDown(worker.close);

        final List<AutoReceiveTxState> emitted = <AutoReceiveTxState>[];
        final StreamSubscription<AutoReceiveTxState> sub = worker.stream.listen(
          emitted.add,
        );
        addTearDown(sub.cancel);

        await worker.addHash(hash1);
        await worker.autoReceive();
        await Future<void>.delayed(Duration.zero);

        expect(worker.pool, isEmpty);
        expect(worker.running, isFalse);
        expect(
          emitted.where((AutoReceiveTxState s) => s.lastNotification != null),
          hasLength(1),
        );
      },
    );

    test('localizes success and error notifications via injected l10nProvider '
        'without BuildContext', () async {
      final List<WalletNotification> captured = <WalletNotification>[];
      final AutoReceiveTxWorker worker = buildWorker(
        onNotification: captured.add,
        l10nProvider: _CustomAutoReceiveL10n.new,
      );
      addTearDown(worker.close);

      await worker.addHash(hash1);
      await worker.autoReceive();

      expect(captured, hasLength(1));
      expect(captured.single.type, NotificationType.paymentReceived);
      expect(captured.single.title, '[L10N] Received on Address 1');
      expect(captured.single.details, '[L10N] Hash: ${testTemplate.hash}');

      captured.clear();
      when(
        () => mockAccountBlockUtils.createAccountBlock(
          any(),
          any(),
          address: any(named: 'address'),
          waitForRequiredPlasma: any(named: 'waitForRequiredPlasma'),
        ),
      ).thenThrow(LocalizedSyriusException(SyriusErrorCode.walletNotUnlocked));

      await worker.addHash(hash2);
      await worker.autoReceive();

      expect(captured, hasLength(1));
      expect(captured.single.type, NotificationType.error);
      expect(captured.single.title, '[L10N] Receive failed');
      expect(
        captured.single.details,
        '[L10N] Failed details: [L10N] Wallet locked',
      );
    });
  });
}
