@Tags(<String>['bend'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart'
    show CouldNotRollBackException, DriftWrappedException;
import 'package:flutter_test/flutter_test.dart';
import 'package:json_rpc_2/json_rpc_2.dart' show RpcException;
import 'package:mocktail/mocktail.dart';
import 'package:sqlite3/sqlite3.dart';
import 'package:zenon_syrius_wallet_flutter/l10n/app_localizations_en.dart';
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/change_wallet_password/change_wallet_password.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/initial_htlc_validation/initial_htlc_validation.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/node_sync_status/services/node_sync_monitor.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/notifications/notifications.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/p2p_swap/p2p_swap.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/p2p_swaps/data/htlc_swap_local_storage_api.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/p2p_swaps/data/htlc_swap_repository.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/p2p_swaps/data/htlc_swaps_database.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/p2p_swaps/data/legacy_htlc_swaps_migrator.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/p2p_swaps/services/htlc_swap_auto_unlock_service.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/p2p_swaps/services/htlc_swap_sync_service.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/p2p_swaps/services/htlc_swap_unlock_service.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/p2p_swaps/utils/swap_storage_error_sanitizer.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/reclaim_deposit/reclaim_deposit.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/exceptions/exceptions.dart';
import 'package:zenon_syrius_wallet_flutter/utils/account_block_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/address_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/format_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:zenon_syrius_wallet_flutter/utils/wallet_file.dart';
import 'package:zenon_syrius_wallet_flutter/utils/zts_utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

import 'bend_conformance_helper.dart';

const String _kDomain = 'p2p_htlc';
const int _kSecondsPerMinute = Duration.secondsPerMinute;

class _MockZenon extends Mock implements Zenon {}

class _MockEmbeddedApi extends Mock implements EmbeddedApi {}

class _MockHtlcApi extends Mock implements HtlcApi {}

class _MockAccountBlockUtils extends Mock implements AccountBlockUtils {}

class _MockZenonAddressUtils extends Mock implements ZenonAddressUtils {}

class _MockWalletFile extends Mock implements WalletFile {}

class _MockHtlcSwapSyncService extends Mock implements HtlcSwapSyncService {}

class _MockHtlcSwapLocalStorageApi extends Mock
    implements HtlcSwapLocalStorageApi {}

class _MockLegacyHtlcSwapsMigrator extends Mock
    implements LegacyHtlcSwapsMigrator {}

class _MockNodeSyncMonitor extends Mock implements NodeSyncMonitor {}

class _MockNotificationsBloc extends Mock implements NotificationsBloc {}

class _MockHtlcSwapUnlockService extends Mock
    implements HtlcSwapUnlockService {}

class _FakeWalletNotification extends Fake implements WalletNotification {}

class _FakeAccountBlockTemplate extends Fake implements AccountBlockTemplate {}

class _FakeHtlcSwapEntry extends Fake implements HtlcSwapEntry {}

class _FakeWalletAccount implements WalletAccount {
  _FakeWalletAccount(this._address);

  final Address _address;

  @override
  Future<Address> getAddress() async => _address;

  @override
  Future<List<int>> getPublicKey() => throw UnimplementedError();

  @override
  Future<List<int>> sign(List<int> message) => throw UnimplementedError();

  @override
  Future<List<int>> signTx(AccountBlockTemplate tx) =>
      throw UnimplementedError();
}

class _FakeWallet implements Wallet {
  _FakeWallet(this._addressForIndex);

  final Address Function(int index) _addressForIndex;

  @override
  Future<WalletAccount> getAccount([int accountIndex = 0]) async =>
      _FakeWalletAccount(_addressForIndex(accountIndex));
}

class _InMemoryWalletFile extends WalletFile {
  _InMemoryWalletFile(this._wallet, {required this._isHardwareWallet})
    : super('in-memory-bend-test');

  final Wallet _wallet;
  final bool _isHardwareWallet;

  @override
  String get walletType => _isHardwareWallet ? 'ledger' : keyStoreWalletType;

  @override
  bool get isOpen => true;

  @override
  bool get isHardwareWallet => _isHardwareWallet;

  @override
  Future<T> access<T>(Future<T> Function(Wallet) accessSection) =>
      accessSection(_wallet);

  @override
  Future<void> close() async {}
}

Address _addr(int seed) {
  final List<int> key = List<int>.filled(32, 0);
  key[0] = seed & 0xff;
  key[1] = (seed >> 8) & 0xff;
  key[31] = (seed * 31 + 7) & 0xff;
  return Address.fromPublicKey(key);
}

Hash _hash(int seed) => Hash.digest(<int>[seed & 0xff, (seed >> 8) & 0xff, 99]);

HtlcSwap _buildSwap({
  required P2pSwapDirection direction,
  required int chainId,
  required int initialExpSec,
  required bool hasCounter,
  P2pSwapState state = P2pSwapState.active,
  String? preimage,
  Address? selfAddr,
}) {
  final Hash initId = _hash(10);
  final Hash counterId = _hash(20);
  final List<int> secretBytes = <int>[1, 2, 3, 4];
  final Address self = selfAddr ?? _addr(1);
  return HtlcSwap(
    hashLock: Hash.digest(secretBytes).toString(),
    initialHtlcId: initId.toString(),
    initialHtlcExpirationTime: initialExpSec,
    hashType: htlcHashTypeSha3,
    id: initId.toString(),
    chainId: chainId,
    type: P2pSwapType.native,
    direction: direction,
    selfAddress: self.toString(),
    counterpartyAddress: _addr(2).toString(),
    fromAmount: BigInt.from(100),
    fromToken: kZnnCoin,
    fromChain: P2pSwapChain.nom,
    toChain: P2pSwapChain.nom,
    startTime: 1000,
    state: state,
    counterHtlcId: hasCounter ? counterId.toString() : null,
    counterHtlcExpirationTime: hasCounter ? initialExpSec : null,
    preimage: preimage ?? FormatUtils.encodeHexString(secretBytes),
  );
}

HtlcInfo _buildHtlcInfo({
  required Hash id,
  required Address timeLocked,
  required Address hashLocked,
  required int expirationTimeSec,
  required List<int> hashLockBytes,
}) {
  return HtlcInfo(
    id: id,
    timeLocked: timeLocked,
    hashLocked: hashLocked,
    tokenStandard: znnZts,
    amount: BigInt.from(100),
    expirationTime: expirationTimeSec,
    hashType: htlcHashTypeSha3,
    keyMaxSize: htlcPreimageMaxLength,
    hashLock: hashLockBytes,
  );
}

Future<bool> _evalUnlockTiming({
  required int expSec,
  required int nowSec,
}) async {
  final _MockZenon zenon = _MockZenon();
  final _MockEmbeddedApi embedded = _MockEmbeddedApi();
  final _MockHtlcApi htlcApi = _MockHtlcApi();
  final _MockAccountBlockUtils blockUtils = _MockAccountBlockUtils();
  final AccountBlockTemplate txTemplate = AccountBlockTemplate(blockType: 2);
  final Address self = _addr(7);
  final List<int> preimage = <int>[1, 2, 3, 4];
  final List<int> hashLockBytes = Hash.digest(preimage).getBytes()!;
  final HtlcSwap swap = _buildSwap(
    direction: P2pSwapDirection.incoming,
    chainId: 1,
    initialExpSec: expSec,
    hasCounter: true,
    preimage: FormatUtils.encodeHexString(preimage),
    selfAddr: self,
  );
  final Hash htlcId = Hash.parse(swap.initialHtlcId);

  final List<String?> savedAddresses = List<String?>.of(kDefaultAddressList);
  kDefaultAddressList
    ..clear()
    ..add(self.toString());

  try {
    when(() => zenon.embedded).thenReturn(embedded);
    when(() => embedded.htlc).thenReturn(htlcApi);
    when(() => htlcApi.getById(htlcId)).thenAnswer(
      (_) async => _buildHtlcInfo(
        id: htlcId,
        timeLocked: _addr(2),
        hashLocked: self,
        expirationTimeSec: expSec,
        hashLockBytes: hashLockBytes,
      ),
    );
    when(() => htlcApi.unlock(htlcId, any())).thenReturn(txTemplate);
    when(
      () => blockUtils.createAccountBlock(
        txTemplate,
        'complete swap',
        address: self,
        waitForRequiredPlasma: true,
      ),
    ).thenAnswer((_) async => txTemplate);

    final HtlcSwapUnlockService service = HtlcSwapUnlockService(
      accountBlockUtils: blockUtils,
      zenon: zenon,
      unixTimeProvider: () => nowSec,
    );

    try {
      await service.unlock(swap);
      return true;
    } on LocalizedSyriusException {
      return false;
    }
  } finally {
    kDefaultAddressList
      ..clear()
      ..addAll(savedAddresses);
  }
}

Future<bool> _evalSqlcipherKeyValid({
  required int keyLen,
  required bool bytesOk,
}) async {
  final List<int> key = List<int>.filled(keyLen, 0x42);
  if (!bytesOk && key.isNotEmpty) {
    key[0] = 256;
  }
  final File tempFile = File(
    '${Directory.systemTemp.path}/syrius_bend_keycheck_$keyLen.sqlite',
  );
  try {
    final HtlcSwapsDatabase db = HtlcSwapsDatabase.encrypted(tempFile, key);
    await db.close();
    if (tempFile.existsSync()) {
      tempFile.deleteSync();
    }
    return true;
  } on Object catch (error) {
    if (error is ArgumentError) {
      return false;
    }
    rethrow;
  }
}

Future<Map<String, Object>> _evalChangePasswordTxn({
  required bool rekeyOk,
  required bool walletPwdOk,
}) async {
  const String currentPwd = 'OldPassword1!';
  const String newPwd = 'NewPassword2@';
  final List<int> oldKey = Crypto.digest(utf8.encode(currentPwd));
  final List<int> newKey = Crypto.digest(utf8.encode(newPwd));

  final _MockWalletFile mockWallet = _MockWalletFile();
  final _MockHtlcSwapSyncService mockSync = _MockHtlcSwapSyncService();
  final _MockHtlcSwapLocalStorageApi mockStorage =
      _MockHtlcSwapLocalStorageApi();
  final _MockLegacyHtlcSwapsMigrator mockMigrator =
      _MockLegacyHtlcSwapsMigrator();

  bool syncStopped = false;
  bool syncRestarted = false;
  bool committed = false;
  bool rolledBack = false;

  when(mockSync.stop).thenAnswer((_) async {
    syncStopped = true;
  });
  when(mockSync.start).thenAnswer((_) {
    if (syncStopped) {
      syncRestarted = true;
    }
  });
  when(
    () => mockMigrator.migrateIfNeeded(
      walletBaseAddress: any(named: 'walletBaseAddress'),
      encryptionKey: any(named: 'encryptionKey'),
    ),
  ).thenAnswer(
    (_) async => const LegacyHtlcSwapsMigrationResult(
      migratedCount: 0,
      failedCount: 0,
      deletedLegacyBoxes: true,
    ),
  );
  when(
    () => mockStorage.beginRekey(
      oldEncryptionKey: oldKey,
      newEncryptionKey: newKey,
    ),
  ).thenAnswer((_) async {
    if (!rekeyOk) {
      throw StateError('beginRekey failed');
    }
  });
  when(mockStorage.commitRekey).thenAnswer((_) async {
    committed = true;
  });
  when(() => mockStorage.rollbackRekey(oldKey)).thenAnswer((_) async {
    rolledBack = true;
  });
  when(() => mockWallet.changePassword(currentPwd, newPwd)).thenAnswer((
    _,
  ) async {
    if (!walletPwdOk) {
      throw StateError('changePassword failed');
    }
  });

  final ChangeWalletPasswordBloc bloc = ChangeWalletPasswordBloc(
    decryptWalletFile: (String _, String _) async => mockWallet,
    walletPathProvider: () => '/tmp/bend-wallet',
    walletFileProvider: () => mockWallet,
    walletBaseAddressProvider: () => _addr(1).toString(),
    syncService: mockSync,
    storageApi: mockStorage,
    legacyMigrator: mockMigrator,
    reportError: (Object _, String _) async {},
  );

  final Future<ChangeWalletPasswordState> terminalFuture = bloc.stream
      .firstWhere(
        (ChangeWalletPasswordState s) =>
            s is ChangeWalletPasswordSuccess ||
            s is ChangeWalletPasswordFailure,
      );

  bloc.add(
    const ChangeWalletPasswordSubmitted(
      currentPassword: currentPwd,
      newPassword: newPwd,
      decryptErrorTitle: 'decrypt',
      changePasswordErrorTitle: 'change',
    ),
  );

  final ChangeWalletPasswordState terminal = await terminalFuture;
  await bloc.close();

  return <String, Object>{
    'succeeded': terminal is ChangeWalletPasswordSuccess,
    'committed': committed,
    'rolled_back': rolledBack,
    'sync_restarted': syncRestarted,
  };
}

Future<Map<String, Object>> _evalReclaim({
  required bool inWallet,
  required bool hasWallet,
  required bool isHw,
  required int walletLen,
  required int? matchIdx,
  required int expMin,
  required int nowMin,
}) async {
  final _MockZenon zenon = _MockZenon();
  final _MockEmbeddedApi embedded = _MockEmbeddedApi();
  final _MockHtlcApi htlcApi = _MockHtlcApi();
  final _MockAccountBlockUtils blockUtils = _MockAccountBlockUtils();
  final _MockZenonAddressUtils addressUtils = _MockZenonAddressUtils();
  final AccountBlockTemplate txTemplate = AccountBlockTemplate(blockType: 2);
  final Hash depositId = _hash(55);

  final List<String?> walletAddresses = <String?>[
    for (int i = 0; i < walletLen; i += 1) _addr(100 + i).toString(),
  ];

  final Address targetAddress;
  if (inWallet && walletLen > 0) {
    targetAddress = _addr(100);
  } else if (matchIdx != null) {
    targetAddress = _addr(100 + matchIdx);
  } else {
    targetAddress = _addr(9999);
  }

  int derivedCount = 0;
  final WalletFile? walletFile = hasWallet
      ? _InMemoryWalletFile(
          _FakeWallet((int index) => _addr(100 + index)),
          isHardwareWallet: isHw,
        )
      : null;

  when(() => zenon.embedded).thenReturn(embedded);
  when(() => embedded.htlc).thenReturn(htlcApi);
  when(() => htlcApi.getById(depositId)).thenAnswer(
    (_) async => _buildHtlcInfo(
      id: depositId,
      timeLocked: targetAddress,
      hashLocked: _addr(2),
      expirationTimeSec: expMin * _kSecondsPerMinute,
      hashLockBytes: Hash.digest(<int>[1, 2, 3]).getBytes()!,
    ),
  );
  when(() => htlcApi.reclaim(depositId)).thenReturn(txTemplate);
  when(
    () => blockUtils.createAccountBlock(
      txTemplate,
      'reclaim deposit',
      address: targetAddress,
      waitForRequiredPlasma: true,
    ),
  ).thenAnswer((_) async => txTemplate);
  when(addressUtils.refreshBalance).thenReturn(null);

  final ReclaimDepositBloc bloc = ReclaimDepositBloc(
    accountBlockUtils: blockUtils,
    zenon: zenon,
    zenonAddressUtils: addressUtils,
    walletAddressesProvider: () => walletAddresses,
    walletFileProvider: () => walletFile,
    generateAddresses: (int count) async {
      derivedCount += count;
      final int start = walletAddresses.length;
      for (int i = 0; i < count; i += 1) {
        walletAddresses.add(_addr(100 + start + i).toString());
      }
    },
    unixTimeProvider: () => nowMin * _kSecondsPerMinute,
  );

  final Future<ReclaimDepositState> terminalFuture = bloc.stream.firstWhere(
    (ReclaimDepositState s) =>
        s is ReclaimDepositDone || s is ReclaimDepositFailure,
  );

  bloc.add(ReclaimDepositRequested(depositId: depositId));
  final ReclaimDepositState terminal = await terminalFuture;
  await bloc.close();

  return <String, Object>{
    'ok': terminal is ReclaimDepositDone,
    'derived_count': derivedCount,
  };
}

Future<Map<String, Object>> _evalAutoUnlockArbiter({
  required bool walletOpen,
  required bool nodeSynced,
  required int firstMin,
  required int secondMin,
}) async {
  final WalletFile? savedWallet = kWalletFile;
  kWalletFile = walletOpen ? _MockWalletFile() : null;

  try {
    final _MockNodeSyncMonitor syncMonitor = _MockNodeSyncMonitor();
    final _MockNotificationsBloc notificationsBloc = _MockNotificationsBloc();
    final _MockHtlcSwapUnlockService unlockService =
        _MockHtlcSwapUnlockService();
    final AccountBlockTemplate txTemplate = AccountBlockTemplate(blockType: 2);
    final HtlcSwap swap = _buildSwap(
      direction: P2pSwapDirection.incoming,
      chainId: 1,
      initialExpSec: 999999,
      hasCounter: true,
    );

    int unlockCalls = 0;
    DateTime currentNow = DateTime.utc(2026, 1, 1, 0, firstMin);

    when(syncMonitor.isNodeSynced).thenAnswer((_) async => nodeSynced);
    when(() => notificationsBloc.addNotification(any())).thenAnswer(
      (_) async {},
    );
    when(() => unlockService.unlock(swap)).thenAnswer((_) async {
      unlockCalls += 1;
      return txTemplate;
    });

    final HtlcSwapAutoUnlockService service = HtlcSwapAutoUnlockService(
      notificationsBloc: notificationsBloc,
      syncMonitor: syncMonitor,
      unlockService: unlockService,
      now: () => currentNow,
      l10nProvider: AppLocalizationsEn.new,
    );

    await service.unlockNext(<HtlcSwap>[swap]);
    final bool firstStarted = unlockCalls == 1;

    currentNow = DateTime.utc(2026, 1, 1, 0, secondMin);
    final int beforeSecond = unlockCalls;
    await service.unlockNext(<HtlcSwap>[swap]);
    final bool secondStarted = unlockCalls > beforeSecond;

    return <String, Object>{
      'first_started': firstStarted,
      'second_started': secondStarted,
    };
  } finally {
    kWalletFile = savedWallet;
  }
}

Map<String, Object> _parseSanitizedSummary(String summary) {
  final RegExp sqliteRe = RegExp(r'^(.+) \(code=(-?\d+)\)$');
  final RegExpMatch? match = sqliteRe.firstMatch(summary);
  if (match != null) {
    final String prefix = match.group(1)!;
    final int code = int.parse(match.group(2)!);
    if (prefix == 'RpcException') {
      return <String, Object>{'kind': 'rpc', 'wrapped': false, 'code': code};
    }
    if (prefix.contains('SqliteException')) {
      return <String, Object>{
        'kind': 'sqlite',
        'wrapped': prefix.contains(' -> '),
        'code': code,
      };
    }
  }
  return <String, Object>{'kind': 'type_only', 'wrapped': false, 'code': 0};
}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeWalletNotification());
    registerFallbackValue(_FakeAccountBlockTemplate());
    registerFallbackValue(_FakeHtlcSwapEntry());
    registerFallbackValue(emptyAddress);
    registerFallbackValue(<int>[]);
    registerFallbackValue(<String>[]);
  });

  group('Bend conformance: $_kDomain', () {
    test(
      'all Bend oracle vectors match Syrius P2P HTLC production logic',
      () async {
        final List<Map<String, dynamic>> vectors = loadBendVectors(_kDomain);
        final Set<String> seenOps = <String>{};

        for (final Map<String, dynamic> vector in vectors) {
          final String caseId = requireCaseId(vector);
          final String op = requireOp(vector);
          final Map<String, dynamic> args = requireArgs(vector);
          final Object? expected = vector['expected'];
          seenOps.add(op);

          switch (op) {
            case 'join_window':
              final int expMin = requireInt(args, 'exp_min');
              final int nowMin = requireInt(args, 'now_min');
              final int expSec = expMin * _kSecondsPerMinute;
              final int nowSec = nowMin * _kSecondsPerMinute;

              final HtlcWindowDecision win = evaluateHtlcJoinWindow(
                expirationTime: expSec,
                unixTime: nowSec,
              );
              final bool canReclaim = evaluateHtlcExpiration(
                expirationTime: expSec,
                unixTime: nowSec,
              );
              final bool canUnlock = await _evalUnlockTiming(
                expSec: expSec,
                nowSec: nowSec,
              );
              final bool exceedsMaxDuration = exceedsMaxInitialHtlcDuration(
                Duration(seconds: (expMin - nowMin) * _kSecondsPerMinute),
              );
              if (win.canSafelyJoin) {
                expect(
                  win.minutesLeftToJoin,
                  equals(
                    expMin -
                        nowMin -
                        (kDefaultMinSafeJoinSeconds ~/ _kSecondsPerMinute),
                  ),
                );
              }

              expectBendMatch(
                domain: _kDomain,
                caseId: caseId,
                actual: <String, Object>{
                  'can_safely_join': win.canSafelyJoin,
                  'can_reclaim': canReclaim,
                  'can_unlock': canUnlock,
                  'exceeds_max_duration': exceedsMaxDuration,
                },
                expected: expected,
              );

            case 'funded_htlc_role':
              final String dirStr = requireString(args, 'direction');
              final bool hasCounter = requireBool(args, 'has_counter');
              final P2pSwapDirection dir = switch (dirStr) {
                'outgoing' => P2pSwapDirection.outgoing,
                'incoming' => P2pSwapDirection.incoming,
                _ => fail('Unknown direction "$dirStr"'),
              };
              final HtlcSwap swap = _buildSwap(
                direction: dir,
                chainId: 1,
                initialExpSec: 30000,
                hasCounter: hasCounter,
              );
              final ({int expirationTime, String id})? funded = swap.fundedHtlc;
              final String actualRole;
              if (funded == null) {
                actualRole = 'none';
              } else if (funded.id == swap.initialHtlcId) {
                actualRole = 'initial';
              } else if (funded.id == swap.counterHtlcId) {
                actualRole = 'counter';
              } else {
                actualRole = 'other';
              }
              expectBendMatch(
                domain: _kDomain,
                caseId: caseId,
                actual: actualRole,
                expected: expected,
              );

            case 'sanitize_error':
              final String kind = requireString(args, 'kind');
              final int wrapDepth = requireInt(args, 'wrap_depth');
              final String wrapKind = requireString(args, 'wrap_kind');
              final int code = requireInt(args, 'code');
              final int secretTag = requireInt(args, 'secret_tag');
              final String secret = 'SECRET_PREIMAGE_$secretTag';

              Object error = switch (kind) {
                'sqlite' => SqliteException(
                  extendedResultCode: code,
                  message: 'constraint failed: $secret',
                  causingStatement: 'INSERT INTO htlc_swaps VALUES (?)',
                  parametersToStatement: <Object?>[secret],
                ),
                'rpc' => RpcException(
                  code,
                  'rpc error: $secret',
                  data: <String, Object?>{'preimage': secret},
                ),
                'other' => StateError('unexpected: $secret'),
                _ => fail('Unknown error kind "$kind"'),
              };

              for (int d = 0; d < wrapDepth; d += 1) {
                error = switch (wrapKind) {
                  'drift' => DriftWrappedException(
                    message: 'wrap_$d $secret',
                    cause: error,
                  ),
                  'rollback' => CouldNotRollBackException(
                    error,
                    StackTrace.empty,
                    StateError('rollback_$d $secret'),
                  ),
                  _ => fail('Unknown wrap_kind "$wrapKind"'),
                };
              }

              final String summary = formatSafeSwapErrorSummary(error);
              final RedactedSwapError redacted = sanitizeSwapErrorForLogging(
                error,
              );
              expect(summary.contains(secret), isFalse);
              expect(redacted.toString().contains(secret), isFalse);
              expectBendMatch(
                domain: _kDomain,
                caseId: caseId,
                actual: _parseSanitizedSummary(summary),
                expected: expected,
              );

            case 'sqlcipher_key_valid':
              final int keyLen = requireInt(args, 'key_len');
              final bool bytesOk = requireBool(args, 'bytes_ok');
              final bool actual = await _evalSqlcipherKeyValid(
                keyLen: keyLen,
                bytesOk: bytesOk,
              );
              expectBendMatch(
                domain: _kDomain,
                caseId: caseId,
                actual: actual,
                expected: expected,
              );

            case 'change_password_txn':
              final bool rekeyOk = requireBool(args, 'rekey_ok');
              final bool walletPwdOk = requireBool(args, 'wallet_pwd_ok');
              final Map<String, Object> actual = await _evalChangePasswordTxn(
                rekeyOk: rekeyOk,
                walletPwdOk: walletPwdOk,
              );
              expectBendMatch(
                domain: _kDomain,
                caseId: caseId,
                actual: actual,
                expected: expected,
              );

            case 'reclaim_evaluate':
              final bool inWallet = requireBool(args, 'in_wallet');
              final bool hasWallet = requireBool(args, 'has_wallet');
              final bool isHw = requireBool(args, 'is_hw');
              final int walletLen = requireInt(args, 'wallet_len');
              final Object? rawMatch = args['match_idx'];
              final int? matchIdx = rawMatch == null
                  ? null
                  : requireInt(args, 'match_idx');
              final int expMin = requireInt(args, 'exp_min');
              final int nowMin = requireInt(args, 'now_min');
              final Map<String, Object> actual = await _evalReclaim(
                inWallet: inWallet,
                hasWallet: hasWallet,
                isHw: isHw,
                walletLen: walletLen,
                matchIdx: matchIdx,
                expMin: expMin,
                nowMin: nowMin,
              );
              expectBendMatch(
                domain: _kDomain,
                caseId: caseId,
                actual: actual,
                expected: expected,
              );

            case 'can_delete_swap':
              final String stateName = requireString(args, 'state');
              final _MockHtlcSwapLocalStorageApi mockApi =
                  _MockHtlcSwapLocalStorageApi();
              List<String> deletedStates = <String>[];
              when(
                () => mockApi.deleteSwapEntriesByState(any(), any()),
              ).thenAnswer((Invocation inv) async {
                deletedStates = inv.positionalArguments[1] as List<String>;
              });
              final HtlcSwapRepository repo = HtlcSwapRepository(
                chainIdProvider: () => 1,
                dataProvider: mockApi,
              );
              await repo.deleteInactiveSwaps();
              expectBendMatch(
                domain: _kDomain,
                caseId: caseId,
                actual: deletedStates.contains(stateName),
                expected: expected,
              );

            case 'auto_unlock_arbiter':
              final bool walletOpen = requireBool(args, 'wallet_open');
              final bool nodeSynced = requireBool(args, 'node_synced');
              final int firstMin = requireInt(args, 'first_min');
              final int secondMin = requireInt(args, 'second_min');
              final Map<String, Object> actual = await _evalAutoUnlockArbiter(
                walletOpen: walletOpen,
                nodeSynced: nodeSynced,
                firstMin: firstMin,
                secondMin: secondMin,
              );
              expectBendMatch(
                domain: _kDomain,
                caseId: caseId,
                actual: actual,
                expected: expected,
              );

            case 'parallel_swap_safety_check':
              final int expMin = requireInt(args, 'exp_min');
              final int nowMin = requireInt(args, 'now_min');
              final int keyLen = requireInt(args, 'key_len');
              final bool bytesOk = requireBool(args, 'bytes_ok');
              final int activeChain = requireInt(args, 'active_chain');
              final Object? rawUpdatedChain = args['updated_chain'];
              final int? updatedChain = rawUpdatedChain == null
                  ? null
                  : requireInt(args, 'updated_chain');

              final HtlcWindowDecision win = evaluateHtlcJoinWindow(
                expirationTime: expMin * _kSecondsPerMinute,
                unixTime: nowMin * _kSecondsPerMinute,
              );
              final bool keyValid = await _evalSqlcipherKeyValid(
                keyLen: keyLen,
                bytesOk: bytesOk,
              );

              final _MockHtlcSwapLocalStorageApi mockApi =
                  _MockHtlcSwapLocalStorageApi();
              when(
                () => mockApi.writeProcessedHtlcBlock(
                  chainId: any(named: 'chainId'),
                  height: any(named: 'height'),
                  updatedEntry: any(named: 'updatedEntry'),
                  maximumStoredSwaps: any(named: 'maximumStoredSwaps'),
                  prunableStates: any(named: 'prunableStates'),
                ),
              ).thenAnswer((_) async {});

              final HtlcSwapRepository repo = HtlcSwapRepository(
                chainIdProvider: () => activeChain,
                dataProvider: mockApi,
              );
              bool chainOk = true;
              try {
                await repo.storeProcessedHtlcBlock(
                  height: 10,
                  updatedSwap: updatedChain == null
                      ? null
                      : _buildSwap(
                          direction: P2pSwapDirection.outgoing,
                          chainId: updatedChain,
                          initialExpSec: expMin * _kSecondsPerMinute,
                          hasCounter: false,
                        ),
                );
              } on Object catch (error) {
                if (error is StateError) {
                  chainOk = false;
                } else {
                  rethrow;
                }
              }

              final bool remWithinMax =
                  !evaluateHtlcExpiration(
                    expirationTime: expMin * _kSecondsPerMinute,
                    unixTime: nowMin * _kSecondsPerMinute,
                  ) &&
                  !exceedsMaxInitialHtlcDuration(
                    Duration(seconds: win.remainingSeconds),
                  );

              expectBendMatch(
                domain: _kDomain,
                caseId: caseId,
                actual:
                    win.canSafelyJoin && remWithinMax && keyValid && chainOk,
                expected: expected,
              );

            default:
              fail('Unhandled Bend conformance op "$_kDomain/$op"');
          }
        }

        expect(
          seenOps,
          equals(<String>{
            'join_window',
            'funded_htlc_role',
            'sanitize_error',
            'sqlcipher_key_valid',
            'change_password_txn',
            'reclaim_evaluate',
            'can_delete_swap',
            'auto_unlock_arbiter',
            'parallel_swap_safety_check',
          }),
        );
      },
    );

    test('evaluateHtlcJoinWindow rounds partial minutes up (ceil)', () {
      final HtlcWindowDecision exactCutoff = evaluateHtlcJoinWindow(
        expirationTime: kDefaultMinSafeJoinSeconds,
        unixTime: 0,
      );
      expect(exactCutoff.canSafelyJoin, isTrue);
      expect(exactCutoff.minutesLeftToJoin, equals(0));

      final HtlcWindowDecision oneSecAboveZero = evaluateHtlcJoinWindow(
        expirationTime: kDefaultMinSafeJoinSeconds + 1,
        unixTime: 0,
      );
      expect(oneSecAboveZero.canSafelyJoin, isTrue);
      expect(oneSecAboveZero.minutesLeftToJoin, equals(1));

      final HtlcWindowDecision oneSecAboveMinute = evaluateHtlcJoinWindow(
        expirationTime: kDefaultMinSafeJoinSeconds + 61,
        unixTime: 0,
      );
      expect(oneSecAboveMinute.canSafelyJoin, isTrue);
      expect(oneSecAboveMinute.minutesLeftToJoin, equals(2));
    });
  }, skip: bendConformanceSkipReason);
}
