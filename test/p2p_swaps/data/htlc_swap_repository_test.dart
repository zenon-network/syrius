import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

void main() {
  late Directory temporaryDirectory;
  late File databaseFile;
  late HtlcSwapLocalStorageApi dataProvider;
  late HtlcSwapRepository repository;
  late int? originalChainId;

  final List<int> encryptionKey = Crypto.digest(utf8.encode('password'));
  final List<int> newEncryptionKey = Crypto.digest(
    utf8.encode('new-password'),
  );

  void createDataLayer() {
    dataProvider = HtlcSwapLocalStorageApi(databaseFile: databaseFile);
    repository = HtlcSwapRepository(
      chainIdProvider: () => kNodeChainId,
      dataProvider: dataProvider,
    );
  }

  setUp(() async {
    originalChainId = kNodeChainId;
    kNodeChainId = 1;
    temporaryDirectory = await Directory.systemTemp.createTemp(
      'syrius_htlc_drift_test_',
    );
    databaseFile = File('${temporaryDirectory.path}/htlc_swaps.sqlite');
    createDataLayer();
    await dataProvider.open(encryptionKey);
  });

  tearDown(() async {
    await dataProvider.close();
    kNodeChainId = originalChainId;
    if (await temporaryDirectory.exists()) {
      await temporaryDirectory.delete(recursive: true);
    }
  });

  test(
    'reads swap history across chains and scopes operational queries',
    () async {
      final HtlcSwap swap = _buildSwap();
      await repository.storeSwap(swap);

      expect(await repository.getAllSwaps(), <HtlcSwap>[swap]);
      expect(await repository.getSwapById(swap.id), swap);
      expect(await repository.getSwapByHashLock(swap.hashLock), swap);
      expect(await repository.getSwapByHtlcId(swap.initialHtlcId), swap);
      expect(await repository.getSwapByHtlcId(swap.counterHtlcId!), swap);
      expect(
        await repository.getSwapsByState(<P2pSwapState>[P2pSwapState.active]),
        <HtlcSwap>[swap],
      );

      kNodeChainId = 2;
      expect(await repository.getAllSwaps(), <HtlcSwap>[swap]);
      expect(await repository.getSwapById(swap.id), swap);
      expect(await repository.getSwapByHashLock(swap.hashLock), isNull);
      expect(
        await repository.getSwapsByState(<P2pSwapState>[P2pSwapState.active]),
        isEmpty,
      );
    },
  );

  test('watches swap history across chains ordered newest first', () async {
    final StreamIterator<List<HtlcSwap>> swaps = StreamIterator<List<HtlcSwap>>(
      repository.watchAllSwaps(),
    );
    addTearDown(swaps.cancel);

    expect(await swaps.moveNext(), isTrue);
    expect(swaps.current, isEmpty);

    final HtlcSwap older = _buildSwap(id: 'older');
    await repository.storeSwap(older);
    expect(await swaps.moveNext(), isTrue);
    expect(swaps.current, <HtlcSwap>[older]);

    final HtlcSwap newer = _buildSwap(
      id: 'newer',
      chainId: 2,
      startTime: 2,
    );
    await repository.storeSwap(newer);
    expect(await swaps.moveNext(), isTrue);
    expect(swaps.current, <HtlcSwap>[newer, older]);
  });

  test('stores scan checkpoints independently for each chain', () async {
    await repository.storeLastCheckedHtlcBlockHeight(10);
    expect(await repository.getLastCheckedHtlcBlockHeight(), 10);

    kNodeChainId = 2;
    expect(await repository.getLastCheckedHtlcBlockHeight(), 0);
    await repository.storeLastCheckedHtlcBlockHeight(20);
    expect(await repository.getLastCheckedHtlcBlockHeight(), 20);

    kNodeChainId = 1;
    expect(await repository.getLastCheckedHtlcBlockHeight(), 10);
  });

  test('stores a processed block update with its checkpoint', () async {
    final HtlcSwap pendingSwap = _buildSwap(state: P2pSwapState.pending);
    await repository.storeSwap(pendingSwap);

    final HtlcSwap activeSwap = pendingSwap.copyWith(
      state: P2pSwapState.active,
    );
    await repository.storeProcessedHtlcBlock(
      height: 10,
      updatedSwap: activeSwap,
    );

    expect(await repository.getSwapById(activeSwap.id), activeSwap);
    expect(await repository.getLastCheckedHtlcBlockHeight(), 10);
  });

  test('checkpoints a processed block without a swap update', () async {
    await repository.storeProcessedHtlcBlock(
      height: 10,
      updatedSwap: null,
    );

    expect(await repository.getAllSwaps(), isEmpty);
    expect(await repository.getLastCheckedHtlcBlockHeight(), 10);
  });

  test('deletes inactive swaps only on the current chain', () async {
    final HtlcSwap active = _buildSwap(id: 'active');
    final HtlcSwap completed = _buildSwap(
      id: 'completed',
      state: P2pSwapState.completed,
    );
    final HtlcSwap otherChain = _buildSwap(
      id: 'other-chain',
      chainId: 2,
      state: P2pSwapState.completed,
    );
    await repository.storeSwap(active);
    await repository.storeSwap(completed);
    await repository.storeSwap(otherChain);

    await repository.deleteInactiveSwaps();

    expect(
      await repository.getAllSwaps(),
      unorderedEquals(<HtlcSwap>[active, otherChain]),
    );
    kNodeChainId = 2;
    expect(
      await repository.getAllSwaps(),
      unorderedEquals(<HtlcSwap>[active, otherChain]),
    );
  });

  test('encrypts the database and rejects an incorrect key', () async {
    const String secretPreimage = 'unencrypted-preimage-marker';
    await repository.storeSwap(_buildSwap(preimage: secretPreimage));
    await dataProvider.close();

    final String databaseContents = latin1.decode(
      await databaseFile.readAsBytes(),
      allowInvalid: true,
    );
    expect(databaseContents, isNot(contains('SQLite format 3')));
    expect(databaseContents, isNot(contains(secretPreimage)));

    final HtlcSwapLocalStorageApi incorrectKeyDataProvider =
        HtlcSwapLocalStorageApi(
          databaseFile: databaseFile,
        );
    await expectLater(
      incorrectKeyDataProvider.open(newEncryptionKey),
      throwsA(anything),
    );
    await incorrectKeyDataProvider.close();

    createDataLayer();
    await dataProvider.open(encryptionKey);
    expect(await repository.getAllSwaps(), hasLength(1));
  });

  test('rekeys the database when the password changes', () async {
    final HtlcSwap swap = _buildSwap();
    await repository.storeSwap(swap);

    await dataProvider.beginRekey(
      oldEncryptionKey: encryptionKey,
      newEncryptionKey: newEncryptionKey,
    );
    await dataProvider.commitRekey();
    await dataProvider.close();

    final HtlcSwapLocalStorageApi oldKeyDataProvider = HtlcSwapLocalStorageApi(
      databaseFile: databaseFile,
    );
    await expectLater(
      oldKeyDataProvider.open(encryptionKey),
      throwsA(anything),
    );
    await oldKeyDataProvider.close();

    createDataLayer();
    await dataProvider.open(newEncryptionKey);
    expect(await repository.getAllSwaps(), <HtlcSwap>[swap]);
  });

  test('restores the old key after an interrupted password change', () async {
    final HtlcSwap swap = _buildSwap();
    await repository.storeSwap(swap);
    await dataProvider.beginRekey(
      oldEncryptionKey: encryptionKey,
      newEncryptionKey: newEncryptionKey,
    );
    await dataProvider.close();

    createDataLayer();
    await dataProvider.open(encryptionKey);

    expect(await repository.getAllSwaps(), <HtlcSwap>[swap]);
    expect(await File('${databaseFile.path}.rekey-backup').exists(), isFalse);
  });

  test('rolls back a prepared password change', () async {
    final HtlcSwap swap = _buildSwap();
    await repository.storeSwap(swap);
    await dataProvider.beginRekey(
      oldEncryptionKey: encryptionKey,
      newEncryptionKey: newEncryptionKey,
    );

    await dataProvider.rollbackRekey(encryptionKey);

    expect(await repository.getAllSwaps(), <HtlcSwap>[swap]);
    await dataProvider.close();
    createDataLayer();
    await dataProvider.open(encryptionKey);
    expect(await repository.getAllSwaps(), <HtlcSwap>[swap]);
  });
}

HtlcSwap _buildSwap({
  String id = 'swap-id',
  int chainId = 1,
  P2pSwapState state = P2pSwapState.active,
  String? preimage,
  int startTime = 1,
}) => HtlcSwap(
  hashLock: 'hash-lock-$id',
  initialHtlcId: 'initial-htlc-id-$id',
  initialHtlcExpirationTime: 1000,
  hashType: htlcHashTypeSha3,
  id: id,
  chainId: chainId,
  type: P2pSwapType.native,
  direction: P2pSwapDirection.incoming,
  selfAddress: 'self-address',
  counterpartyAddress: 'counterparty-address',
  fromAmount: BigInt.from(100),
  fromToken: kZnnCoin,
  fromChain: P2pSwapChain.nom,
  toChain: P2pSwapChain.nom,
  startTime: startTime,
  state: state,
  toAmount: BigInt.from(200),
  toToken: kQsrCoin,
  counterHtlcId: 'counter-htlc-id-$id',
  counterHtlcExpirationTime: 900,
  preimage: preimage,
);
