import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:json_rpc_2/json_rpc_2.dart' show RpcException;
import 'package:logging/logging.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/l10n/app_localizations_en.dart';
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/wallet_file.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class MockNodeSyncMonitor extends Mock implements NodeSyncMonitor {}

class MockNotificationsBloc extends Mock implements NotificationsBloc {}

class MockHtlcSwapUnlockService extends Mock implements HtlcSwapUnlockService {}

class MockWalletFile extends Mock implements WalletFile {}

class FakeWalletNotification extends Fake implements WalletNotification {}

class _CustomAutoUnlockL10n extends AppLocalizationsEn {
  _CustomAutoUnlockL10n() : super('en');

  @override
  String get failedToCompleteSwap => '[L10N] Failed swap title';

  @override
  String failedToCompleteSwapWithError(String error) =>
      '[L10N] Failed swap details: $error';

  @override
  String get swapAddressNotInDefaultAddresses => '[L10N] Swap address missing';
}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeWalletNotification());
  });

  group('HtlcSwapAutoUnlockService', () {
    final Hash htlcId = Hash.digest(<int>[1, 2, 3]);
    final List<int> preimage = <int>[4, 5, 6];
    final Address selfAddress = emptyAddress;

    late MockHtlcSwapUnlockService unlockService;
    late MockNotificationsBloc notificationsBloc;
    late MockNodeSyncMonitor syncMonitor;
    late AccountBlockTemplate transactionParams;
    late HtlcSwap swap;
    late HtlcSwapAutoUnlockService service;
    late List<WalletNotification> notifications;
    late DateTime now;
    late WalletFile? previousWalletFile;

    setUp(() {
      previousWalletFile = kWalletFile;
      unlockService = MockHtlcSwapUnlockService();
      notificationsBloc = MockNotificationsBloc();
      syncMonitor = MockNodeSyncMonitor();
      transactionParams = AccountBlockTemplate(blockType: 1);
      notifications = <WalletNotification>[];
      now = DateTime(2026);
      kWalletFile = MockWalletFile();

      swap = HtlcSwap(
        hashLock: Hash.digest(preimage).toString(),
        initialHtlcId: htlcId.toString(),
        initialHtlcExpirationTime: 2000,
        hashType: htlcHashTypeSha3,
        id: htlcId.toString(),
        chainId: 1,
        type: P2pSwapType.native,
        direction: P2pSwapDirection.incoming,
        selfAddress: selfAddress.toString(),
        counterpartyAddress: htlcAddress.toString(),
        fromAmount: BigInt.one,
        fromToken: kZnnCoin,
        fromChain: P2pSwapChain.nom,
        toChain: P2pSwapChain.nom,
        startTime: 1000,
        state: P2pSwapState.active,
        preimage: FormatUtils.encodeHexString(preimage),
      );

      when(() => syncMonitor.isNodeSynced()).thenAnswer((_) async => true);
      when(
        () => unlockService.unlock(swap),
      ).thenAnswer((_) async => transactionParams);
      when(() => notificationsBloc.addNotification(any())).thenAnswer((
        Invocation invocation,
      ) async {
        notifications.add(
          invocation.positionalArguments.single as WalletNotification,
        );
      });

      service = HtlcSwapAutoUnlockService(
        notificationsBloc: notificationsBloc,
        syncMonitor: syncMonitor,
        unlockService: unlockService,
        now: () => now,
      );
    });

    tearDown(() {
      kWalletFile = previousWalletFile;
    });

    test(
      'unlocks one eligible swap and sends a success notification',
      () async {
        await service.unlockNext(<HtlcSwap>[swap]);

        verify(() => unlockService.unlock(swap)).called(1);
        expect(notifications, hasLength(1));
        expect(notifications.single.type, NotificationType.paymentReceived);
      },
    );

    test('exposes an in-progress unlock attempt', () async {
      final Completer<AccountBlockTemplate> completer =
          Completer<AccountBlockTemplate>();
      when(
        () => unlockService.unlock(swap),
      ).thenAnswer((_) => completer.future);

      final Future<void> unlock = service.unlockNext(<HtlcSwap>[swap]);
      await Future<void>.delayed(Duration.zero);

      expect(service.isUnlocking, isTrue);

      completer.complete(transactionParams);
      await unlock;
      expect(service.isUnlocking, isFalse);
    });

    test('retries a swap only after the cooldown', () async {
      await service.unlockNext(<HtlcSwap>[swap]);
      await service.unlockNext(<HtlcSwap>[swap]);

      verify(() => unlockService.unlock(swap)).called(1);

      now = now.add(const Duration(minutes: 2));
      await service.unlockNext(<HtlcSwap>[swap]);

      verify(() => unlockService.unlock(swap)).called(1);
    });

    test(
      'does not attempt an unlock while the wallet is unavailable',
      () async {
        kWalletFile = null;

        await service.unlockNext(<HtlcSwap>[swap]);

        verifyNever(() => syncMonitor.isNodeSynced());
        verifyNever(() => unlockService.unlock(swap));
        expect(notifications, isEmpty);
      },
    );

    test('does not attempt an unlock while the node is syncing', () async {
      when(() => syncMonitor.isNodeSynced()).thenAnswer((_) async => false);

      await service.unlockNext(<HtlcSwap>[swap]);

      verifyNever(() => unlockService.unlock(swap));
      expect(notifications, isEmpty);
    });

    test('reports an unlock failure', () async {
      when(
        () => unlockService.unlock(swap),
      ).thenThrow(SyriusException('Swap address not in default addresses.'));

      await service.unlockNext(<HtlcSwap>[swap]);

      expect(notifications, hasLength(1));
      expect(notifications.single.type, NotificationType.error);
      expect(
        notifications.single.details,
        contains('Swap address not in default addresses'),
      );
    });

    test('sanitizes RpcException details in logs and notifications while '
        'suppressing data non existent notifications', () async {
      const String secretPreimage = 'deadbeefcafebabe0123456789abcdef';
      final List<LogRecord> records = <LogRecord>[];
      final StreamSubscription<LogRecord> subscription = Logger(
        'HtlcSwapAutoUnlockService',
      ).onRecord.listen(records.add);
      addTearDown(subscription.cancel);

      when(() => unlockService.unlock(swap)).thenThrow(
        RpcException(
          -32000,
          'node rejected tx containing $secretPreimage',
          data: secretPreimage,
        ),
      );

      await service.unlockNext(<HtlcSwap>[swap]);

      expect(notifications, hasLength(1));
      expect(notifications.single.type, NotificationType.error);
      expect(
        notifications.single.details,
        'Failed to complete the swap: RpcException (code=-32000)',
      );
      expect(notifications.single.details, isNot(contains(secretPreimage)));
      expect(records, hasLength(1));
      expect(records.single.error, isA<RedactedSwapError>());
      expect(records.single.error.toString(), 'RpcException (code=-32000)');
      expect(records.single.error.toString(), isNot(contains(secretPreimage)));

      now = now.add(const Duration(minutes: 2));
      notifications.clear();
      records.clear();

      when(
        () => unlockService.unlock(swap),
      ).thenThrow(RpcException(-32000, 'data non existent: $secretPreimage'));

      await service.unlockNext(<HtlcSwap>[swap]);

      expect(notifications, isEmpty);
      expect(records, hasLength(1));
      expect(records.single.error.toString(), isNot(contains(secretPreimage)));
    });

    test(
      'sanitizes unexpected unlock errors in logs and notifications',
      () async {
        const String secretPreimage = 'deadbeefcafebabe0123456789abcdef';
        final List<LogRecord> records = <LogRecord>[];
        final StreamSubscription<LogRecord> subscription =
            Logger('HtlcSwapAutoUnlockService').onRecord.listen((
              LogRecord record,
            ) {
              if (record.loggerName == 'HtlcSwapAutoUnlockService') {
                records.add(record);
              }
            });
        addTearDown(subscription.cancel);

        when(() => unlockService.unlock(swap)).thenThrow(
          const FormatException('Invalid hexadecimal string', secretPreimage),
        );

        await service.unlockNext(<HtlcSwap>[swap]);

        expect(notifications, hasLength(1));
        expect(notifications.single.type, NotificationType.error);
        expect(
          notifications.single.details,
          'Failed to complete the swap: FormatException',
        );
        expect(notifications.single.details, isNot(contains(secretPreimage)));
        expect(records, hasLength(1));
        expect(records.single.error, isA<RedactedSwapError>());
        expect(records.single.error.toString(), 'FormatException');
        expect(
          records.single.error.toString(),
          isNot(contains(secretPreimage)),
        );
      },
    );

    test(
      'localizes LocalizedSyriusException errors via injected l10nProvider',
      () async {
        final HtlcSwapAutoUnlockService localizedService =
            HtlcSwapAutoUnlockService(
              notificationsBloc: notificationsBloc,
              syncMonitor: syncMonitor,
              unlockService: unlockService,
              now: () => now,
              l10nProvider: _CustomAutoUnlockL10n.new,
            );

        when(() => unlockService.unlock(swap)).thenThrow(
          LocalizedSyriusException(
            SyriusErrorCode.swapAddressNotInDefaultAddresses,
          ),
        );

        await localizedService.unlockNext(<HtlcSwap>[swap]);

        expect(notifications, hasLength(1));
        expect(notifications.single.title, '[L10N] Failed swap title');
        expect(
          notifications.single.details,
          '[L10N] Failed swap details: [L10N] Swap address missing',
        );
      },
    );
  });
}
