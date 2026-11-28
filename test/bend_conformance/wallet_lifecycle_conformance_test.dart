@Tags(<String>['bend'])
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hex/hex.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as path;
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/cubits/hide_widget/hide_widget_cubit.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:zenon_syrius_wallet_flutter/utils/wallet_file.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_ledger_dart/znn_ledger_dart.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

import '../helpers/hydrated_bloc.dart';
import 'bend_conformance_helper.dart';

const String _kDomain = 'wallet_lifecycle';
const String _kTestPassword = 'Password1!';

class _MockWalletFile extends Mock implements WalletFile {}

class _FakeLedgerWallet extends Fake implements LedgerWallet {
  int disconnectCalls = 0;

  @override
  Future<void> disconnect() async {
    disconnectCalls += 1;
  }
}

class _StubSoftwareWalletFile extends WalletFile {
  _StubSoftwareWalletFile() : super('/tmp/bend-software-wallet');

  @override
  String get walletType => keyStoreWalletType;

  @override
  bool get isOpen => false;

  @override
  bool get isHardwareWallet => false;

  @override
  Future<T> access<T>(Future<T> Function(Wallet) accessSection) {
    throw UnimplementedError();
  }

  @override
  Future<void> close() async {}
}

String _observeWalletFileState(WalletFile file) {
  if (!file.isClosed && !file.isOpen) {
    return 'idle';
  }
  if (!file.isClosed && file.isOpen) {
    return 'session_active';
  }
  if (file.isClosed && file.isOpen) {
    return 'closing';
  }
  return 'closed';
}

Future<Map<String, Object>> _runWalletFileLifecycleEvents(
  List<String> events,
) async {
  final _FakeLedgerWallet fakeLedger = _FakeLedgerWallet();
  final LedgerWalletFile file = LedgerWalletFile.forTesting(
    '/tmp/bend-lifecycle-wallet',
    'bend-ledger',
    (String _) async => fakeLedger,
  );

  Completer<void>? activeSession;
  Future<void>? activeAccessFuture;
  Future<void>? pendingCloseFuture;
  bool lastGranted = false;

  for (final String event in events) {
    switch (event) {
      case 'begin_access':
        if (!file.isClosed && !file.isOpen) {
          final Completer<void> entered = Completer<void>();
          final Completer<void> gate = Completer<void>();
          activeSession = gate;
          activeAccessFuture = file.access<void>((Wallet _) async {
            entered.complete();
            await gate.future;
          });
          await entered.future;
          lastGranted = true;
        } else if (file.isClosed) {
          bool threwClosed = false;
          try {
            await file.access<void>((Wallet _) async {});
          } on WalletException {
            threwClosed = true;
          }
          expect(threwClosed, isTrue);
          lastGranted = false;
        } else {
          lastGranted = false;
        }

      case 'end_access':
        if (activeSession != null && !activeSession.isCompleted) {
          activeSession.complete();
          try {
            await activeAccessFuture;
          } on WalletException {
            // Expected when close() ran concurrently before section completed.
          }
          activeSession = null;
          activeAccessFuture = null;
          if (pendingCloseFuture != null) {
            await pendingCloseFuture;
            pendingCloseFuture = null;
          }
        }
        lastGranted = false;

      case 'request_close':
        pendingCloseFuture = file.close();
        await Future<void>.delayed(Duration.zero);
        if (activeSession == null) {
          await pendingCloseFuture;
          pendingCloseFuture = null;
        }
        lastGranted = false;

      case 'finish_close':
        if (file.isClosed &&
            activeSession != null &&
            !activeSession.isCompleted) {
          activeSession.complete();
          try {
            await activeAccessFuture;
          } on WalletException {
            // Expected during close completion.
          }
          activeSession = null;
          activeAccessFuture = null;
          if (pendingCloseFuture != null) {
            await pendingCloseFuture;
            pendingCloseFuture = null;
          }
        }
        lastGranted = false;

      default:
        fail('Unknown WalletFile lifecycle event "$event"');
    }
  }

  final String observedState = _observeWalletFileState(file);

  if (activeSession != null && !activeSession.isCompleted) {
    activeSession.complete();
    try {
      await activeAccessFuture;
    } on WalletException {
      // Cleanup after leaving session active.
    }
  }
  await file.close();

  return <String, Object>{
    'state': observedState,
    'access_granted': lastGranted,
  };
}

String _buildPrefixedHex(int byteCount, {required bool validHex}) {
  if (!validHex) {
    final int pairs = byteCount < 1 ? 1 : byteCount;
    return '0x${'zz' * pairs}';
  }
  return '0x${'ab' * byteCount}';
}

Future<bool> _validateKeystoreSchemaViaWalletFileRead({
  required Directory tempDir,
  required String caseId,
  required int saltBytes,
  required int cipherBytes,
  required int nonceBytes,
  required bool saltHexOk,
  required bool cipherHexOk,
  required bool nonceHexOk,
  required bool hasCipherName,
  required bool hasKdf,
  required bool metaTypesOk,
}) async {
  final String filePath = path.join(tempDir.path, 'schema_$caseId.json');
  final Map<String, dynamic> payload = <String, dynamic>{
    'timestamp': metaTypesOk ? 1700000000 : 'invalid-timestamp',
    'version': 1,
    'crypto': <String, dynamic>{
      'argon2Params': <String, dynamic>{
        'salt': _buildPrefixedHex(saltBytes, validHex: saltHexOk),
      },
      'cipherData': _buildPrefixedHex(cipherBytes, validHex: cipherHexOk),
      'nonce': _buildPrefixedHex(nonceBytes, validHex: nonceHexOk),
      'cipherName': hasCipherName ? 'aes-256-gcm' : '',
      'kdf': hasKdf ? 'argon2.IDKey' : '',
    },
  };
  File(filePath).writeAsStringSync(jsonEncode(payload));
  try {
    await WalletFile.read(filePath);
    return true;
  } on FormatException {
    return false;
  }
}

SplashFlow _parseSplashFlow(String flow) {
  return switch (flow) {
    'normal' => SplashFlow.normal,
    'dev' => SplashFlow.development,
    'delete_cache' => SplashFlow.deleteCache,
    'reset_wallet' => SplashFlow.resetWallet,
    _ => fail('Unknown SplashFlow "$flow"'),
  };
}

String _splashDestinationKey(SplashDestination dest) {
  return switch (dest) {
    SplashDestination.accessWallet => 'access_wallet',
    SplashDestination.home => 'home',
    SplashDestination.nodeManagement => 'node_management',
  };
}

String _unlockStatusKey(WalletUnlockStatus status) {
  return switch (status) {
    WalletUnlockStatus.initial => 'initial',
    WalletUnlockStatus.success => 'success',
    WalletUnlockStatus.failure => 'failure',
    WalletUnlockStatus.autoEraseTriggered => 'auto_erase',
    WalletUnlockStatus.decrypting => 'decrypting',
    WalletUnlockStatus.initializing => 'initializing',
  };
}

List<String> _requireStringList(Map<String, dynamic> map, String key) {
  final Object? raw = map[key];
  if (raw is! List<dynamic>) {
    fail('Expected List<String> for "$key" in $map, got $raw');
  }
  final List<String> result = <String>[];
  for (final Object? element in raw) {
    if (element is! String) {
      fail('Expected String element in "$key" of $map, got $element');
    }
    result.add(element);
  }
  return result;
}

void main() {
  initHydratedStorage();

  late Directory tempDir;
  late Map<String, dynamic> templateKeyStoreJson;
  late Map<String, dynamic> templateLedgerJson;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('syrius_bend_wl_');

    final KeyStore keyStore = await KeyStore.newRandom();
    final Address baseAddr = await (await keyStore.getAccount()).getAddress();
    final String ksTemplatePath = path.join(tempDir.path, 'tpl_ks.json');
    await WalletFile.write(
      ksTemplatePath,
      _kTestPassword,
      HEX.decode(keyStore.entropy),
      metadata: <String, dynamic>{
        baseAddressKey: baseAddr.toString(),
        walletTypeKey: keyStoreWalletType,
      },
    );
    templateKeyStoreJson =
        jsonDecode(File(ksTemplatePath).readAsStringSync())
            as Map<String, dynamic>;

    final String ledgerTemplatePath = path.join(
      tempDir.path,
      'tpl_ledger.json',
    );
    await WalletFile.write(
      ledgerTemplatePath,
      _kTestPassword,
      utf8.encode(baseAddr.toString()),
      metadata: <String, dynamic>{
        baseAddressKey: baseAddr.toString(),
        walletTypeKey: ledgerWalletType,
      },
    );
    templateLedgerJson =
        jsonDecode(File(ledgerTemplatePath).readAsStringSync())
            as Map<String, dynamic>;
  });

  tearDownAll(() async {
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('Bend conformance: $_kDomain', () {
    test(
      'all Bend oracle vectors match Syrius wallet lifecycle, keystore, '
      'unlock, lock, splash, and hide-widget implementations',
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
            case 'wallet_file_lifecycle':
              final List<String> events = _requireStringList(args, 'events');
              final Map<String, Object> outcome =
                  await _runWalletFileLifecycleEvents(events);
              expectBendMatch(
                domain: _kDomain,
                caseId: caseId,
                actual: outcome,
                expected: expected,
              );

            case 'validate_keystore_schema':
              final bool valid = await _validateKeystoreSchemaViaWalletFileRead(
                tempDir: tempDir,
                caseId: caseId,
                saltBytes: requireInt(args, 'salt_bytes'),
                cipherBytes: requireInt(args, 'cipher_bytes'),
                nonceBytes: requireInt(args, 'nonce_bytes'),
                saltHexOk: requireBool(args, 'salt_hex_ok'),
                cipherHexOk: requireBool(args, 'cipher_hex_ok'),
                nonceHexOk: requireBool(args, 'nonce_hex_ok'),
                hasCipherName: requireBool(args, 'has_cipher_name'),
                hasKdf: requireBool(args, 'has_kdf'),
                metaTypesOk: requireBool(args, 'meta_types_ok'),
              );
              expectBendMatch(
                domain: _kDomain,
                caseId: caseId,
                actual: valid,
                expected: expected,
              );

            case 'dispatch_wallet_type':
              final String rawType = requireString(args, 'raw_type');
              final int otherCode = requireInt(args, 'other_code');
              final Map<String, dynamic> baseTemplate = rawType == 'ledger'
                  ? templateLedgerJson
                  : templateKeyStoreJson;
              final Map<String, dynamic> copy =
                  jsonDecode(jsonEncode(baseTemplate)) as Map<String, dynamic>;
              switch (rawType) {
                case 'none':
                  copy.remove(walletTypeKey);
                case 'keystore':
                  copy[walletTypeKey] = keyStoreWalletType;
                case 'ledger':
                  copy[walletTypeKey] = ledgerWalletType;
                case 'other':
                  copy[walletTypeKey] = 'unsupported_type_$otherCode';
                default:
                  fail('Unknown raw_type "$rawType"');
              }
              final String dispatchPath = path.join(
                tempDir.path,
                'dispatch_$caseId.json',
              );
              File(dispatchPath).writeAsStringSync(jsonEncode(copy));
              String resolved;
              try {
                final WalletFile opened = await WalletFile.decrypt(
                  dispatchPath,
                  _kTestPassword,
                );
                resolved = opened is LedgerWalletFile ? 'ledger' : 'keystore';
                await opened.close();
              } on WalletFileReadException catch (err) {
                expect(
                  err.reason,
                  WalletFileReadFailureReason.unsupportedWalletType,
                );
                resolved = 'unsupported';
              }
              expectBendMatch(
                domain: _kDomain,
                caseId: caseId,
                actual: resolved,
                expected: expected,
              );

            case 'can_backup_wallet':
              final bool isUnlocked = requireBool(args, 'is_unlocked');
              final bool isHardware = requireBool(args, 'is_hardware');
              final WalletFile? priorGlobalWalletFile = kWalletFile;
              kWalletFile = null;
              try {
                final WalletFile? injected = !isUnlocked
                    ? null
                    : isHardware
                    ? LedgerWalletFile.forTesting(
                        '/tmp/bend-hw',
                        'hw',
                        (String _) async => _FakeLedgerWallet(),
                      )
                    : _StubSoftwareWalletFile();
                final SettingsBackupCubit cubit = SettingsBackupCubit(
                  walletFile: injected,
                );
                final bool canBackup = cubit.state.canBackup;
                await cubit.close();
                if (injected != null) {
                  await injected.close();
                }
                expectBendMatch(
                  domain: _kDomain,
                  caseId: caseId,
                  actual: canBackup,
                  expected: expected,
                );
              } finally {
                kWalletFile = priorGlobalWalletFile;
              }

            case 'unlock_step':
              int failedAttempts = requireInt(args, 'failed');
              final int limit = requireInt(args, 'limit');
              bool initCompleted = requireBool(args, 'init_completed');
              final String attempt = requireString(args, 'attempt');
              bool neededInit = false;
              final _MockWalletFile unlockedHandle = _MockWalletFile();

              final WalletUnlockBloc bloc = WalletUnlockBloc(
                afterUnlockCallback: (String _) async {},
                afterInitCallback: () {},
                decryptWallet: (String _, String _) async {
                  return switch (attempt) {
                    'ok' => unlockedHandle,
                    'incorrect_password' => throw IncorrectPasswordException(),
                    'ledger_error' =>
                      // LedgerError is an external freezed union caught by
                      // WalletUnlockBloc via `on LedgerError`.
                      // ignore: only_throw_errors
                      throw const LedgerError.connectionError(
                        origMessage: 'Ledger disconnected',
                      ),
                    'io_error' => throw const FileSystemException('IO error'),
                    'empty' => unlockedHandle,
                    _ => fail('Unknown unlock attempt "$attempt"'),
                  };
                },
                initWalletAfterDecryption: (List<int> _) async {
                  neededInit = true;
                  initCompleted = true;
                },
                getWalletPath: () => '/tmp/bend-unlock-wallet',
                setWalletFile: (WalletFile _) {},
                isWalletInitCompleted: () => initCompleted,
                getNumFailedAttempts: () => failedAttempts,
                saveNumFailedAttempts: (int value) async {
                  failedAttempts = value;
                },
                getAutoEraseWalletLimit: () => limit,
                onFetchBalances: () {},
                sendErrorNotification: (Object _, String _) async {},
              );

              final WalletUnlockSubmitted submitted = WalletUnlockSubmitted(
                password: attempt == 'empty' ? '' : _kTestPassword,
                incorrectPasswordTitle: 'Incorrect password',
                unlockFailedTitle: 'Unlock failed',
                ledgerErrorTitleBuilder: (String details) => 'Ledger: $details',
              );

              if (attempt == 'empty') {
                bloc.add(submitted);
                await Future<void>.delayed(Duration.zero);
              } else {
                final Future<WalletUnlockState> done = bloc.stream.firstWhere(
                  (WalletUnlockState s) =>
                      s.status == WalletUnlockStatus.success ||
                      s.status == WalletUnlockStatus.failure ||
                      s.status == WalletUnlockStatus.autoEraseTriggered,
                );
                bloc.add(submitted);
                await done;
              }

              final WalletUnlockState finalState = bloc.state;
              await bloc.close();

              expectBendMatch(
                domain: _kDomain,
                caseId: caseId,
                actual: <String, Object>{
                  'status': _unlockStatusKey(finalState.status),
                  'failed': failedAttempts,
                  'remaining': finalState.remainingAttempts,
                  'init_completed': initCompleted,
                  'last_needed_init': neededInit,
                },
                expected: expected,
              );

            case 'lock_step':
              final bool isLocked = requireBool(args, 'is_locked');
              final bool hasHandle = requireBool(args, 'has_handle');
              final bool timerActive = requireBool(args, 'timer_active');
              final int initialSeq = requireInt(args, 'seq');
              final String input = requireString(args, 'input');
              final bool hasActiveIncomingSwaps = requireBool(
                args,
                'has_active_incoming_swaps',
              );

              final LockBloc bloc = LockBloc(
                currentPageProvider: () =>
                    isLocked ? Tabs.lock : Tabs.dashboard,
              );
              for (int i = 0; i < initialSeq; i += 1) {
                bloc.add(const LockCountDownRequested());
              }
              if (initialSeq > 0) {
                await bloc.stream.firstWhere(
                  (WalletLockState s) => s.sequence == initialSeq,
                );
              }

              bool nextLocked = isLocked;
              bool nextHandle = hasHandle;
              bool nextTimer = timerActive;

              switch (input) {
                case 'user_activity':
                  bloc.add(const LockTimerResetRequested());
                  await Future<void>.delayed(Duration.zero);
                  if (bloc.state.sequence > initialSeq) {
                    nextTimer = true;
                  }
                case 'manual_lock':
                  final Future<WalletLockState> next = bloc.stream.first;
                  bloc.add(const LockNavigateToLockRequested());
                  await next;
                  nextLocked = true;
                  nextHandle = false;
                  nextTimer = false;
                case 'timer_fired':
                  if (!hasActiveIncomingSwaps && !isLocked && timerActive) {
                    final Future<WalletLockState> next = bloc.stream.first;
                    bloc.add(const LockNavigateToLockRequested());
                    await next;
                    nextLocked = true;
                    nextHandle = false;
                    nextTimer = false;
                  }
                case 'unlocked':
                  final Future<WalletLockState> next = bloc.stream.first;
                  bloc.add(const LockNavigateToDashboardRequested());
                  await next;
                  nextLocked = false;
                  nextHandle = true;
                  nextTimer = true;
                default:
                  fail('Unknown LockInput "$input"');
              }

              final int finalSeq = bloc.state.sequence;
              await bloc.close();

              expectBendMatch(
                domain: _kDomain,
                caseId: caseId,
                actual: <String, Object>{
                  'is_locked': nextLocked,
                  'has_handle': nextHandle,
                  'timer_active': nextTimer,
                  'sequence': finalSeq,
                },
                expected: expected,
              );

            case 'splash_destination':
              final SplashFlow flow = _parseSplashFlow(
                requireString(args, 'flow'),
              );
              final bool hasWalletPath = requireBool(args, 'has_wallet_path');
              final bool hasNode = requireBool(args, 'has_node');
              bool exitedApp = false;
              final SplashBloc bloc = SplashBloc(
                setWalletInitIncomplete: () {},
                clearLastNotification: () async {},
                stopWebSocketClient: () {},
                clearAutoReceivePool: () {},
                stopHtlcSwapSync: () async {},
                closeHtlcSwapStorage: () async {},
                closeHive: () async {},
                deleteCacheBox: (String _) async {},
                deleteWeb3Cache: () async {},
                deleteHtlcDatabase: () async {},
                deleteLegacyHtlcBoxes: () async {},
                deleteKeyStoreBox: () async {},
                closeAndDeleteWalletFile: () async {},
                getWalletPath: () => hasWalletPath ? '/tmp/wallet' : null,
                getSelectedNode: () =>
                    hasNode ? 'wss://node.example:35998' : null,
                exitApp: () => exitedApp = true,
              );
              final Future<SplashState> settled = bloc.stream.firstWhere(
                (SplashState s) =>
                    s is SplashNavigateTo || s is SplashCacheDeleted,
              );
              bloc.add(SplashStarted(flow: flow, initApp: () async {}));
              final SplashState finalSplash = await settled;
              await bloc.close();
              final String destKey = switch (finalSplash) {
                SplashNavigateTo(:final SplashDestination destination) =>
                  _splashDestinationKey(destination),
                SplashCacheDeleted() => () {
                  expect(exitedApp, isTrue);
                  return 'exit_app';
                }(),
                _ => fail('Unexpected SplashState: $finalSplash'),
              };
              expectBendMatch(
                domain: _kDomain,
                caseId: caseId,
                actual: destKey,
                expected: expected,
              );

            case 'splash_can_retry':
              final SplashFlow flow = _parseSplashFlow(
                requireString(args, 'flow'),
              );
              final bool failDuringClear = requireBool(
                args,
                'fail_during_clear',
              );
              final bool isDestructive =
                  flow == SplashFlow.resetWallet ||
                  flow == SplashFlow.deleteCache;
              final SplashBloc bloc = SplashBloc(
                setWalletInitIncomplete: () {},
                clearLastNotification: () async {},
                stopWebSocketClient: () {},
                clearAutoReceivePool: () {},
                stopHtlcSwapSync: () async {},
                closeHtlcSwapStorage: () async {},
                closeHive: () async {
                  if (failDuringClear) {
                    throw StateError('clear failure');
                  }
                },
                deleteCacheBox: (String _) async {},
                deleteWeb3Cache: () async {},
                deleteHtlcDatabase: () async {},
                deleteLegacyHtlcBoxes: () async {},
                deleteKeyStoreBox: () async {},
                closeAndDeleteWalletFile: () async {},
                getWalletPath: () => null,
                getSelectedNode: () => null,
                exitApp: () {},
              );

              bool canRetry;
              if (flow == SplashFlow.deleteCache && !failDuringClear) {
                final Future<SplashState> done = bloc.stream.firstWhere(
                  (SplashState s) => s is SplashCacheDeleted,
                );
                bloc.add(SplashStarted(flow: flow, initApp: () async {}));
                await done;
                canRetry = false;
              } else {
                final Future<SplashState> failed = bloc.stream.firstWhere(
                  (SplashState s) => s is SplashFailure,
                );
                bloc.add(
                  SplashStarted(
                    flow: flow,
                    initApp: () async {
                      throw StateError('init failure');
                    },
                  ),
                );
                final SplashFailure failure = (await failed) as SplashFailure;
                canRetry = failure.failedWhileClearing && isDestructive;
              }
              await bloc.close();

              expectBendMatch(
                domain: _kDomain,
                caseId: caseId,
                actual: canRetry,
                expected: expected,
              );

            case 'hide_widget_step':
              final bool currentlyHidden = requireBool(
                args,
                'currently_hidden',
              );
              final bool targetHidden = requireBool(args, 'target_hidden');
              final bool passwordValid = requireBool(args, 'password_valid');

              int decryptCalls = 0;
              bool failDecrypt = false;
              final _MockWalletFile tempWallet = _MockWalletFile();
              when(tempWallet.close).thenAnswer((_) async {});

              final HideWidgetCubit cubit = HideWidgetCubit(
                walletPathProvider: () => '/tmp/bend-hide-wallet',
                decryptWalletFile: (String _, String _) async {
                  decryptCalls += 1;
                  if (failDecrypt) {
                    throw IncorrectPasswordException();
                  }
                  return tempWallet;
                },
                markWidgetAsHidden:
                    (String _, {required bool isHidden}) async {},
              );

              await cubit.saveValue(
                isHidden: currentlyHidden,
                widgetTitle: 'Balance',
                password: _kTestPassword,
              );
              decryptCalls = 0;
              failDecrypt = !passwordValid;

              await cubit.saveValue(
                isHidden: targetHidden,
                widgetTitle: 'Balance',
                password: passwordValid ? _kTestPassword : 'wrong',
              );
              final bool actualHidden = cubit.state.isHidden ?? currentlyHidden;
              await cubit.close();

              if (targetHidden) {
                expect(decryptCalls, 0);
              }
              expectBendMatch(
                domain: _kDomain,
                caseId: caseId,
                actual: actualHidden,
                expected: expected,
              );

            default:
              fail('Unhandled Bend conformance op "$_kDomain/$op"');
          }
        }

        expect(seenOps, isNotEmpty);
      },
    );

    test(
      'WalletFile.access enforces strict mutual exclusion and permanent '
      'closure under concurrency',
      () async {
        final _FakeLedgerWallet ledger = _FakeLedgerWallet();
        final LedgerWalletFile file = LedgerWalletFile.forTesting(
          '/tmp/bend-mutex-wallet',
          'mutex-ledger',
          (String _) async => ledger,
        );

        final Completer<void> firstEntered = Completer<void>();
        final Completer<void> firstGate = Completer<void>();
        bool secondEntered = false;

        final Future<void> first = file.access<void>((Wallet _) async {
          firstEntered.complete();
          await firstGate.future;
        });
        await firstEntered.future;

        final Future<void> second = file.access<void>((Wallet _) async {
          secondEntered = true;
        });
        await Future<void>.delayed(Duration.zero);

        expectBendMatch(
          domain: _kDomain,
          caseId: 'wallet_file_concurrent_second_blocked',
          actual: secondEntered,
          expected: false,
        );

        final Future<void> closing = file.close();
        await Future<void>.delayed(Duration.zero);
        expectBendMatch(
          domain: _kDomain,
          caseId: 'wallet_file_closing_while_active',
          actual: _observeWalletFileState(file),
          expected: 'closing',
        );

        firstGate.complete();
        await first;
        await expectLater(second, throwsA(isA<WalletException>()));
        await closing;

        expectBendMatch(
          domain: _kDomain,
          caseId: 'wallet_file_permanently_closed',
          actual: _observeWalletFileState(file),
          expected: 'closed',
        );
        expectBendMatch(
          domain: _kDomain,
          caseId: 'wallet_file_second_never_ran_after_close',
          actual: secondEntered,
          expected: false,
        );
      },
    );
  });
}
