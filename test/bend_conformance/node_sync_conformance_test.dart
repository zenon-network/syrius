@Tags(<String>['bend'])
library;

import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/hive/hive_registrar.g.dart';
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/about/about.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/node_management/node_management.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/node_sync_status/node_sync_status.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/notifications/notifications.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/settings_wallet_options/settings_wallet_options.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/exceptions/exceptions.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/extensions/sync_info_extension.dart';
import 'package:zenon_syrius_wallet_flutter/services/shared_prefs_service.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

import '../helpers/hydrated_bloc.dart';
import 'bend_conformance_helper.dart';

const String _kDomain = 'node_sync';

const String _kPrevNode = kEmbeddedNode;
const String _kTargetNode = kLocalhostDefaultNodeUrl;
const String _kCustomNode = 'wss://custom.bend-test.node:35998';

class _MockNodeManagementRepository extends Mock
    implements NodeManagementRepository {}

class _MockNotificationsRepository extends Mock
    implements NotificationsRepository {}

class _MockSharedPrefsService extends Mock implements SharedPrefsService {}

class _MockZenon extends Mock implements Zenon {}

class _MockWsClient extends Mock implements WsClient {}

class _MockLedgerApi extends Mock implements LedgerApi {}

class _MockStatsApi extends Mock implements StatsApi {}

class _MockNodeSyncMonitor extends Mock implements NodeSyncMonitor {}

class _MockMomentum extends Mock implements Momentum {}

class _MockProcessInfo extends Mock implements ProcessInfo {}

class _MockOsInfo extends Mock implements OsInfo {}

class _FakeWalletNotification extends Fake implements WalletNotification {}

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

String _encodeNodeId(String node) {
  if (node == _kPrevNode) {
    return 'prev';
  }
  if (node == _kTargetNode) {
    return 'target';
  }
  return node;
}

Future<Map<String, Object>> _runNodeMgmtConfirmFlow({
  required bool checkMismatch,
  required int clientChainId,
  required bool connectOk,
  required int liveChainId,
  required bool precommitOk,
  required bool rollbackOk,
  required int restoredChainId,
  required bool notifyOk,
  required String action,
  required int proceedLiveChainId,
}) async {
  final int? savedGlobalChainId = kNodeChainId;
  kNodeChainId = clientChainId;

  final _MockNodeManagementRepository repo = _MockNodeManagementRepository();
  String persistedNode = _kPrevNode;
  final List<String> availableNodes = <String>[_kPrevNode, _kTargetNode];
  int frontierPhase = 0;

  when(repo.shuffleCommunityNodes).thenReturn(null);
  when(repo.getAvailableNodes).thenAnswer(
    (_) => List<String>.of(availableNodes),
  );
  when(
    () => repo.getCurrentNode(fallback: any(named: 'fallback')),
  ).thenAnswer((_) => persistedNode);
  when(repo.getClientChainId).thenReturn(clientChainId);
  when(repo.getNodeChainId).thenAnswer((_) async => clientChainId);
  when(repo.getAutoReceive).thenReturn(true);
  when(repo.disconnectFromNode).thenReturn(null);
  when(repo.clearAutoReceivePool).thenReturn(null);
  when(repo.triggerAutoReceive).thenAnswer((_) async {});
  when(() => repo.reportError(any(), any())).thenAnswer((_) async {});
  when(
    () => repo.resetLastCheckedHtlcBlockHeight(chainId: any(named: 'chainId')),
  ).thenAnswer((_) async {});

  when(() => repo.connectToNode(_kTargetNode)).thenAnswer(
    (_) async => connectOk,
  );
  when(() => repo.connectToNode(_kPrevNode)).thenAnswer(
    (_) async => rollbackOk,
  );

  when(repo.getFrontierChainId).thenAnswer((_) async {
    frontierPhase += 1;
    if (frontierPhase == 1) {
      return liveChainId;
    }
    if (action == 'proceed' && frontierPhase == 2) {
      return proceedLiveChainId;
    }
    return restoredChainId;
  });

  when(() => repo.saveSelectedNode(any())).thenAnswer((
    Invocation invocation,
  ) async {
    if (!precommitOk) {
      throw StateError('saveSelectedNode failed');
    }
    persistedNode = invocation.positionalArguments.first as String;
  });

  when(() => repo.addNotification(any())).thenAnswer((_) async {
    if (!notifyOk) {
      throw StateError('notification failed');
    }
  });

  final NodeManagementBloc bloc = NodeManagementBloc(
    repository: repo,
    checkChainIdMismatch: checkMismatch,
    resetHtlcBlockHeightOnChange: false,
    shuffleCommunityNodes: false,
  );

  try {
    bloc
      ..add(const NodeManagementNodeSelected(node: _kTargetNode))
      ..add(
        const NodeManagementConfirmNodeRequested(
          successTitle: 'Connected',
          successDetails: 'Connected',
          connectionUnavailableMessage: 'Unavailable',
          connectionFailedTitle: 'Failed',
        ),
      );
    await Future<void>.delayed(const Duration(milliseconds: 10));

    if (action == 'proceed' || action == 'cancel') {
      bloc.add(
        NodeManagementChainIdMismatchResolved(
          proceed: action == 'proceed',
          connectionFailedTitle: 'Failed',
          connectionUnavailableMessage: 'Unavailable',
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }

    final NodeManagementState s = bloc.state;
    return <String, Object>{
      'selected': _encodeNodeId(s.selectedNode),
      'confirmed': _encodeNodeId(s.confirmedNode),
      'saved': _encodeNodeId(persistedNode),
      'has_mismatch': s.pendingChainIdMismatch != null,
      'is_disconnected': s.isDisconnected,
      'reconnect_failed': s.pendingChainIdMismatch?.reconnectFailed ?? false,
      'nonce': s.nodeConfirmedNonce,
    };
  } finally {
    await bloc.close();
    kNodeChainId = savedGlobalChainId;
  }
}

Future<String> _runNodeMgmtEditValidation({
  required int newLen,
  required bool isDuplicate,
}) async {
  final _MockNodeManagementRepository repo = _MockNodeManagementRepository();
  final String candidate = newLen == 0
      ? ''
      : List<String>.filled(newLen, 'a').join();
  final List<String> availableNodes = <String>[
    _kPrevNode,
    _kCustomNode,
    if (isDuplicate && candidate.isNotEmpty) candidate,
  ];

  when(repo.shuffleCommunityNodes).thenReturn(null);
  when(repo.getAvailableNodes).thenAnswer(
    (_) => List<String>.of(availableNodes),
  );
  when(
    () => repo.getCurrentNode(fallback: any(named: 'fallback')),
  ).thenReturn(_kPrevNode);
  when(repo.getClientChainId).thenReturn(1);
  when(repo.getAutoReceive).thenReturn(true);
  when(
    () => repo.updateCustomNode(
      oldNode: any(named: 'oldNode'),
      newNode: any(named: 'newNode'),
    ),
  ).thenAnswer((_) async {});
  when(() => repo.reportError(any(), any())).thenAnswer((_) async {});

  final NodeManagementBloc bloc = NodeManagementBloc(
    repository: repo,
    checkChainIdMismatch: true,
    resetHtlcBlockHeightOnChange: false,
    shuffleCommunityNodes: false,
  );
  try {
    bloc.add(
      NodeManagementEditNodeRequested(
        oldNode: _kCustomNode,
        newNode: candidate,
        emptyErrorMessage: 'empty',
        tooLongErrorMessage: 'too_long',
        duplicateErrorMessage: 'duplicate',
        errorTitle: 'error',
      ),
    );
    await Future<void>.delayed(Duration.zero);
    return bloc.state.editNodeError ?? 'valid';
  } finally {
    await bloc.close();
  }
}

Future<String> _runSyncCubitHysteresis({
  required SyncState state1,
  required int cur1,
  required int tgt1,
  required SyncState state2,
  required int cur2,
  required int tgt2,
}) async {
  final _MockZenon mockZenon = _MockZenon();
  final _MockWsClient mockWs = _MockWsClient();
  final _MockNodeSyncMonitor mockMonitor = _MockNodeSyncMonitor();

  when(() => mockZenon.wsClient).thenReturn(mockWs);
  when(mockWs.isClosed).thenReturn(false);
  when(mockWs.status).thenReturn(WebsocketStatus.running);

  int callCount = 0;
  when(mockMonitor.fetch).thenAnswer((_) async {
    callCount += 1;
    if (callCount == 1) {
      return _syncInfo(state: state1, currentHeight: cur1, targetHeight: tgt1);
    }
    return _syncInfo(state: state2, currentHeight: cur2, targetHeight: tgt2);
  });

  final NodeSyncStatusCubit cubit = NodeSyncStatusCubit(
    zenon: mockZenon,
    syncMonitor: mockMonitor,
  );
  try {
    await cubit.fetch();
    final Pair<SyncState, SyncInfo> second = await cubit.fetch();
    return second.first.name;
  } finally {
    await cubit.close();
  }
}

Future<Map<String, Object>> _runAboutReduce({
  required bool r1Ok,
  required bool r2Ok,
  required bool r3Ok,
}) async {
  final _MockZenon mockZenon = _MockZenon();
  final _MockLedgerApi mockLedger = _MockLedgerApi();
  final _MockStatsApi mockStats = _MockStatsApi();
  final _MockMomentum mockMomentum = _MockMomentum();
  final _MockProcessInfo mockProcess = _MockProcessInfo();
  final _MockOsInfo mockOs = _MockOsInfo();

  when(() => mockZenon.ledger).thenReturn(mockLedger);
  when(() => mockZenon.stats).thenReturn(mockStats);

  if (r1Ok) {
    when(mockLedger.getFrontierMomentum).thenAnswer((_) async => mockMomentum);
  } else {
    when(
      mockLedger.getFrontierMomentum,
    ).thenAnswer((_) async => throw SyriusException('err_1'));
  }
  if (r2Ok) {
    when(mockStats.processInfo).thenAnswer((_) async => mockProcess);
  } else {
    when(
      mockStats.processInfo,
    ).thenAnswer((_) async => throw SyriusException('err_2'));
  }
  if (r3Ok) {
    when(mockStats.osInfo).thenAnswer((_) async => mockOs);
  } else {
    when(
      mockStats.osInfo,
    ).thenAnswer((_) async => throw SyriusException('err_3'));
  }

  final AboutBloc bloc = AboutBloc(zenon: mockZenon);
  try {
    bloc.add(const AboutRequested());
    await Future<void>.delayed(const Duration(milliseconds: 10));
    final AboutState state = bloc.state;
    if (state is AboutFailure) {
      return <String, Object>{
        'is_failure': true,
        'has_momentum': false,
        'has_process': false,
        'has_os': false,
        'first_err_idx': _parseErrIdx(state.exception.message),
      };
    }
    if (state is AboutPopulated) {
      return <String, Object>{
        'is_failure': false,
        'has_momentum': state.nodeInfo.frontierMomentum != null,
        'has_process': state.nodeInfo.processInfo != null,
        'has_os': state.nodeInfo.osInfo != null,
        'first_err_idx': state.nodeError == null
            ? 0
            : _parseErrIdx(state.nodeError!.message),
      };
    }
    fail('Unexpected AboutState: $state');
  } finally {
    await bloc.close();
  }
}

int _parseErrIdx(String message) {
  return switch (message) {
    'err_1' => 1,
    'err_2' => 2,
    'err_3' => 3,
    _ => -1,
  };
}

Future<Map<String, Object>> _runNotifBlocLifecycle({
  required bool addRepoOk,
  required String dismissMode,
}) async {
  final _MockNotificationsRepository repo = _MockNotificationsRepository();
  when(() => repo.addNotification(any())).thenAnswer((_) async {
    if (!addRepoOk) {
      throw StateError('persist failed');
    }
  });

  final NotificationsBloc bloc = NotificationsBloc(
    repository: repo,
    isDesktopPlatformCheck: () => false,
  );
  try {
    await bloc.addNotification(
      WalletNotification(
        title: 'Test',
        timestamp: 1000,
        details: 'Details',
        type: NotificationType.paymentSent,
      ),
    );
    switch (dismissMode) {
      case 'none':
        await bloc.dismissNotification();
      case 'matching':
        await bloc.dismissNotification(revision: bloc.state.revision);
      case 'stale':
        await bloc.dismissNotification(revision: bloc.state.revision + 99);
      case 'skip':
        break;
      default:
        fail('Unknown dismissMode "$dismissMode"');
    }
    return <String, Object>{
      'has_active': bloc.state.hasActiveNotification,
      'revision': bloc.state.revision,
    };
  } finally {
    await bloc.close();
  }
}

Future<bool> _runWalletOptDesktopNotifs({
  required bool prev,
  required bool desired,
  required bool isMacOs,
  required bool osPermGranted,
  required bool saveOk,
}) async {
  final _MockSharedPrefsService prefs = _MockSharedPrefsService();
  when(
    () => prefs.get(
      kLaunchAtStartupKey,
      defaultValue: any(named: 'defaultValue'),
    ),
  ).thenReturn(false);
  when(
    () => prefs.get(
      kEnableDesktopNotificationsKey,
      defaultValue: any(named: 'defaultValue'),
    ),
  ).thenReturn(prev);
  when(
    () => prefs.get(
      kEnableClipboardWatcherKey,
      defaultValue: any(named: 'defaultValue'),
    ),
  ).thenReturn(false);
  when(
    () => prefs.get(kAutoReceiveKey, defaultValue: any(named: 'defaultValue')),
  ).thenReturn(true);
  when(() => prefs.put(any(), any<dynamic>())).thenAnswer((_) async {
    if (!saveOk) {
      throw StateError('prefs write failed');
    }
  });

  final SettingsWalletOptionsBloc bloc = SettingsWalletOptionsBloc(
    prefsService: prefs,
    isMacOs: isMacOs,
    requestMacOsNotificationPermissions: () async => osPermGranted,
    addNotification: (WalletNotification _) async {},
    reportError: (Object _, String _) async {},
  );
  try {
    bloc.add(
      SettingsWalletOptionsDesktopNotificationsToggled(
        enabled: desired,
        notificationTitle: 'Desktop notifs',
        notificationDetails: 'Toggled',
        errorTitle: 'Error',
      ),
    );
    await Future<void>.delayed(const Duration(milliseconds: 10));
    return bloc.state.enableDesktopNotifications;
  } finally {
    await bloc.close();
  }
}

void main() {
  initHydratedStorage();

  late Directory hiveDirectory;
  int boxCounter = 0;

  setUpAll(() {
    registerFallbackValue(_FakeWalletNotification());
    hiveDirectory = Directory.systemTemp.createTempSync(
      'syrius_bend_node_sync_conformance_',
    );
    Hive
      ..init(hiveDirectory.path)
      ..registerAdapters();
  });

  tearDownAll(() async {
    await Hive.close();
    if (hiveDirectory.existsSync()) {
      hiveDirectory.deleteSync(recursive: true);
    }
  });

  group('Bend conformance: $_kDomain', () {
    test(
      'all Bend oracle vectors match Syrius node, sync, about, notification & '
      'wallet-options logic',
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
            case 'sync_info_status':
              final SyncInfo info = _syncInfo(
                state: _parseSyncState(requireString(args, 'state')),
                currentHeight: requireInt(args, 'current_height'),
                targetHeight: requireInt(args, 'target_height'),
              );
              expectBendMatch(
                domain: _kDomain,
                caseId: caseId,
                actual: <String, Object>{
                  'is_synced': info.isSynced,
                  'is_clearly_behind': info.isClearlyBehind,
                },
                expected: expected,
              );
            case 'sync_cubit_hysteresis':
              final String actual = await _runSyncCubitHysteresis(
                state1: _parseSyncState(requireString(args, 'state1')),
                cur1: requireInt(args, 'cur1'),
                tgt1: requireInt(args, 'tgt1'),
                state2: _parseSyncState(requireString(args, 'state2')),
                cur2: requireInt(args, 'cur2'),
                tgt2: requireInt(args, 'tgt2'),
              );
              expectBendMatch(
                domain: _kDomain,
                caseId: caseId,
                actual: actual,
                expected: expected,
              );
            case 'node_mgmt_confirm_flow':
              final Map<String, Object> actual = await _runNodeMgmtConfirmFlow(
                checkMismatch: requireBool(args, 'check_mismatch'),
                clientChainId: requireInt(args, 'client_chain_id'),
                connectOk: requireBool(args, 'connect_ok'),
                liveChainId: requireInt(args, 'live_chain_id'),
                precommitOk: requireBool(args, 'precommit_ok'),
                rollbackOk: requireBool(args, 'rollback_ok'),
                restoredChainId: requireInt(args, 'restored_chain_id'),
                notifyOk: requireBool(args, 'notify_ok'),
                action: requireString(args, 'action'),
                proceedLiveChainId: requireInt(args, 'proceed_live_chain_id'),
              );
              expectBendMatch(
                domain: _kDomain,
                caseId: caseId,
                actual: actual,
                expected: expected,
              );
            case 'node_mgmt_edit_validation':
              final String actual = await _runNodeMgmtEditValidation(
                newLen: requireInt(args, 'new_len'),
                isDuplicate: requireBool(args, 'is_duplicate'),
              );
              expectBendMatch(
                domain: _kDomain,
                caseId: caseId,
                actual: actual,
                expected: expected,
              );
            case 'about_reduce':
              final Map<String, Object> actual = await _runAboutReduce(
                r1Ok: requireBool(args, 'r1_ok'),
                r2Ok: requireBool(args, 'r2_ok'),
                r3Ok: requireBool(args, 'r3_ok'),
              );
              expectBendMatch(
                domain: _kDomain,
                caseId: caseId,
                actual: actual,
                expected: expected,
              );
            case 'notif_repo_fifo_load':
              final List<int> timestamps = requireIntList(args, 'timestamps');
              final int maxEntries = requireInt(args, 'max_entries');
              final int limit = requireInt(args, 'limit');
              final String boxName = 'bend_notif_fifo_${boxCounter++}';
              final HiveNotificationsRepository repo =
                  HiveNotificationsRepository(boxName: boxName);
              try {
                for (int i = 0; i < timestamps.length; i += 1) {
                  await repo.addNotification(
                    WalletNotification(
                      title: 'N$i',
                      timestamp: timestamps[i],
                      details: 'D$i',
                      type: NotificationType.paymentReceived,
                    ),
                    maxEntries: maxEntries,
                  );
                }
                final List<StoredWalletNotification> loaded = await repo
                    .loadNotifications(limit: limit);
                final List<int> loadedTs = loaded
                    .map(
                      (StoredWalletNotification e) =>
                          e.notification.timestamp ?? 0,
                    )
                    .toList();
                expectBendMatch(
                  domain: _kDomain,
                  caseId: caseId,
                  actual: <String, Object>{
                    'loaded_timestamps': loadedTs,
                    'loaded_len': loadedTs.length,
                  },
                  expected: expected,
                );
              } finally {
                if (Hive.isBoxOpen(boxName)) {
                  await Hive.box<dynamic>(boxName).close();
                }
                await Hive.deleteBoxFromDisk(boxName);
              }
            case 'notif_bloc_lifecycle':
              final Map<String, Object> actual = await _runNotifBlocLifecycle(
                addRepoOk: requireBool(args, 'add_repo_ok'),
                dismissMode: requireString(args, 'dismiss_mode'),
              );
              expectBendMatch(
                domain: _kDomain,
                caseId: caseId,
                actual: actual,
                expected: expected,
              );
            case 'wallet_opt_desktop_notifs':
              final bool actual = await _runWalletOptDesktopNotifs(
                prev: requireBool(args, 'prev'),
                desired: requireBool(args, 'desired'),
                isMacOs: requireBool(args, 'is_macos'),
                osPermGranted: requireBool(args, 'os_perm_granted'),
                saveOk: requireBool(args, 'save_ok'),
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
      'NodeManagementBloc enforces busy mutex, rename/delete selection rules, '
      'and auto-receive rollback on persistence failure',
      () async {
        final _MockNodeManagementRepository repo =
            _MockNodeManagementRepository();
        final List<String> nodes = <String>[
          _kPrevNode,
          _kTargetNode,
          _kCustomNode,
        ];
        final Completer<bool> pendingConnect = Completer<bool>();
        int connectCalls = 0;

        when(repo.shuffleCommunityNodes).thenReturn(null);
        when(repo.getAvailableNodes).thenAnswer((_) => List<String>.of(nodes));
        when(
          () => repo.getCurrentNode(fallback: any(named: 'fallback')),
        ).thenReturn(_kPrevNode);
        when(repo.getClientChainId).thenReturn(1);
        when(repo.getAutoReceive).thenReturn(true);
        when(() => repo.connectToNode(any())).thenAnswer((_) {
          connectCalls += 1;
          return pendingConnect.future;
        });
        when(repo.getFrontierChainId).thenAnswer((_) async => 1);
        when(() => repo.saveSelectedNode(any())).thenAnswer((_) async {});
        when(() => repo.addNotification(any())).thenAnswer((_) async {});
        when(() => repo.reportError(any(), any())).thenAnswer((_) async {});
        when(
          () => repo.updateCustomNode(
            oldNode: any(named: 'oldNode'),
            newNode: any(named: 'newNode'),
          ),
        ).thenAnswer((Invocation invocation) async {
          final String oldN = invocation.namedArguments[#oldNode] as String;
          final String newN = invocation.namedArguments[#newNode] as String;
          final int idx = nodes.indexOf(oldN);
          if (idx >= 0) {
            nodes[idx] = newN;
          }
        });
        when(() => repo.deleteCustomNode(any())).thenAnswer((
          Invocation invocation,
        ) async {
          nodes.remove(invocation.positionalArguments.first as String);
        });
        when(
          () => repo.saveAutoReceive(enabled: any(named: 'enabled')),
        ).thenAnswer((_) async => throw StateError('disk full'));

        final NodeManagementBloc bloc = NodeManagementBloc(
          repository: repo,
          checkChainIdMismatch: false,
          resetHtlcBlockHeightOnChange: false,
          shuffleCommunityNodes: false,
        );
        addTearDown(bloc.close);

        // 1. Busy mutex drops concurrent confirm request.
        bloc
          ..add(const NodeManagementNodeSelected(node: _kTargetNode))
          ..add(
            const NodeManagementConfirmNodeRequested(
              successTitle: 'Ok',
              successDetails: 'Ok',
              connectionUnavailableMessage: 'Fail',
              connectionFailedTitle: 'Fail',
            ),
          )
          ..add(
            const NodeManagementConfirmNodeRequested(
              successTitle: 'Ok',
              successDetails: 'Ok',
              connectionUnavailableMessage: 'Fail',
              connectionFailedTitle: 'Fail',
            ),
          );
        await Future<void>.delayed(Duration.zero);
        expectBendMatch(
          domain: _kDomain,
          caseId: 'node_mgmt_busy_drops_concurrent_confirm',
          actual: connectCalls,
          expected: 1,
        );
        pendingConnect.complete(true);
        await Future<void>.delayed(const Duration(milliseconds: 10));

        // 2. Rename updates selectedNode; delete falls back to confirmedNode.
        const String renamedNode = 'wss://renamed.bend-test.node:35998';
        bloc
          ..add(const NodeManagementNodeSelected(node: _kCustomNode))
          ..add(
            const NodeManagementEditNodeRequested(
              oldNode: _kCustomNode,
              newNode: renamedNode,
              emptyErrorMessage: 'empty',
              tooLongErrorMessage: 'too_long',
              duplicateErrorMessage: 'duplicate',
              errorTitle: 'error',
            ),
          );
        await Future<void>.delayed(const Duration(milliseconds: 10));
        expectBendMatch(
          domain: _kDomain,
          caseId: 'node_mgmt_rename_updates_selected',
          actual: bloc.state.selectedNode,
          expected: renamedNode,
        );

        bloc.add(
          const NodeManagementDeleteNodeRequested(
            node: renamedNode,
            errorTitle: 'error',
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 10));
        expectBendMatch(
          domain: _kDomain,
          caseId: 'node_mgmt_delete_falls_back_to_confirmed',
          actual: bloc.state.selectedNode,
          expected: bloc.state.confirmedNode,
        );

        // 3. Auto-receive toggle rolls back on persistence failure.
        bloc.add(
          const NodeManagementAutoReceiveToggled(
            enabled: false,
            notificationTitle: 'Auto receive',
            notificationDetails: 'Disabled',
            errorTitle: 'Error',
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 10));
        expectBendMatch(
          domain: _kDomain,
          caseId: 'node_mgmt_auto_receive_rollback_on_save_fail',
          actual: bloc.state.autoReceive,
          expected: true,
        );
      },
    );
  });
}
