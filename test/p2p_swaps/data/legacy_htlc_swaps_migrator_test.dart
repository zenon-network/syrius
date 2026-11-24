import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:logging/logging.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class _MockHive extends Mock implements HiveInterface {}

class _MockBox extends Mock implements Box<dynamic> {}

class _MockRepository extends Mock implements HtlcSwapRepository {}

void main() {
  const String walletBaseAddress = 'z1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqsggv2f';
  const String legacySwapsBoxName = '${kHtlcSwapsBox}_$walletBaseAddress';

  final List<int> encryptionKey = Crypto.digest(utf8.encode('wallet-pass'));
  final List<int> wrongEncryptionKey = Crypto.digest(utf8.encode('other-pass'));

  late Directory temporaryDirectory;
  late File databaseFile;
  late HtlcSwapLocalStorageApi dataProvider;
  late HtlcSwapRepository repository;
  late LegacyHtlcSwapsMigrator migrator;
  late int? originalChainId;

  setUp(() async {
    originalChainId = kNodeChainId;
    kNodeChainId = 1;
    temporaryDirectory = await Directory.systemTemp.createTemp(
      'syrius_htlc_hive_migration_test_',
    );
    Hive.init(temporaryDirectory.path);
    databaseFile = File('${temporaryDirectory.path}/htlc_swaps.sqlite');
    dataProvider = HtlcSwapLocalStorageApi(databaseFile: databaseFile);
    repository = HtlcSwapRepository(
      chainIdProvider: () => kNodeChainId,
      dataProvider: dataProvider,
    );
    migrator = LegacyHtlcSwapsMigrator(
      swapRepository: repository,
      hiveDirectoryPath: temporaryDirectory.path,
    );
    await dataProvider.open(encryptionKey);
  });

  tearDown(() async {
    await dataProvider.close();
    await Hive.close();
    kNodeChainId = originalChainId;
    if (temporaryDirectory.existsSync()) {
      await temporaryDirectory.delete(recursive: true);
    }
  });

  test('is a no-op when no legacy Hive boxes exist', () async {
    final LegacyHtlcSwapsMigrationResult result = await migrator
        .migrateIfNeeded(
          walletBaseAddress: walletBaseAddress,
          encryptionKey: encryptionKey,
        );

    expect(result.migratedCount, 0);
    expect(result.failedCount, 0);
    expect(result.deletedLegacyBoxes, isTrue);
    expect(await repository.getAllSwaps(), isEmpty);
    expect(
      await Hive.boxExists(legacySwapsBoxName, path: temporaryDirectory.path),
      isFalse,
    );
    expect(
      await Hive.boxExists(
        kLastCheckedHtlcBlockBox,
        path: temporaryDirectory.path,
      ),
      isFalse,
    );
  });

  test('migrates encrypted legacy Hive swaps into Drift, removes legacy boxes, '
      'and is idempotent', () async {
    final Box<dynamic> swapsBox = await Hive.openBox<dynamic>(
      legacySwapsBoxName,
      encryptionCipher: HiveAesCipher(encryptionKey),
      path: temporaryDirectory.path,
    );
    await swapsBox.put(
      'swap-active',
      jsonEncode(
        _buildLegacySwapJson(
          id: 'swap-active',
          chainId: 1,
          state: 'active',
          startTime: 200,
          preimage: 'secret-preimage-hex',
        ),
      ),
    );
    await swapsBox.put(
      'swap-testnet',
      jsonEncode(
        _buildLegacySwapJson(
          id: 'swap-testnet',
          chainId: 3,
          state: 'reclaimable',
          startTime: 100,
          includeToToken: false,
        ),
      ),
    );
    await swapsBox.close();

    final Box<dynamic> checkpointBox = await Hive.openBox<dynamic>(
      kLastCheckedHtlcBlockBox,
      encryptionCipher: HiveAesCipher(encryptionKey),
      path: temporaryDirectory.path,
    );
    await checkpointBox.put(kLastCheckedHtlcBlockKey, 42);
    await checkpointBox.close();

    final LegacyHtlcSwapsMigrationResult firstRun = await migrator
        .migrateIfNeeded(
          walletBaseAddress: walletBaseAddress,
          encryptionKey: encryptionKey,
        );

    expect(firstRun.migratedCount, 2);
    expect(firstRun.failedCount, 0);
    expect(firstRun.deletedLegacyBoxes, isTrue);

    final List<HtlcSwap> migrated = await repository.getAllSwaps();
    expect(migrated, hasLength(2));
    expect(migrated.first.id, 'swap-active');
    expect(migrated.first.preimage, 'secret-preimage-hex');
    expect(migrated.first.fromToken.tokenStandard, kZnnCoin.tokenStandard);
    expect(migrated.first.fromToken.symbol, 'ZNN');
    expect(migrated.first.fromToken.decimals, 8);
    expect(migrated.first.toToken?.tokenStandard, kQsrCoin.tokenStandard);
    expect(migrated.first.toToken?.symbol, 'QSR');
    expect(migrated.first.toAmount, BigInt.from(2000));
    expect(migrated.last.id, 'swap-testnet');
    expect(migrated.last.chainId, 3);
    expect(migrated.last.state, P2pSwapState.reclaimable);
    expect(migrated.last.toToken, isNull);
    expect(migrated.last.toAmount, isNull);
    expect(await repository.getLastCheckedHtlcBlockHeight(), 0);
    expect(
      await Hive.boxExists(legacySwapsBoxName, path: temporaryDirectory.path),
      isFalse,
    );
    expect(
      await Hive.boxExists(
        kLastCheckedHtlcBlockBox,
        path: temporaryDirectory.path,
      ),
      isFalse,
    );

    final LegacyHtlcSwapsMigrationResult secondRun = await migrator
        .migrateIfNeeded(
          walletBaseAddress: walletBaseAddress,
          encryptionKey: encryptionKey,
        );
    expect(secondRun.migratedCount, 0);
    expect(secondRun.failedCount, 0);
    expect(secondRun.deletedLegacyBoxes, isTrue);
    expect(await repository.getAllSwaps(), hasLength(2));
  });

  test(
    'does not overwrite newer Drift swap records when re-migrating',
    () async {
      final HtlcSwap completedInDrift = HtlcSwap(
        hashLock: 'hash-lock-shared',
        initialHtlcId: 'initial-htlc-shared',
        initialHtlcExpirationTime: 1000,
        hashType: htlcHashTypeSha3,
        id: 'shared-swap',
        chainId: 1,
        type: P2pSwapType.native,
        direction: P2pSwapDirection.incoming,
        selfAddress: walletBaseAddress,
        counterpartyAddress: 'z1qqjnwjjpnue8xmmpanz6csze6tcmtzzdtfsww7',
        fromAmount: BigInt.from(1000),
        fromToken: kZnnCoin,
        fromChain: P2pSwapChain.nom,
        toChain: P2pSwapChain.nom,
        startTime: 200,
        state: P2pSwapState.completed,
        toAmount: BigInt.from(2000),
        toToken: kQsrCoin,
        counterHtlcId: 'counter-htlc-shared',
        counterHtlcExpirationTime: 900,
        preimage: 'newer-drift-preimage',
      );
      await repository.storeSwap(completedInDrift);

      final Box<dynamic> swapsBox = await Hive.openBox<dynamic>(
        legacySwapsBoxName,
        encryptionCipher: HiveAesCipher(encryptionKey),
        path: temporaryDirectory.path,
      );
      await swapsBox.put(
        'shared-swap',
        jsonEncode(
          _buildLegacySwapJson(
            id: 'shared-swap',
            chainId: 1,
            state: 'active',
            startTime: 200,
          ),
        ),
      );
      await swapsBox.put(
        'missing-swap',
        jsonEncode(
          _buildLegacySwapJson(
            id: 'missing-swap',
            chainId: 1,
            state: 'pending',
            startTime: 150,
          ),
        ),
      );
      await swapsBox.close();

      final LegacyHtlcSwapsMigrationResult result = await migrator
          .migrateIfNeeded(
            walletBaseAddress: walletBaseAddress,
            encryptionKey: encryptionKey,
          );

      expect(result.migratedCount, 2);
      expect(result.failedCount, 0);
      expect(result.deletedLegacyBoxes, isTrue);

      final HtlcSwap? storedShared = await repository.getSwapById(
        'shared-swap',
      );
      expect(storedShared, completedInDrift);
      expect(await repository.getSwapById('missing-swap'), isNotNull);
    },
  );

  test(
    'migrates valid entries, removes migrated keys from retained legacy box, '
    'and does not resurrect deleted Drift swaps on re-run',
    () async {
      final Box<dynamic> swapsBox = await Hive.openBox<dynamic>(
        legacySwapsBoxName,
        encryptionCipher: HiveAesCipher(encryptionKey),
        path: temporaryDirectory.path,
      );
      await swapsBox.put(
        'valid-swap',
        jsonEncode(
          _buildLegacySwapJson(
            id: 'valid-swap',
            chainId: 1,
            state: 'active',
            startTime: 300,
          ),
        ),
      );
      await swapsBox.put('corrupt-json', '{not-valid-json');
      await swapsBox.put('non-string', 12345);
      await swapsBox.close();

      final LegacyHtlcSwapsMigrationResult firstRun = await migrator
          .migrateIfNeeded(
            walletBaseAddress: walletBaseAddress,
            encryptionKey: encryptionKey,
          );

      expect(firstRun.migratedCount, 1);
      expect(firstRun.failedCount, 2);
      expect(firstRun.deletedLegacyBoxes, isFalse);
      expect(await repository.getSwapById('valid-swap'), isNotNull);
      expect(
        await Hive.boxExists(legacySwapsBoxName, path: temporaryDirectory.path),
        isTrue,
      );
      expect(Hive.isBoxOpen(legacySwapsBoxName), isFalse);

      // Delete the migrated swap from Drift and re-run migration: it must not
      // be resurrected from the retained Hive box.
      await repository.deleteSwap('valid-swap');
      final LegacyHtlcSwapsMigrationResult secondRun = await migrator
          .migrateIfNeeded(
            walletBaseAddress: walletBaseAddress,
            encryptionKey: encryptionKey,
          );

      expect(secondRun.migratedCount, 0);
      expect(secondRun.failedCount, 2);
      expect(secondRun.deletedLegacyBoxes, isFalse);
      expect(await repository.getSwapById('valid-swap'), isNull);
    },
  );

  test('keeps legacy box, does not throw, and never logs secret preimage when '
      'Drift insert fails', () async {
    const String secretPreimage = 'ultra-secret-htlc-preimage-0123456789';
    final Box<dynamic> swapsBox = await Hive.openBox<dynamic>(
      legacySwapsBoxName,
      encryptionCipher: HiveAesCipher(encryptionKey),
      path: temporaryDirectory.path,
    );
    await swapsBox.put(
      'swap-secret',
      jsonEncode(
        _buildLegacySwapJson(
          id: 'swap-secret',
          chainId: 1,
          state: 'active',
          startTime: 300,
          preimage: secretPreimage,
        ),
      ),
    );
    await swapsBox.close();

    final _MockRepository failingRepository = _MockRepository();
    when(() => failingRepository.storeMissingSwaps(any())).thenThrow(
      SqliteException(
        extendedResultCode: 13,
        message: 'database or disk is full',
        causingStatement: 'INSERT OR IGNORE INTO htlc_swaps VALUES (?)',
        parametersToStatement: <Object?>[secretPreimage],
      ),
    );

    final List<LogRecord> logs = <LogRecord>[];
    final Logger testLogger = Logger.detached('test_preimage_redaction')
      ..level = Level.ALL;
    final StreamSubscription<LogRecord> subscription = testLogger.onRecord
        .listen(logs.add);
    addTearDown(subscription.cancel);

    final LegacyHtlcSwapsMigrator failingMigrator = LegacyHtlcSwapsMigrator(
      swapRepository: failingRepository,
      hiveDirectoryPath: temporaryDirectory.path,
      logger: testLogger,
    );

    final LegacyHtlcSwapsMigrationResult result = await failingMigrator
        .migrateIfNeeded(
          walletBaseAddress: walletBaseAddress,
          encryptionKey: encryptionKey,
        );

    expect(result.migratedCount, 0);
    expect(result.failedCount, 1);
    expect(result.deletedLegacyBoxes, isFalse);
    expect(
      await Hive.boxExists(legacySwapsBoxName, path: temporaryDirectory.path),
      isTrue,
    );
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

  test(
    'preserves migratedCount and leaves box intact when deleteFromDisk fails',
    () async {
      final _MockHive mockHive = _MockHive();
      final _MockBox mockBox = _MockBox();

      when(() => mockHive.isBoxOpen(legacySwapsBoxName)).thenReturn(false);
      when(
        () => mockHive.boxExists(
          legacySwapsBoxName,
          path: temporaryDirectory.path,
        ),
      ).thenAnswer((_) async => true);
      when(
        () => mockHive.openBox<dynamic>(
          legacySwapsBoxName,
          encryptionCipher: any(named: 'encryptionCipher'),
          path: temporaryDirectory.path,
        ),
      ).thenAnswer((_) async => mockBox);
      when(mockBox.toMap).thenReturn(<dynamic, dynamic>{
        'swap-1': jsonEncode(
          _buildLegacySwapJson(
            id: 'swap-1',
            chainId: 1,
            state: 'active',
            startTime: 250,
          ),
        ),
      });
      when(() => mockBox.deleteAll(any())).thenAnswer((_) async {});
      when(
        mockBox.deleteFromDisk,
      ).thenThrow(const FileSystemException('file locked'));
      when(() => mockBox.isOpen).thenReturn(true);
      when(mockBox.close).thenAnswer((_) async {});

      final LegacyHtlcSwapsMigrator mockMigrator = LegacyHtlcSwapsMigrator(
        swapRepository: repository,
        hive: mockHive,
        hiveDirectoryPath: temporaryDirectory.path,
      );

      final LegacyHtlcSwapsMigrationResult result = await mockMigrator
          .migrateIfNeeded(
            walletBaseAddress: walletBaseAddress,
            encryptionKey: encryptionKey,
          );

      expect(result.migratedCount, 1);
      expect(result.failedCount, 0);
      expect(result.deletedLegacyBoxes, isFalse);
      expect(await repository.getSwapById('swap-1'), isNotNull);
      verify(() => mockBox.deleteAll(<dynamic>['swap-1'])).called(1);
      verify(mockBox.close).called(1);
    },
  );

  test(
    'does not close a legacy box that was already open before migration',
    () async {
      final Box<dynamic> alreadyOpenBox = await Hive.openBox<dynamic>(
        legacySwapsBoxName,
        encryptionCipher: HiveAesCipher(encryptionKey),
        path: temporaryDirectory.path,
      );
      await alreadyOpenBox.put('bad-entry', '{corrupt');

      final LegacyHtlcSwapsMigrationResult result = await migrator
          .migrateIfNeeded(
            walletBaseAddress: walletBaseAddress,
            encryptionKey: encryptionKey,
          );

      expect(result.migratedCount, 0);
      expect(result.failedCount, 1);
      expect(result.deletedLegacyBoxes, isFalse);
      expect(alreadyOpenBox.isOpen, isTrue);
      await alreadyOpenBox.close();
    },
  );

  test('does not throw when Hive.boxExists fails before opening box', () async {
    final _MockHive mockHive = _MockHive();
    when(() => mockHive.isBoxOpen(legacySwapsBoxName)).thenReturn(false);
    when(
      () =>
          mockHive.boxExists(legacySwapsBoxName, path: temporaryDirectory.path),
    ).thenThrow(const FileSystemException('permission denied'));

    final LegacyHtlcSwapsMigrator mockMigrator = LegacyHtlcSwapsMigrator(
      swapRepository: repository,
      hive: mockHive,
      hiveDirectoryPath: temporaryDirectory.path,
    );

    final LegacyHtlcSwapsMigrationResult result = await mockMigrator
        .migrateIfNeeded(
          walletBaseAddress: walletBaseAddress,
          encryptionKey: encryptionKey,
        );

    expect(result.migratedCount, 0);
    expect(result.failedCount, 1);
    expect(result.deletedLegacyBoxes, isFalse);
  });

  test(
    'does not throw or delete legacy box when decryption key does not match',
    () async {
      final Box<dynamic> swapsBox = await Hive.openBox<dynamic>(
        legacySwapsBoxName,
        encryptionCipher: HiveAesCipher(wrongEncryptionKey),
        path: temporaryDirectory.path,
      );
      await swapsBox.put(
        'locked-swap',
        jsonEncode(
          _buildLegacySwapJson(
            id: 'locked-swap',
            chainId: 1,
            state: 'active',
            startTime: 300,
          ),
        ),
      );
      await swapsBox.close();

      final LegacyHtlcSwapsMigrationResult result = await migrator
          .migrateIfNeeded(
            walletBaseAddress: walletBaseAddress,
            encryptionKey: encryptionKey,
          );

      expect(result.migratedCount, 0);
      expect(result.failedCount, greaterThan(0));
      expect(result.deletedLegacyBoxes, isFalse);
      expect(await repository.getAllSwaps(), isEmpty);
      expect(
        await Hive.boxExists(legacySwapsBoxName, path: temporaryDirectory.path),
        isTrue,
      );

      final Box<dynamic> verifyIntactBox = await Hive.openBox<dynamic>(
        legacySwapsBoxName,
        encryptionCipher: HiveAesCipher(wrongEncryptionKey),
        path: temporaryDirectory.path,
      );
      expect(verifyIntactBox.containsKey('locked-swap'), isTrue);
      await verifyIntactBox.close();
    },
  );

  test(
    'removes orphaned legacy checkpoint box when swaps box is absent',
    () async {
      final Box<dynamic> checkpointBox = await Hive.openBox<dynamic>(
        kLastCheckedHtlcBlockBox,
        encryptionCipher: HiveAesCipher(encryptionKey),
        path: temporaryDirectory.path,
      );
      await checkpointBox.put(kLastCheckedHtlcBlockKey, 99);
      await checkpointBox.close();

      final LegacyHtlcSwapsMigrationResult result = await migrator
          .migrateIfNeeded(
            walletBaseAddress: walletBaseAddress,
            encryptionKey: encryptionKey,
          );

      expect(result.migratedCount, 0);
      expect(result.failedCount, 0);
      expect(result.deletedLegacyBoxes, isTrue);
      expect(
        await Hive.boxExists(
          kLastCheckedHtlcBlockBox,
          path: temporaryDirectory.path,
        ),
        isFalse,
      );
    },
  );

  test('deleteLegacyBoxesOnReset deletes all htlc_swaps_box_* files while '
      'preserving unrelated cache files', () async {
    final File swapHive = File(
      '${temporaryDirectory.path}/${kHtlcSwapsBox}_$walletBaseAddress.hive',
    )..writeAsStringSync('legacy-swap-data');
    final File swapCompact = File(
      '${temporaryDirectory.path}/${kHtlcSwapsBox}_$walletBaseAddress.hivec',
    )..writeAsStringSync('legacy-compact-data');
    final File swapLock = File(
      '${temporaryDirectory.path}/${kHtlcSwapsBox}_$walletBaseAddress.lock',
    )..writeAsStringSync('');
    final File otherBox = File(
      '${temporaryDirectory.path}/$kFavoriteTokensBox.hive',
    )..writeAsStringSync('favorites');

    await migrator.deleteLegacyBoxesOnReset();

    expect(swapHive.existsSync(), isFalse);
    expect(swapCompact.existsSync(), isFalse);
    expect(swapLock.existsSync(), isFalse);
    expect(otherBox.existsSync(), isTrue);
  });
}

Map<String, dynamic> _buildLegacySwapJson({
  required String id,
  required int chainId,
  required String state,
  required int startTime,
  String? preimage,
  bool includeToToken = true,
}) => <String, dynamic>{
  'id': id,
  'chainId': chainId,
  'type': 'native',
  'mode': 'htlc',
  'direction': 'incoming',
  'selfAddress': 'z1qqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqqsggv2f',
  'counterpartyAddress': 'z1qqjnwjjpnue8xmmpanz6csze6tcmtzzdtfsww7',
  'fromAmount': '1000',
  'fromTokenStandard': kZnnCoin.tokenStandard.toString(),
  'fromSymbol': 'ZNN',
  'fromDecimals': 8,
  'fromChain': 'nom',
  'toChain': 'nom',
  'startTime': startTime,
  'state': state,
  'toAmount': includeToToken ? '2000' : null,
  'toTokenStandard': includeToToken ? kQsrCoin.tokenStandard.toString() : null,
  'toSymbol': includeToToken ? 'QSR' : null,
  'toDecimals': includeToToken ? 8 : null,
  'hashLock': 'hash-lock-$id',
  'initialHtlcId': 'initial-htlc-$id',
  'initialHtlcExpirationTime': 1000,
  'hashType': htlcHashTypeSha3,
  'counterHtlcId': includeToToken ? 'counter-htlc-$id' : null,
  'counterHtlcExpirationTime': includeToToken ? 900 : null,
  'preimage': preimage,
};
