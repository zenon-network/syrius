@Tags(<String>['bend'])
library;

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:json_rpc_2/json_rpc_2.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mutex/mutex.dart';
import 'package:zenon_syrius_wallet_flutter/l10n/app_localizations_en.dart';
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/account_chain_stats/account_chain_stats.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/auto_receive_tx/auto_receive_tx.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/balance/balance.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/pow_generating_status/pow_generating_status.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/cubits/timer_cubit.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/exceptions/exceptions.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/functions/poll_until_confirmed.dart';
import 'package:zenon_syrius_wallet_flutter/utils/account_block_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/wallet_file.dart';
import 'package:zenon_syrius_wallet_flutter/utils/zts_utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

import '../helpers/hydrated_bloc.dart';
import 'bend_conformance_helper.dart';

const String _kDomain = 'tx_pipeline';

const String _kAlreadyReceivedRpcMessage =
    'account-block from-block already received';

final Address _kAddress0 = Address.parse(
  'z1qqjnwjjpnue8xmmpanz6csze6tcmtzzdtfsww7',
);
final Address _kAddress1 = stakeAddress;
final Address _kUnknownAddress = tokenAddress;

class _MockZenon extends Mock implements Zenon {}

class _MockStatsApi extends Mock implements StatsApi {}

class _MockLedgerApi extends Mock implements LedgerApi {}

class _MockWsClient extends Mock implements WsClient {}

class _MockAccountBlockUtils extends Mock implements AccountBlockUtils {}

class _FakeHash extends Fake implements Hash {}

class _FakeAddress extends Fake implements Address {}

class _FakeAccountBlockTemplate extends Fake implements AccountBlockTemplate {}

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

  @override
  Future<WalletAccount> getAccount([int accountIndex = 0]) async {
    return _FakeWalletAccount(_addresses[accountIndex], accountIndex);
  }
}

class _FakeWalletFile extends WalletFile {
  _FakeWalletFile(
    this._wallet, {
    required this.isHardwareWallet,
    this.onBeforeAccess,
  }) : super('/tmp/bend-conformance-wallet');

  final Wallet _wallet;
  final Mutex _lock = Mutex();
  final void Function()? onBeforeAccess;
  bool _isClosed = false;

  @override
  final bool isHardwareWallet;

  @override
  String get walletType => isHardwareWallet ? 'ledger' : keyStoreWalletType;

  @override
  bool get isOpen => _lock.isLocked;

  @override
  bool get isClosed => _isClosed;

  @override
  Future<T> access<T>(Future<T> Function(Wallet) accessSection) async {
    onBeforeAccess?.call();
    if (_isClosed) {
      throw WalletException('Wallet file is closed');
    }
    return await _lock.protect<T>(() => accessSection(_wallet));
  }

  @override
  Future<void> close() async {
    _isClosed = true;
  }
}

class _TestInfiniteListBloc extends InfiniteListBloc<int> {
  _TestInfiniteListBloc({
    required super.zenon,
    required super.pageSize,
    required this.onFetch,
  }) : super(
         fromJsonT: (Object? value) => value! as int,
         toJsonT: (int value) => value,
       );

  final Future<List<int>> Function(Address? address, int pageIndex, int size)
  onFetch;

  @override
  Future<List<int>> paginationFetch({
    required Address? address,
    required int pageIndex,
    required int pageSize,
  }) => onFetch(address, pageIndex, pageSize);
}

class _TestFetchBloc extends FetchBloc<String> {
  _TestFetchBloc({required super.zenon, required this.onFetch})
    : super(
        fromJsonT: (Map<String, dynamic> json) => json['v'] as String,
        toJsonT: (String data) => <String, dynamic>{'v': data},
      );

  final Future<String> Function(Address address) onFetch;

  @override
  Future<String> getData({required Address address}) => onFetch(address);
}

class _TestTimerState extends TimerState<int> {
  const _TestTimerState({super.status, super.data, super.error});

  @override
  TimerState<int> copyWith({
    TimerStatus? status,
    int? data,
    SyriusException? error,
  }) {
    return _TestTimerState(
      status: status ?? this.status,
      data: data ?? this.data,
      error: error ?? this.error,
    );
  }
}

class _TestTimerCubit extends TimerCubit<int, _TestTimerState> {
  _TestTimerCubit({required super.zenon, required this.onFetch})
    : super(
        initialState: const _TestTimerState(),
        refreshInterval: const Duration(days: 1),
      );

  final Future<int> Function() onFetch;

  @override
  Future<int> fetch() => onFetch();

  @override
  _TestTimerState? fromJson(Map<String, dynamic> json) => null;

  @override
  Map<String, dynamic>? toJson(_TestTimerState state) => null;
}

SyncState _parseSyncState(String name) {
  return switch (name) {
    'unknown' => SyncState.unknown,
    'syncing' => SyncState.syncing,
    'syncDone' => SyncState.syncDone,
    'notEnoughPeers' => SyncState.notEnoughPeers,
    _ => fail('Unknown SyncState "$name"'),
  };
}

SyncInfo _syncInfo({
  required SyncState state,
  required int currentHeight,
  required int targetHeight,
}) {
  return SyncInfo.fromJson(<String, dynamic>{
    'state': state.index,
    'currentHeight': currentHeight,
    'targetHeight': targetHeight,
  });
}

Hash _hashFromId(int id) {
  final String hex = id.toRadixString(16).padLeft(64, '0');
  return Hash.parse(hex);
}

int _idFromHash(Hash hash) => int.parse(hash.toString(), radix: 16);

AccountBlock _fakeBlockForAddress(Address toAddress) {
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
    'address': _kAddress0.toString(),
    'toAddress': toAddress.toString(),
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

Future<String> _runCreatePreconditions({
  required SyncState syncState,
  required int currentHeight,
  required int targetHeight,
  required bool hasExplicitAddr,
  required bool hasSelectedAddr,
  required bool addrInWallet,
  required bool walletUnlocked,
}) async {
  final _MockZenon mockZenon = _MockZenon();
  final _MockStatsApi mockStats = _MockStatsApi();
  final _FakeWalletFile walletFile = _FakeWalletFile(
    _FakeWallet(<Address>[_kAddress0, _kAddress1]),
    isHardwareWallet: false,
  );

  when(() => mockZenon.stats).thenReturn(mockStats);
  when(mockStats.syncInfo).thenAnswer(
    (_) async => _syncInfo(
      state: syncState,
      currentHeight: currentHeight,
      targetHeight: targetHeight,
    ),
  );
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

  final Address targetAddr = addrInWallet ? _kAddress0 : _kUnknownAddress;
  final AccountBlockUtils utils = AccountBlockUtils(
    publishSuccessNotification: false,
    zenonProvider: () => mockZenon,
    walletFileProvider: () => walletUnlocked ? walletFile : null,
    addressListProvider: () => <String?>[
      _kAddress0.toString(),
      _kAddress1.toString(),
    ],
    selectedAddressProvider: () =>
        hasSelectedAddr ? targetAddr.toString() : null,
    sendPlasmaNotification: (String _) async {},
    addNotification: (WalletNotification _) async {},
    onPowStatusChanged: (PowStatus _) {},
    postSendDelay: Duration.zero,
  );

  final AccountBlockTemplate tx = AccountBlockTemplate(
    blockType: BlockTypeEnum.userSend.index,
  );

  try {
    await utils.createAccountBlock(
      tx,
      'send',
      address: hasExplicitAddr ? targetAddr : null,
    );
    return 'ok';
  } on NodeNotSyncedException {
    return 'err_node_not_synced';
  } on LocalizedSyriusException catch (e) {
    return switch (e.code) {
      SyriusErrorCode.noWalletAddressSelected => 'err_no_address_selected',
      SyriusErrorCode.addressNotInWalletList => 'err_address_not_in_wallet',
      SyriusErrorCode.walletNotUnlocked => 'err_wallet_not_unlocked',
      _ => 'err_other_${e.code.name}',
    };
  }
}

Future<String> _runHwReviewTiming({
  required bool needReview,
  required bool needPlasma,
}) async {
  final _MockZenon mockZenon = _MockZenon();
  final _MockStatsApi mockStats = _MockStatsApi();
  final _FakeWalletFile walletFile = _FakeWalletFile(
    _FakeWallet(<Address>[_kAddress0]),
    isHardwareWallet: needReview,
  );
  final List<String> trace = <String>[];

  when(() => mockZenon.stats).thenReturn(mockStats);
  when(mockStats.syncInfo).thenAnswer(
    (_) async => _syncInfo(
      state: SyncState.syncDone,
      currentHeight: 100,
      targetHeight: 100,
    ),
  );
  when(
    () => mockZenon.requiresPoW(
      any(),
      blockSigningKey: any(named: 'blockSigningKey'),
    ),
  ).thenAnswer((_) async => needPlasma);
  when(
    () => mockZenon.send(
      any(),
      currentKeyPair: any(named: 'currentKeyPair'),
      generatingPowCallback: any(named: 'generatingPowCallback'),
      waitForRequiredPlasma: any(named: 'waitForRequiredPlasma'),
    ),
  ).thenAnswer((Invocation invocation) async {
    trace.add('send_start');
    final void Function(PowStatus)? cb =
        invocation.namedArguments[#generatingPowCallback]
            as void Function(PowStatus)?;
    if (needPlasma && cb != null) {
      cb(PowStatus.generating);
      cb(PowStatus.done);
      await Future<void>.delayed(Duration.zero);
    }
    return invocation.positionalArguments.first as AccountBlockTemplate;
  });

  final AccountBlockUtils utils = AccountBlockUtils(
    publishSuccessNotification: false,
    zenonProvider: () => mockZenon,
    walletFileProvider: () => walletFile,
    addressListProvider: () => <String?>[_kAddress0.toString()],
    selectedAddressProvider: _kAddress0.toString,
    sendPlasmaNotification: (String _) async {
      trace.add('plasma');
    },
    addNotification: (WalletNotification notification) async {
      if (notification.type == NotificationType.confirm) {
        trace.add('review');
      }
    },
    onPowStatusChanged: (PowStatus status) {
      trace.add('pow_${status.name}');
    },
    postSendDelay: Duration.zero,
  );

  await utils.createAccountBlock(
    AccountBlockTemplate(blockType: BlockTypeEnum.userSend.index),
    'send',
    address: _kAddress0,
  );
  await Future<void>.delayed(Duration.zero);

  final int reviewIdx = trace.indexOf('review');
  if (reviewIdx == -1) {
    return 'none';
  }
  final int sendIdx = trace.indexOf('send_start');
  if (reviewIdx < sendIdx) {
    return 'immediate';
  }
  return 'deferred';
}

Future<Map<String, Object>> _runAutoReceiveStep({
  required List<int> initialPool,
  required bool enabled,
  required bool htlcUnlocking,
  required String outcome,
}) async {
  final _MockZenon mockZenon = _MockZenon();
  final _MockStatsApi mockStats = _MockStatsApi();
  final _MockLedgerApi mockLedger = _MockLedgerApi();
  final _MockAccountBlockUtils mockBlockUtils = _MockAccountBlockUtils();

  bool currentHtlcUnlocking = htlcUnlocking;
  int createCalls = 0;
  bool enteredSecondIteration = false;

  when(() => mockZenon.stats).thenReturn(mockStats);
  when(() => mockZenon.ledger).thenReturn(mockLedger);
  when(
    () => mockLedger.getAccountBlockByHash(any()),
  ).thenAnswer((_) async => _fakeBlockForAddress(_kAddress0));
  when(
    () => mockBlockUtils.createAccountBlock(
      any(),
      any(),
      address: any(named: 'address'),
      waitForRequiredPlasma: any(named: 'waitForRequiredPlasma'),
    ),
  ).thenAnswer((Invocation invocation) async {
    createCalls += 1;
    final AccountBlockTemplate template =
        invocation.positionalArguments.first as AccountBlockTemplate;
    return switch (outcome) {
      'ok' => template,
      'already_received' => throw RpcException(
        -32000,
        _kAlreadyReceivedRpcMessage,
      ),
      'other_error' => throw RpcException(-32000, 'transient rpc failure'),
      _ => fail('Unknown AutoReceive outcome "$outcome"'),
    };
  });

  final AutoReceiveTxWorker worker = AutoReceiveTxWorker(
    zenonProvider: () => mockZenon,
    accountBlockUtilsProvider: () => mockBlockUtils,
    isAutoReceiveEnabled: () => enabled,
    isHtlcAutoUnlocking: () {
      if (createCalls >= 1) {
        enteredSecondIteration = true;
        currentHtlcUnlocking = true;
      }
      return currentHtlcUnlocking;
    },
    onRefreshPendingTransactions: () {},
    onTransactionReceived: () {},
    addressLabelResolver: (String _) => 'Addr',
    onNotification: (WalletNotification _) {},
    l10nProvider: AppLocalizationsEn.new,
  );

  for (final int hashId in initialPool) {
    worker.enqueueForTesting(_hashFromId(hashId));
  }

  await worker.autoReceive();
  final List<int> remaining = worker.pool.map(_idFromHash).toList();
  final int notifSeq = worker.state.notificationSequence;
  await worker.close();

  return <String, Object>{
    'remaining_pool': remaining,
    'notif_seq': notifSeq,
    'entered_next': enteredSecondIteration,
  };
}

Future<Map<String, Object>> _runPollStep({
  required bool cancelledBefore,
  required int remBeforeMs,
  required String outcome,
  required bool cancelledAfter,
  required int remAfterMs,
  required int pollIntervalMs,
}) async {
  DateTime clock = DateTime(2026);
  final DateTime deadline = clock.add(Duration(milliseconds: remBeforeMs));
  bool afterFetch = false;
  bool sleptOnce = false;
  final List<int> sleepsMs = <int>[];

  final bool result = await pollUntilConfirmed<bool>(
    fetch: () async {
      afterFetch = true;
      clock = deadline.subtract(Duration(milliseconds: remAfterMs));
      return switch (outcome) {
        'confirmed' => true,
        'not_confirmed' => false,
        'transient_error' => throw Exception('transient rpc error'),
        _ => fail('Unknown poll outcome "$outcome"'),
      };
    },
    isConfirmed: (bool value) => value,
    pollInterval: Duration(milliseconds: pollIntervalMs),
    timeout: Duration(milliseconds: remBeforeMs),
    isCancelled: () {
      if (sleptOnce) {
        return true;
      }
      return afterFetch ? cancelledAfter : cancelledBefore;
    },
    now: () => clock,
    delay: (Duration duration) async {
      sleepsMs.add(duration.inMilliseconds);
      sleptOnce = true;
    },
  );

  if (sleepsMs.isNotEmpty) {
    return <String, Object>{'kind': 'sleep', 'sleep_ms': sleepsMs.first};
  }
  return <String, Object>{
    'kind': result ? 'done_true' : 'done_false',
    'sleep_ms': 0,
  };
}

Future<Map<String, Object>> _runInfiniteListStep({
  required int pageSize,
  required int firstPageLen,
  required int secondPageLen,
  required bool moreSameAddress,
}) async {
  final _MockZenon mockZenon = _MockZenon();
  final List<int> fetchedPageIndices = <int>[];

  final _TestInfiniteListBloc bloc = _TestInfiniteListBloc(
    zenon: mockZenon,
    pageSize: pageSize,
    onFetch: (Address? address, int pageIndex, int size) async {
      fetchedPageIndices.add(pageIndex);
      if (pageIndex == 0) {
        return List<int>.generate(firstPageLen, (int i) => i);
      }
      return List<int>.generate(secondPageLen, (int i) => firstPageLen + i);
    },
  )..add(InfiniteListRequested(address: _kAddress0));
  await Future<void>.delayed(Duration.zero);
  final bool firstHasReachedMax = bloc.state.hasReachedMax;

  bloc.add(
    InfiniteListMoreRequested(
      address: moreSameAddress ? _kAddress0 : _kAddress1,
    ),
  );
  await Future<void>.delayed(Duration.zero);

  final int finalCount = bloc.state.data?.length ?? 0;
  final bool finalHasReachedMax = bloc.state.hasReachedMax;
  final int secondPageIndex = fetchedPageIndices.length >= 2
      ? fetchedPageIndices[1]
      : -1;
  await bloc.close();

  return <String, Object>{
    'first_has_reached_max': firstHasReachedMax,
    'second_page_index': secondPageIndex,
    'final_count': finalCount,
    'final_has_reached_max': finalHasReachedMax,
  };
}

Future<bool> _runBalanceIsPopulated({
  required int blockCount,
  required int znn,
  required int qsr,
}) async {
  final _MockZenon mockZenon = _MockZenon();
  final _MockLedgerApi mockLedger = _MockLedgerApi();
  when(() => mockZenon.ledger).thenReturn(mockLedger);
  when(() => mockLedger.getAccountInfoByAddress(any())).thenAnswer(
    (_) async => AccountInfo.fromJson(<String, dynamic>{
      'address': _kAddress0.toString(),
      'accountHeight': blockCount,
      'balanceInfoMap': <String, dynamic>{
        znnZts.toString(): <String, dynamic>{
          'token': kZnnCoin.toJson(),
          'balance': znn.toString(),
        },
        qsrZts.toString(): <String, dynamic>{
          'token': kQsrCoin.toJson(),
          'balance': qsr.toString(),
        },
      },
    }),
  );

  final BalanceCubit cubit = BalanceCubit(
    address: _kAddress0,
    zenon: mockZenon,
  );
  try {
    await cubit.fetch();
    return true;
  } on NoBalanceException {
    return false;
  } finally {
    await cubit.close();
  }
}

Future<int> _runAccountChainStatsPageCount({
  required int blockCount,
  required int pageSize,
}) async {
  if (pageSize != rpcMaxPageSize) {
    return blockCount <= 0 ? 0 : (blockCount / pageSize).ceil();
  }
  final _MockZenon mockZenon = _MockZenon();
  final _MockLedgerApi mockLedger = _MockLedgerApi();
  int heightCalls = 0;

  when(() => mockZenon.ledger).thenReturn(mockLedger);
  when(() => mockLedger.getAccountInfoByAddress(any())).thenAnswer(
    (_) async => AccountInfo.fromJson(<String, dynamic>{
      'address': _kAddress0.toString(),
      'accountHeight': blockCount,
      'balanceInfoMap': const <String, dynamic>{},
    }),
  );
  when(
    () => mockLedger.getAccountBlocksByHeight(any(), any(), any()),
  ).thenAnswer((_) async {
    heightCalls += 1;
    return AccountBlockList.fromJson(<String, dynamic>{
      'list': const <dynamic>[],
      'count': 0,
      'more': false,
    });
  });

  final AccountChainStatsBloc bloc = AccountChainStatsBloc(zenon: mockZenon);
  try {
    await bloc.getData(address: _kAddress0);
    return heightCalls;
  } on EmptyAccountChainException {
    return 0;
  } finally {
    await bloc.close();
  }
}

void main() {
  initHydratedStorage();

  setUpAll(() {
    registerFallbackValue(_FakeHash());
    registerFallbackValue(_FakeAddress());
    registerFallbackValue(_FakeAccountBlockTemplate());
    registerFallbackValue(_FakeWalletAccount(emptyAddress, 0));
  });

  group('Bend conformance: $_kDomain', () {
    test(
      'all Bend oracle vectors match Syrius transaction pipeline logic',
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
            case 'node_is_synced_for_tx':
              final String outcome = await _runCreatePreconditions(
                syncState: _parseSyncState(requireString(args, 'state')),
                currentHeight: requireInt(args, 'current_height'),
                targetHeight: requireInt(args, 'target_height'),
                hasExplicitAddr: true,
                hasSelectedAddr: true,
                addrInWallet: true,
                walletUnlocked: true,
              );
              expectBendMatch(
                domain: _kDomain,
                caseId: caseId,
                actual: outcome == 'ok',
                expected: expected,
              );
            case 'check_create_preconditions':
              final String actual = await _runCreatePreconditions(
                syncState: _parseSyncState(requireString(args, 'state')),
                currentHeight: requireInt(args, 'current_height'),
                targetHeight: requireInt(args, 'target_height'),
                hasExplicitAddr: requireBool(args, 'has_explicit_addr'),
                hasSelectedAddr: requireBool(args, 'has_selected_addr'),
                addrInWallet: requireBool(args, 'addr_in_wallet'),
                walletUnlocked: requireBool(args, 'wallet_unlocked'),
              );
              expectBendMatch(
                domain: _kDomain,
                caseId: caseId,
                actual: actual,
                expected: expected,
              );
            case 'pow_sequence':
              final List<int> events = requireIntList(args, 'events');
              final PowGeneratingStatusBloc bloc = PowGeneratingStatusBloc();
              int emissions = 0;
              final StreamSubscription<PowGeneratingStatusState> sub = bloc
                  .stream
                  .listen((PowGeneratingStatusState _) {
                    emissions += 1;
                  });
              for (final int ev in events) {
                bloc.add(
                  PowGeneratingStatusChanged(
                    ev == 1 ? PowStatus.generating : PowStatus.done,
                  ),
                );
              }
              await Future<void>.delayed(Duration.zero);
              final bool finalGenerating = bloc.state.isGenerating;
              await sub.cancel();
              await bloc.close();
              expectBendMatch(
                domain: _kDomain,
                caseId: caseId,
                actual: <String, Object>{
                  'final_generating': finalGenerating,
                  'emissions': emissions,
                },
                expected: expected,
              );
            case 'hw_review_timing':
              final String actual = await _runHwReviewTiming(
                needReview: requireBool(args, 'need_review'),
                needPlasma: requireBool(args, 'need_plasma'),
              );
              expectBendMatch(
                domain: _kDomain,
                caseId: caseId,
                actual: actual,
                expected: expected,
              );
            case 'auto_receive_add_hash':
              final List<int> hashes = requireIntList(args, 'hashes');
              final List<int> syncedFlags = requireIntList(
                args,
                'synced_flags',
              );
              final _MockZenon mockZenon = _MockZenon();
              final _MockStatsApi mockStats = _MockStatsApi();
              when(() => mockZenon.stats).thenReturn(mockStats);
              final AutoReceiveTxWorker worker = AutoReceiveTxWorker(
                zenonProvider: () => mockZenon,
                isAutoReceiveEnabled: () => true,
                isHtlcAutoUnlocking: () => false,
                onRefreshPendingTransactions: () {},
                onTransactionReceived: () {},
                onNotification: (WalletNotification _) {},
                l10nProvider: AppLocalizationsEn.new,
              );
              for (int i = 0; i < hashes.length; i += 1) {
                final bool synced = syncedFlags[i] == 1;
                when(mockStats.syncInfo).thenAnswer(
                  (_) async => synced
                      ? _syncInfo(
                          state: SyncState.syncDone,
                          currentHeight: 100,
                          targetHeight: 100,
                        )
                      : _syncInfo(
                          state: SyncState.syncing,
                          currentHeight: 10,
                          targetHeight: 1000,
                        ),
                );
                await worker.addHash(_hashFromId(hashes[i]));
              }
              final List<int> poolIds = worker.pool.map(_idFromHash).toList();
              await worker.close();
              expectBendMatch(
                domain: _kDomain,
                caseId: caseId,
                actual: <String, Object>{
                  'pool': poolIds,
                  'pool_len': poolIds.length,
                },
                expected: expected,
              );
            case 'auto_receive_step':
              final Map<String, Object> actual = await _runAutoReceiveStep(
                initialPool: requireIntList(args, 'initial_pool'),
                enabled: requireBool(args, 'enabled'),
                htlcUnlocking: requireBool(args, 'htlc_unlocking'),
                outcome: requireString(args, 'outcome'),
              );
              expectBendMatch(
                domain: _kDomain,
                caseId: caseId,
                actual: actual,
                expected: expected,
              );
            case 'poll_step':
              final Map<String, Object> actual = await _runPollStep(
                cancelledBefore: requireBool(args, 'cancelled_before'),
                remBeforeMs: requireInt(args, 'rem_before_ms'),
                outcome: requireString(args, 'outcome'),
                cancelledAfter: requireBool(args, 'cancelled_after'),
                remAfterMs: requireInt(args, 'rem_after_ms'),
                pollIntervalMs: requireInt(args, 'poll_interval_ms'),
              );
              expectBendMatch(
                domain: _kDomain,
                caseId: caseId,
                actual: actual,
                expected: expected,
              );
            case 'infinite_list_page_and_max':
              final Map<String, Object> actual = await _runInfiniteListStep(
                pageSize: requireInt(args, 'page_size'),
                firstPageLen: requireInt(args, 'first_page_len'),
                secondPageLen: requireInt(args, 'second_page_len'),
                moreSameAddress: requireBool(args, 'more_same_address'),
              );
              expectBendMatch(
                domain: _kDomain,
                caseId: caseId,
                actual: actual,
                expected: expected,
              );
            case 'balance_is_populated':
              final bool actual = await _runBalanceIsPopulated(
                blockCount: requireInt(args, 'block_count'),
                znn: requireInt(args, 'znn'),
                qsr: requireInt(args, 'qsr'),
              );
              expectBendMatch(
                domain: _kDomain,
                caseId: caseId,
                actual: actual,
                expected: expected,
              );
            case 'account_chain_stats_page_count':
              final int actual = await _runAccountChainStatsPageCount(
                blockCount: requireInt(args, 'block_count'),
                pageSize: requireInt(args, 'page_size'),
              );
              expectBendMatch(
                domain: _kDomain,
                caseId: caseId,
                actual: actual,
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
      'AccountBlockUtils aborts when wallet locks or swaps mid-flight',
      () async {
        final _MockZenon mockZenon = _MockZenon();
        final _MockStatsApi mockStats = _MockStatsApi();
        when(() => mockZenon.stats).thenReturn(mockStats);
        when(mockStats.syncInfo).thenAnswer(
          (_) async => _syncInfo(
            state: SyncState.syncDone,
            currentHeight: 100,
            targetHeight: 100,
          ),
        );

        late WalletFile? activeWallet;
        final _FakeWalletFile replacementWallet = _FakeWalletFile(
          _FakeWallet(<Address>[_kAddress0]),
          isHardwareWallet: false,
        );
        final _FakeWalletFile originalWallet = _FakeWalletFile(
          _FakeWallet(<Address>[_kAddress0]),
          isHardwareWallet: false,
          onBeforeAccess: () {
            activeWallet = replacementWallet;
          },
        );
        activeWallet = originalWallet;

        final AccountBlockUtils utils = AccountBlockUtils(
          publishSuccessNotification: false,
          zenonProvider: () => mockZenon,
          walletFileProvider: () => activeWallet,
          addressListProvider: () => <String?>[_kAddress0.toString()],
          selectedAddressProvider: _kAddress0.toString,
          sendPlasmaNotification: (String _) async {},
          addNotification: (WalletNotification _) async {},
          onPowStatusChanged: (PowStatus _) {},
          postSendDelay: Duration.zero,
        );

        String outcome = 'allowed';
        try {
          await utils.createAccountBlock(
            AccountBlockTemplate(blockType: BlockTypeEnum.userSend.index),
            'send',
            address: _kAddress0,
          );
        } on LocalizedSyriusException catch (e) {
          outcome = e.code == SyriusErrorCode.walletNotUnlocked
              ? 'aborted_wallet_changed'
              : 'other_${e.code.name}';
        }

        expectBendMatch(
          domain: _kDomain,
          caseId: 'publish_fence_wallet_swap_in_access',
          actual: outcome,
          expected: 'aborted_wallet_changed',
        );
      },
    );

    test(
      'InfiniteListBloc discards stale first-page response and FetchBloc '
      'tracks ref-counted loading while TimerCubit preserves valid states',
      () async {
        final _MockZenon mockZenon = _MockZenon();
        final _MockWsClient mockWs = _MockWsClient();
        when(() => mockZenon.wsClient).thenReturn(mockWs);
        when(mockWs.isClosed).thenReturn(false);

        final Completer<List<int>> stalePage = Completer<List<int>>();
        final Completer<List<int>> freshPage = Completer<List<int>>();
        int fetchCalls = 0;

        final _TestInfiniteListBloc listBloc = _TestInfiniteListBloc(
          zenon: mockZenon,
          pageSize: 5,
          onFetch: (Address? address, int pageIndex, int size) {
            fetchCalls += 1;
            return fetchCalls == 1 ? stalePage.future : freshPage.future;
          },
        );
        addTearDown(listBloc.close);

        listBloc.add(InfiniteListRefreshRequested(address: _kAddress0));
        await Future<void>.delayed(Duration.zero);
        listBloc.add(InfiniteListRefreshRequested(address: _kAddress1));
        await Future<void>.delayed(Duration.zero);

        freshPage.complete(<int>[10, 20]);
        await Future<void>.delayed(Duration.zero);
        stalePage.complete(<int>[99, 98, 97, 96, 95]);
        await Future<void>.delayed(Duration.zero);

        expectBendMatch(
          domain: _kDomain,
          caseId: 'infinite_list_stale_first_page_discarded',
          actual: listBloc.state.data,
          expected: <int>[10, 20],
        );

        final Completer<String> f1 = Completer<String>();
        final Completer<String> f2 = Completer<String>();
        int fCalls = 0;
        final _TestFetchBloc fetchBloc = _TestFetchBloc(
          zenon: mockZenon,
          onFetch: (Address _) {
            fCalls += 1;
            return fCalls == 1 ? f1.future : f2.future;
          },
        );
        addTearDown(fetchBloc.close);

        final bool loadingBefore = fetchBloc.isLoadingListenable.value;
        fetchBloc
          ..add(FetchRequestData(address: _kAddress0))
          ..add(FetchRequestData(address: _kAddress1));
        await Future<void>.delayed(Duration.zero);
        final bool loadingDuringTwo = fetchBloc.isLoadingListenable.value;
        f1.complete('a');
        await Future<void>.delayed(Duration.zero);
        final bool loadingDuringOne = fetchBloc.isLoadingListenable.value;
        f2.complete('b');
        await Future<void>.delayed(Duration.zero);
        final bool loadingAfterBoth = fetchBloc.isLoadingListenable.value;

        expectBendMatch(
          domain: _kDomain,
          caseId: 'fetch_bloc_ref_counted_loading',
          actual: <bool>[
            loadingBefore,
            loadingDuringTwo,
            loadingDuringOne,
            loadingAfterBoth,
          ],
          expected: <bool>[false, true, true, false],
        );

        final _TestTimerCubit timerCubit = _TestTimerCubit(
          zenon: mockZenon,
          onFetch: () async => 42,
        );
        addTearDown(timerCubit.close);

        final List<TimerStatus> timerStatuses = <TimerStatus>[];
        final StreamSubscription<_TestTimerState> timerSub = timerCubit.stream
            .listen((_TestTimerState s) => timerStatuses.add(s.status));
        addTearDown(timerSub.cancel);

        await timerCubit.fetchDataPeriodically();
        await timerCubit.fetchDataPeriodically();
        await Future<void>.delayed(Duration.zero);

        expectBendMatch(
          domain: _kDomain,
          caseId: 'timer_cubit_success_skips_loading_flicker',
          actual: timerStatuses.map((TimerStatus s) => s.name).toList(),
          expected: <String>[
            TimerStatus.loading.name,
            TimerStatus.success.name,
          ],
        );
      },
    );
  });
}
