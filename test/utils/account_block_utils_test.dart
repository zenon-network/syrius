import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mutex/mutex.dart';
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/exceptions/exceptions.dart';
import 'package:zenon_syrius_wallet_flutter/utils/account_block_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/wallet_file.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class _MockZenon extends Mock implements Zenon {}

class _MockStatsApi extends Mock implements StatsApi {}

class _FakeWalletAccount implements WalletAccount {
  _FakeWalletAccount(this._address, this.accountIndex);

  final Address _address;
  final int accountIndex;

  @override
  Future<Address> getAddress() async => _address;

  @override
  Future<List<int>> getPublicKey() async => <int>[];

  @override
  Future<List<int>> sign(List<int> message) async => <int>[];

  @override
  Future<List<int>> signTx(AccountBlockTemplate tx) async => <int>[];
}

class _FakeWallet implements Wallet {
  _FakeWallet(this._addresses);

  final List<Address> _addresses;
  final List<int> requestedIndices = <int>[];

  @override
  Future<WalletAccount> getAccount([int accountIndex = 0]) async {
    requestedIndices.add(accountIndex);
    if (accountIndex < 0 || accountIndex >= _addresses.length) {
      throw RangeError.index(accountIndex, _addresses);
    }
    return _FakeWalletAccount(_addresses[accountIndex], accountIndex);
  }
}

class _LockingWalletFile extends WalletFile {
  _LockingWalletFile(this._wallet, {required this.isHardwareWallet})
    : super('/tmp/fake-wallet');

  final Wallet _wallet;
  final Mutex _lock = Mutex();
  int openCalls = 0;

  @override
  final bool isHardwareWallet;

  @override
  String get walletType => isHardwareWallet ? 'ledger' : keyStoreWalletType;

  @override
  bool get isOpen => _lock.isLocked;

  @override
  Future<Wallet> open() async {
    await _lock.acquire();
    openCalls++;
    return _wallet;
  }

  @override
  void close() {
    if (_lock.isLocked) {
      _lock.release();
    }
  }
}

void main() {
  setUpAll(() {
    registerFallbackValue(AccountBlockTemplate(blockType: 2));
    registerFallbackValue(_FakeWalletAccount(emptyAddress, 0));
  });

  group('AccountBlockUtils.createAccountBlock', () {
    final Address address0 = Address.parse(
      'z1qqjnwjjpnue8xmmpanz6csze6tcmtzzdtfsww7',
    );
    final Address address1 = stakeAddress;
    final Address unknownAddress = tokenAddress;

    late _MockZenon mockZenon;
    late _MockStatsApi mockStatsApi;
    late _FakeWallet fakeWallet;
    late _LockingWalletFile softwareWalletFile;
    late List<String?> addressList;
    late List<WalletNotification> notifications;
    late List<String> plasmaNotifications;
    late List<PowStatus> powStatuses;

    SyncInfo syncedInfo() => SyncInfo.fromJson(<String, dynamic>{
      'state': SyncState.syncDone.index,
      'currentHeight': 100,
      'targetHeight': 100,
    });

    AccountBlockUtils buildUtils({
      WalletFile? Function()? walletFileProvider,
      List<String?> Function()? addressListProvider,
      String? Function()? selectedAddressProvider,
      Duration postSendDelay = Duration.zero,
    }) {
      return AccountBlockUtils(
        zenonProvider: () => mockZenon,
        walletFileProvider: walletFileProvider ?? () => softwareWalletFile,
        addressListProvider: addressListProvider ?? () => addressList,
        selectedAddressProvider: selectedAddressProvider ?? address0.toString,
        sendPlasmaNotification: (String purpose) async {
          plasmaNotifications.add(purpose);
        },
        addNotification: (WalletNotification notification) async {
          notifications.add(notification);
        },
        onPowStatusChanged: powStatuses.add,
        postSendDelay: postSendDelay,
      );
    }

    setUp(() {
      mockZenon = _MockZenon();
      mockStatsApi = _MockStatsApi();
      fakeWallet = _FakeWallet(<Address>[address0, address1]);
      softwareWalletFile = _LockingWalletFile(
        fakeWallet,
        isHardwareWallet: false,
      );
      addressList = <String?>[address0.toString(), address1.toString()];
      notifications = <WalletNotification>[];
      plasmaNotifications = <String>[];
      powStatuses = <PowStatus>[];

      when(() => mockZenon.stats).thenReturn(mockStatsApi);
      when(() => mockStatsApi.syncInfo()).thenAnswer((_) async => syncedInfo());
      when(
        () => mockZenon.requiresPoW(
          any(),
          blockSigningKey: any(named: 'blockSigningKey'),
        ),
      ).thenAnswer((_) async => false);
      when(
        () => mockZenon.send(
          any(),
          currentKeyPair: any(named: 'currentKeyPair'),
          generatingPowCallback: any(named: 'generatingPowCallback'),
          waitForRequiredPlasma: any(named: 'waitForRequiredPlasma'),
        ),
      ).thenAnswer(
        (Invocation invocation) async =>
            invocation.positionalArguments.first as AccountBlockTemplate,
      );
    });

    test(
      'throws SyriusException without opening wallet when address is missing',
      () async {
        final AccountBlockUtils utils = buildUtils();
        final AccountBlockTemplate tx = AccountBlockTemplate(
          blockType: BlockTypeEnum.userSend.index,
        );

        await expectLater(
          () => utils.createAccountBlock(tx, 'send', address: unknownAddress),
          throwsA(
            isA<SyriusException>().having(
              (SyriusException e) => e.message,
              'message',
              contains(unknownAddress.toString()),
            ),
          ),
        );

        expect(softwareWalletFile.openCalls, 0);
        expect(fakeWallet.requestedIndices, isEmpty);
        verifyNever(
          () => mockZenon.send(
            any(),
            currentKeyPair: any(named: 'currentKeyPair'),
            generatingPowCallback: any(named: 'generatingPowCallback'),
            waitForRequiredPlasma: any(named: 'waitForRequiredPlasma'),
          ),
        );
      },
    );

    test(
      'throws SyriusException when selected address is null or not in list',
      () async {
        final AccountBlockUtils nullSelected = buildUtils(
          selectedAddressProvider: () => null,
        );
        final AccountBlockUtils missingSelected = buildUtils(
          selectedAddressProvider: unknownAddress.toString,
        );
        final AccountBlockTemplate tx = AccountBlockTemplate(
          blockType: BlockTypeEnum.userSend.index,
        );

        await expectLater(
          () => nullSelected.createAccountBlock(tx, 'send'),
          throwsA(isA<SyriusException>()),
        );
        await expectLater(
          () => missingSelected.createAccountBlock(tx, 'send'),
          throwsA(isA<SyriusException>()),
        );
        expect(softwareWalletFile.openCalls, 0);
      },
    );

    test('throws SyriusException when wallet file is not unlocked', () async {
      final AccountBlockUtils utils = buildUtils(
        walletFileProvider: () => null,
      );
      final AccountBlockTemplate tx = AccountBlockTemplate(
        blockType: BlockTypeEnum.userSend.index,
      );

      await expectLater(
        () => utils.createAccountBlock(tx, 'send', address: address0),
        throwsA(isA<SyriusException>()),
      );
    });

    test('throws NodeNotSyncedException when node is not synced', () async {
      when(() => mockStatsApi.syncInfo()).thenAnswer(
        (_) async => SyncInfo.fromJson(<String, dynamic>{
          'state': SyncState.syncing.index,
          'currentHeight': 10,
          'targetHeight': 100,
        }),
      );
      final AccountBlockUtils utils = buildUtils();
      final AccountBlockTemplate tx = AccountBlockTemplate(
        blockType: BlockTypeEnum.userSend.index,
      );

      await expectLater(
        () => utils.createAccountBlock(tx, 'send', address: address0),
        throwsA(isA<NodeNotSyncedException>()),
      );
      expect(softwareWalletFile.openCalls, 0);
    });

    test(
      'releases software wallet lock before requiresPoW and PoW send so '
      'concurrent wallet access does not stall',
      () async {
        final Completer<void> powStarted = Completer<void>();
        final Completer<void> finishPow = Completer<void>();
        bool? walletLockedDuringRequiresPoW;
        bool? walletLockedDuringSend;

        when(
          () => mockZenon.requiresPoW(
            any(),
            blockSigningKey: any(named: 'blockSigningKey'),
          ),
        ).thenAnswer((_) async {
          walletLockedDuringRequiresPoW = softwareWalletFile.isOpen;
          return true;
        });

        when(
          () => mockZenon.send(
            any(),
            currentKeyPair: any(named: 'currentKeyPair'),
            generatingPowCallback: any(named: 'generatingPowCallback'),
            waitForRequiredPlasma: any(named: 'waitForRequiredPlasma'),
          ),
        ).thenAnswer((Invocation invocation) async {
          walletLockedDuringSend = softwareWalletFile.isOpen;
          powStarted.complete();
          await finishPow.future;
          return invocation.positionalArguments.first as AccountBlockTemplate;
        });

        final AccountBlockUtils utils = buildUtils();
        final AccountBlockTemplate tx = AccountBlockTemplate(
          blockType: BlockTypeEnum.userSend.index,
        );

        final Future<AccountBlockTemplate> sendFuture = utils
            .createAccountBlock(tx, 'send tx', address: address0);

        await powStarted.future;
        expect(walletLockedDuringRequiresPoW, isFalse);
        expect(walletLockedDuringSend, isFalse);
        expect(softwareWalletFile.isOpen, isFalse);

        // Concurrent wallet read (e.g. address derivation / reclaim discovery)
        // must complete immediately while PoW is still running.
        final Address concurrentDerived = await softwareWalletFile
            .access<Address>(
              (Wallet wallet) async =>
                  await (await wallet.getAccount(1)).getAddress(),
            );
        expect(concurrentDerived, address1);

        finishPow.complete();
        final AccountBlockTemplate result = await sendFuture;
        expect(result, same(tx));
        expect(plasmaNotifications, <String>['send tx']);
        expect(notifications, hasLength(1));
      },
    );

    test(
      'serializes consecutive sends from the same address across postSendDelay '
      'while allowing sends from different addresses concurrently',
      () async {
        final Completer<void> firstSendEntered = Completer<void>();
        final Completer<void> releaseFirstSend = Completer<void>();
        final Completer<void> otherAddrSendEntered = Completer<void>();
        final List<String> sendTimeline = <String>[];

        when(
          () => mockZenon.send(
            any(),
            currentKeyPair: any(named: 'currentKeyPair'),
            generatingPowCallback: any(named: 'generatingPowCallback'),
            waitForRequiredPlasma: any(named: 'waitForRequiredPlasma'),
          ),
        ).thenAnswer((Invocation invocation) async {
          final AccountBlockTemplate block =
              invocation.positionalArguments.first as AccountBlockTemplate;
          final _FakeWalletAccount account =
              invocation.namedArguments[#currentKeyPair] as _FakeWalletAccount;
          if (account.accountIndex == 0 && !firstSendEntered.isCompleted) {
            sendTimeline.add('addr0-first-start');
            firstSendEntered.complete();
            await releaseFirstSend.future;
            sendTimeline.add('addr0-first-end');
          } else if (account.accountIndex == 0) {
            sendTimeline.add('addr0-second-start');
          } else {
            sendTimeline.add('addr1-start');
            otherAddrSendEntered.complete();
          }
          return block;
        });

        final AccountBlockUtils utils = buildUtils(
          postSendDelay: const Duration(milliseconds: 80),
        );

        final Future<AccountBlockTemplate> firstAddr0 = utils
            .createAccountBlock(
              AccountBlockTemplate(blockType: BlockTypeEnum.userSend.index),
              'first',
              address: address0,
            );

        await firstSendEntered.future;

        // Start a second send on the SAME address and a send on a DIFFERENT
        // address while the first send is still in flight.
        final Future<AccountBlockTemplate> secondAddr0 = utils
            .createAccountBlock(
              AccountBlockTemplate(blockType: BlockTypeEnum.userSend.index),
              'second',
              address: address0,
            );
        final Future<AccountBlockTemplate> sendAddr1 = utils.createAccountBlock(
          AccountBlockTemplate(blockType: BlockTypeEnum.userSend.index),
          'other',
          address: address1,
        );

        // Different address must not wait on address0's send lock.
        await otherAddrSendEntered.future;
        await sendAddr1;

        // Second send on address0 must still be waiting behind the first send.
        expect(sendTimeline, isNot(contains('addr0-second-start')));

        final DateTime releasedAt = DateTime.now();
        releaseFirstSend.complete();

        await Future.wait<AccountBlockTemplate>(<Future<AccountBlockTemplate>>[
          firstAddr0,
          secondAddr0,
        ]);

        // Second send on address0 must start only after first finished.
        expect(
          sendTimeline.indexOf('addr0-first-end'),
          lessThan(sendTimeline.indexOf('addr0-second-start')),
        );
        expect(
          DateTime.now().difference(releasedAt),
          greaterThanOrEqualTo(const Duration(milliseconds: 60)),
        );
      },
    );

    test(
      'keeps hardware wallet lock during send and releases it before '
      'postSendDelay',
      () async {
        final _LockingWalletFile hardwareWalletFile = _LockingWalletFile(
          fakeWallet,
          isHardwareWallet: true,
        );
        bool? walletLockedDuringSend;

        when(
          () => mockZenon.send(
            any(),
            currentKeyPair: any(named: 'currentKeyPair'),
            generatingPowCallback: any(named: 'generatingPowCallback'),
            waitForRequiredPlasma: any(named: 'waitForRequiredPlasma'),
          ),
        ).thenAnswer((Invocation invocation) async {
          walletLockedDuringSend = hardwareWalletFile.isOpen;
          return invocation.positionalArguments.first as AccountBlockTemplate;
        });

        final AccountBlockUtils utils = buildUtils(
          walletFileProvider: () => hardwareWalletFile,
          postSendDelay: const Duration(milliseconds: 80),
        );

        final Future<AccountBlockTemplate> txFuture = utils.createAccountBlock(
          AccountBlockTemplate(blockType: BlockTypeEnum.userSend.index),
          'hw send',
          address: address0,
        );

        // Let send complete and enter postSendDelay.
        await Future<void>.delayed(const Duration(milliseconds: 20));
        expect(walletLockedDuringSend, isTrue);
        // Hardware wallet lock must already be released during postSendDelay.
        expect(hardwareWalletFile.isOpen, isFalse);

        await txFuture;
        // Hardware review notification + published notification.
        expect(notifications, hasLength(2));
      },
    );

    test(
      'releases per-address lock on send failure so subsequent send succeeds',
      () async {
        int attempts = 0;
        when(
          () => mockZenon.send(
            any(),
            currentKeyPair: any(named: 'currentKeyPair'),
            generatingPowCallback: any(named: 'generatingPowCallback'),
            waitForRequiredPlasma: any(named: 'waitForRequiredPlasma'),
          ),
        ).thenAnswer((Invocation invocation) async {
          attempts++;
          if (attempts == 1) {
            throw StateError('rpc failed');
          }
          return invocation.positionalArguments.first as AccountBlockTemplate;
        });

        final AccountBlockUtils utils = buildUtils();
        final AccountBlockTemplate tx = AccountBlockTemplate(
          blockType: BlockTypeEnum.userSend.index,
        );

        await expectLater(
          () => utils.createAccountBlock(tx, 'send', address: address0),
          throwsA(isA<StateError>()),
        );
        expect(softwareWalletFile.isOpen, isFalse);

        final AccountBlockTemplate retryResult = await utils.createAccountBlock(
          tx,
          'send retry',
          address: address0,
        );
        expect(retryResult, same(tx));
        expect(attempts, 2);
      },
    );
  });
}
