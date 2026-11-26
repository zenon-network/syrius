import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/auto_receive_tx/auto_receive_tx.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/node_management/node_management.dart';
import 'package:zenon_syrius_wallet_flutter/services/shared_prefs_service.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class MockNodeManagementRepository extends Mock
    implements NodeManagementRepository {}

class MockSharedPrefsService extends Mock implements SharedPrefsService {}

class FakeWalletNotification extends Fake implements WalletNotification {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeWalletNotification());
  });

  group('NodeManagementBloc', () {
    const String customNode = 'wss://custom.node:35998';
    const String editedNode = 'wss://edited.node:35998';

    late MockNodeManagementRepository repository;
    late List<String> nodes;
    late String currentNode;
    late int clientChainId;
    late bool autoReceive;
    late int? previousGlobalNodeChainId;

    setUp(() {
      previousGlobalNodeChainId = kNodeChainId;
      kNodeChainId = 1;
      repository = MockNodeManagementRepository();
      nodes = <String>[kEmbeddedNode, kLocalhostDefaultNodeUrl];
      currentNode = kEmbeddedNode;
      clientChainId = 1;
      autoReceive = true;

      when(() => repository.shuffleCommunityNodes()).thenReturn(null);
      when(
        () => repository.getAvailableNodes(),
      ).thenAnswer((_) => List<String>.of(nodes));
      when(
        () => repository.getCurrentNode(fallback: any(named: 'fallback')),
      ).thenAnswer((_) => currentNode);
      when(
        () => repository.getClientChainId(),
      ).thenAnswer((_) => clientChainId);
      when(() => repository.getNodeChainId()).thenAnswer((_) async => 1);
      when(() => repository.getFrontierChainId()).thenAnswer((_) async => 1);
      when(() => repository.getAutoReceive()).thenAnswer((_) => autoReceive);
      when(() => repository.connectToNode(any())).thenAnswer((_) async => true);
      when(() => repository.disconnectFromNode()).thenReturn(null);
      when(() => repository.saveSelectedNode(any())).thenAnswer((
        Invocation invocation,
      ) async {
        currentNode = invocation.positionalArguments.first as String;
      });
      when(
        () => repository.resetLastCheckedHtlcBlockHeight(
          chainId: any(named: 'chainId'),
        ),
      ).thenAnswer((_) async {});
      when(() => repository.addCustomNode(any())).thenAnswer((
        Invocation invocation,
      ) async {
        nodes.add(invocation.positionalArguments.first as String);
      });
      when(
        () => repository.updateCustomNode(
          oldNode: any(named: 'oldNode'),
          newNode: any(named: 'newNode'),
        ),
      ).thenAnswer((Invocation invocation) async {
        final String oldNode = invocation.namedArguments[#oldNode] as String;
        final String newNode = invocation.namedArguments[#newNode] as String;
        final int idx = nodes.indexOf(oldNode);
        if (idx != -1) {
          nodes[idx] = newNode;
        }
      });
      when(() => repository.deleteCustomNode(any())).thenAnswer((
        Invocation invocation,
      ) async {
        nodes.remove(invocation.positionalArguments.first as String);
      });
      when(() => repository.saveClientChainId(any())).thenAnswer((
        Invocation invocation,
      ) async {
        clientChainId = invocation.positionalArguments.first as int;
      });
      when(
        () => repository.notifyClientChainIdChanged(any()),
      ).thenAnswer((_) async {});
      when(
        () => repository.saveAutoReceive(enabled: any(named: 'enabled')),
      ).thenAnswer((Invocation invocation) async {
        autoReceive = invocation.namedArguments[#enabled] as bool;
      });
      when(() => repository.triggerAutoReceive()).thenAnswer((_) async {});
      when(() => repository.clearAutoReceivePool()).thenReturn(null);
      when(() => repository.addNotification(any())).thenAnswer((_) async {});
      when(() => repository.reportError(any(), any())).thenAnswer((_) async {});
    });

    tearDown(() {
      kNodeChainId = previousGlobalNodeChainId;
    });

    NodeManagementBloc buildBloc({
      bool checkChainIdMismatch = true,
      bool resetHtlcBlockHeightOnChange = true,
    }) => NodeManagementBloc(
      repository: repository,
      checkChainIdMismatch: checkChainIdMismatch,
      resetHtlcBlockHeightOnChange: resetHtlcBlockHeightOnChange,
    );

    blocTest<NodeManagementBloc, NodeManagementState>(
      'confirms node switch, resets HTLC block height, saves, and notifies',
      build: buildBloc,
      act: (NodeManagementBloc bloc) {
        bloc
          ..add(
            const NodeManagementNodeSelected(node: kLocalhostDefaultNodeUrl),
          )
          ..add(
            const NodeManagementConfirmNodeRequested(
              successTitle: 'Connected',
              successDetails: 'Connected',
              connectionUnavailableMessage: 'Failed',
              connectionFailedTitle: 'Connection failed',
            ),
          );
      },
      verify: (_) {
        verify(
          () => repository.connectToNode(kLocalhostDefaultNodeUrl),
        ).called(1);
        verify(
          () => repository.resetLastCheckedHtlcBlockHeight(chainId: 1),
        ).called(1);
        verify(
          () => repository.saveSelectedNode(kLocalhostDefaultNodeUrl),
        ).called(1);
        verify(() => repository.addNotification(any())).called(1);
      },
      expect: () => <Matcher>[
        isA<NodeManagementState>().having(
          (NodeManagementState s) => s.selectedNode,
          'selectedNode',
          kLocalhostDefaultNodeUrl,
        ),
        isA<NodeManagementState>().having(
          (NodeManagementState s) => s.isConfirmingNode,
          'isConfirmingNode',
          true,
        ),
        isA<NodeManagementState>()
            .having(
              (NodeManagementState s) => s.confirmedNode,
              'confirmedNode',
              kLocalhostDefaultNodeUrl,
            )
            .having(
              (NodeManagementState s) => s.nodeConfirmedNonce,
              'nonce',
              1,
            ),
      ],
    );

    blocTest<NodeManagementBloc, NodeManagementState>(
      'emits chain ID mismatch prompt and rolls back when user cancels',
      setUp: () {
        int frontierCalls = 0;
        when(() => repository.getFrontierChainId()).thenAnswer((_) async {
          frontierCalls++;
          return frontierCalls == 1 ? 2 : 1;
        });
      },
      build: buildBloc,
      act: (NodeManagementBloc bloc) async {
        bloc
          ..add(
            const NodeManagementNodeSelected(node: kLocalhostDefaultNodeUrl),
          )
          ..add(
            const NodeManagementConfirmNodeRequested(
              successTitle: 'Connected',
              successDetails: 'Connected',
              connectionUnavailableMessage: 'Failed',
              connectionFailedTitle: 'Connection failed',
            ),
          );
        await Future<void>.delayed(Duration.zero);
        bloc.add(
          const NodeManagementChainIdMismatchResolved(
            proceed: false,
            connectionFailedTitle: 'Connection failed',
          ),
        );
      },
      verify: (_) {
        verify(
          () => repository.connectToNode(kLocalhostDefaultNodeUrl),
        ).called(1);
        verify(() => repository.disconnectFromNode()).called(1);
        verify(() => repository.connectToNode(kEmbeddedNode)).called(1);
        verifyNever(() => repository.saveSelectedNode(any()));
        verifyNever(
          () => repository.resetLastCheckedHtlcBlockHeight(
            chainId: any(named: 'chainId'),
          ),
        );
      },
      expect: () => <Matcher>[
        isA<NodeManagementState>().having(
          (NodeManagementState s) => s.selectedNode,
          'selectedNode',
          kLocalhostDefaultNodeUrl,
        ),
        isA<NodeManagementState>().having(
          (NodeManagementState s) => s.isConfirmingNode,
          'isConfirmingNode',
          true,
        ),
        isA<NodeManagementState>().having(
          (NodeManagementState s) => s.pendingChainIdMismatch?.nodeChainId,
          'mismatch nodeChainId',
          2,
        ),
        isA<NodeManagementState>()
            .having(
              (NodeManagementState s) => s.isConfirmingNode,
              'isConfirmingNode',
              false,
            )
            .having(
              (NodeManagementState s) => s.selectedNode,
              'reverted selectedNode',
              kEmbeddedNode,
            )
            .having(
              (NodeManagementState s) => s.pendingChainIdMismatch,
              'cleared prompt',
              isNull,
            ),
      ],
    );

    blocTest<NodeManagementBloc, NodeManagementState>(
      'passes verified frontier chain ID explicitly to HTLC checkpoint reset',
      setUp: () {
        kNodeChainId = 1;
        clientChainId = 2;
        when(() => repository.getNodeChainId()).thenAnswer((_) async => 1);
        when(() => repository.getFrontierChainId()).thenAnswer((_) async => 2);
      },
      build: buildBloc,
      act: (NodeManagementBloc bloc) {
        bloc
          ..add(
            const NodeManagementNodeSelected(node: kLocalhostDefaultNodeUrl),
          )
          ..add(
            const NodeManagementConfirmNodeRequested(
              successTitle: 'Connected',
              successDetails: 'Connected',
              connectionUnavailableMessage: 'Failed',
              connectionFailedTitle: 'Connection failed',
            ),
          );
      },
      verify: (_) {
        verify(
          () => repository.resetLastCheckedHtlcBlockHeight(chainId: 2),
        ).called(1);
        verifyNever(() => repository.getNodeChainId());
        expect(kNodeChainId, 2);
      },
    );

    blocTest<NodeManagementBloc, NodeManagementState>(
      'restores previous live connection when frontier lookup fails pre-commit',
      setUp: () {
        int frontierCalls = 0;
        when(() => repository.getFrontierChainId()).thenAnswer((_) async {
          frontierCalls++;
          if (frontierCalls == 1) {
            throw StateError('frontier failed');
          }
          return 1;
        });
      },
      build: buildBloc,
      act: (NodeManagementBloc bloc) {
        bloc
          ..add(
            const NodeManagementNodeSelected(node: kLocalhostDefaultNodeUrl),
          )
          ..add(
            const NodeManagementConfirmNodeRequested(
              successTitle: 'Connected',
              successDetails: 'Connected',
              connectionUnavailableMessage: 'Failed',
              connectionFailedTitle: 'Connection failed',
            ),
          );
      },
      verify: (_) {
        verifyInOrder(<Object? Function()>[
          () => repository.connectToNode(kLocalhostDefaultNodeUrl),
          () => repository.disconnectFromNode(),
          () => repository.connectToNode(kEmbeddedNode),
        ]);
        verifyNever(() => repository.saveSelectedNode(any()));
      },
      expect: () => <Matcher>[
        isA<NodeManagementState>().having(
          (NodeManagementState s) => s.selectedNode,
          'selectedNode',
          kLocalhostDefaultNodeUrl,
        ),
        isA<NodeManagementState>().having(
          (NodeManagementState s) => s.isConfirmingNode,
          'isConfirmingNode',
          true,
        ),
        isA<NodeManagementState>()
            .having(
              (NodeManagementState s) => s.isConfirmingNode,
              'isConfirmingNode',
              false,
            )
            .having(
              (NodeManagementState s) => s.selectedNode,
              'selectedNode',
              kEmbeddedNode,
            )
            .having(
              (NodeManagementState s) => s.isDisconnected,
              'isDisconnected',
              false,
            ),
      ],
    );

    blocTest<NodeManagementBloc, NodeManagementState>(
      'emits disconnected state when pre-commit rollback reconnect also fails',
      setUp: () {
        when(
          () => repository.resetLastCheckedHtlcBlockHeight(
            chainId: any(named: 'chainId'),
          ),
        ).thenThrow(StateError('db error'));
        when(
          () => repository.connectToNode(kEmbeddedNode),
        ).thenAnswer((_) async => false);
      },
      build: buildBloc,
      act: (NodeManagementBloc bloc) {
        bloc
          ..add(
            const NodeManagementNodeSelected(node: kLocalhostDefaultNodeUrl),
          )
          ..add(
            const NodeManagementConfirmNodeRequested(
              successTitle: 'Connected',
              successDetails: 'Connected',
              connectionUnavailableMessage: 'Failed',
              connectionFailedTitle: 'Connection failed',
            ),
          );
      },
      verify: (_) {
        verify(() => repository.disconnectFromNode()).called(2);
        verifyNever(() => repository.saveSelectedNode(any()));
      },
      expect: () => <Matcher>[
        isA<NodeManagementState>(),
        isA<NodeManagementState>(),
        isA<NodeManagementState>()
            .having(
              (NodeManagementState s) => s.isDisconnected,
              'isDisconnected',
              true,
            )
            .having(
              (NodeManagementState s) => s.selectedNode,
              'selectedNode',
              kEmbeddedNode,
            ),
      ],
    );

    blocTest<NodeManagementBloc, NodeManagementState>(
      'does not roll back committed node switch when notification throws',
      setUp: () {
        when(
          () => repository.addNotification(any()),
        ).thenThrow(StateError('notification failed'));
      },
      build: buildBloc,
      act: (NodeManagementBloc bloc) {
        bloc
          ..add(
            const NodeManagementNodeSelected(node: kLocalhostDefaultNodeUrl),
          )
          ..add(
            const NodeManagementConfirmNodeRequested(
              successTitle: 'Connected',
              successDetails: 'Connected',
              connectionUnavailableMessage: 'Failed',
              connectionFailedTitle: 'Connection failed',
            ),
          );
      },
      verify: (_) {
        verify(
          () => repository.saveSelectedNode(kLocalhostDefaultNodeUrl),
        ).called(1);
        verifyNever(() => repository.connectToNode(kEmbeddedNode));
        verify(
          () => repository.reportError(any(), 'Connection failed'),
        ).called(1);
      },
      expect: () => <Matcher>[
        isA<NodeManagementState>(),
        isA<NodeManagementState>(),
        isA<NodeManagementState>()
            .having(
              (NodeManagementState s) => s.confirmedNode,
              'confirmedNode',
              kLocalhostDefaultNodeUrl,
            )
            .having(
              (NodeManagementState s) => s.isDisconnected,
              'isDisconnected',
              false,
            )
            .having(
              (NodeManagementState s) => s.nodeConfirmedNonce,
              'nonce',
              1,
            ),
      ],
    );

    blocTest<NodeManagementBloc, NodeManagementState>(
      'preserves mismatch prompt with retry path when cancel reconnect fails',
      setUp: () {
        int previousConnectAttempts = 0;
        int frontierCalls = 0;
        when(() => repository.getFrontierChainId()).thenAnswer((_) async {
          frontierCalls++;
          return frontierCalls == 1 ? 2 : 1;
        });
        when(() => repository.connectToNode(kEmbeddedNode)).thenAnswer((
          _,
        ) async {
          previousConnectAttempts++;
          return previousConnectAttempts > 1;
        });
      },
      build: buildBloc,
      act: (NodeManagementBloc bloc) async {
        bloc
          ..add(
            const NodeManagementNodeSelected(node: kLocalhostDefaultNodeUrl),
          )
          ..add(
            const NodeManagementConfirmNodeRequested(
              successTitle: 'Connected',
              successDetails: 'Connected',
              connectionUnavailableMessage: 'Failed',
              connectionFailedTitle: 'Connection failed',
            ),
          );
        await Future<void>.delayed(Duration.zero);
        bloc.add(
          const NodeManagementChainIdMismatchResolved(
            proceed: false,
            connectionFailedTitle: 'Connection failed',
            connectionUnavailableMessage: 'Previous offline',
          ),
        );
        await Future<void>.delayed(Duration.zero);
        bloc.add(
          const NodeManagementChainIdMismatchResolved(
            proceed: false,
            connectionFailedTitle: 'Connection failed',
            connectionUnavailableMessage: 'Previous offline',
          ),
        );
      },
      verify: (_) {
        verify(() => repository.connectToNode(kEmbeddedNode)).called(2);
        verify(() => repository.getFrontierChainId()).called(2);
        verify(
          () => repository.reportError(any(), 'Connection failed'),
        ).called(1);
      },
      expect: () => <Matcher>[
        isA<NodeManagementState>(),
        isA<NodeManagementState>(),
        isA<NodeManagementState>().having(
          (NodeManagementState s) => s.pendingChainIdMismatch?.reconnectFailed,
          'initial prompt',
          false,
        ),
        isA<NodeManagementState>()
            .having(
              (NodeManagementState s) =>
                  s.pendingChainIdMismatch?.reconnectFailed,
              'retained prompt with reconnectFailed',
              true,
            )
            .having(
              (NodeManagementState s) => s.isDisconnected,
              'isDisconnected',
              true,
            ),
        isA<NodeManagementState>().having(
          (NodeManagementState s) => s.isConfirmingNode,
          'retrying reconnect',
          true,
        ),
        isA<NodeManagementState>()
            .having(
              (NodeManagementState s) => s.pendingChainIdMismatch,
              'cleared after successful retry',
              isNull,
            )
            .having(
              (NodeManagementState s) => s.isDisconnected,
              'restored connection',
              false,
            )
            .having(
              (NodeManagementState s) => s.selectedNode,
              'restored selectedNode',
              kEmbeddedNode,
            ),
      ],
    );

    test(
      'drops concurrent mismatch recovery action while reconnect dial runs',
      () async {
        final Completer<bool> secondReconnectCompleter = Completer<bool>();
        int previousConnectAttempts = 0;
        int frontierCalls = 0;
        when(() => repository.getFrontierChainId()).thenAnswer((_) async {
          frontierCalls++;
          return frontierCalls == 1 ? 2 : 1;
        });
        when(() => repository.connectToNode(kEmbeddedNode)).thenAnswer((_) {
          previousConnectAttempts++;
          if (previousConnectAttempts == 1) {
            return Future<bool>.value(false);
          }
          return secondReconnectCompleter.future;
        });

        final NodeManagementBloc bloc = buildBloc();
        addTearDown(bloc.close);

        // Trigger initial mismatch, then fail the first cancel-reconnect.
        bloc
          ..add(
            const NodeManagementNodeSelected(node: kLocalhostDefaultNodeUrl),
          )
          ..add(
            const NodeManagementConfirmNodeRequested(
              successTitle: 'Connected',
              successDetails: 'Connected',
              connectionUnavailableMessage: 'Failed',
              connectionFailedTitle: 'Connection failed',
            ),
          );
        await expectLater(
          bloc.stream,
          emitsThrough(
            isA<NodeManagementState>().having(
              (NodeManagementState s) => s.pendingChainIdMismatch?.node,
              'pending mismatch',
              kLocalhostDefaultNodeUrl,
            ),
          ),
        );

        bloc.add(
          const NodeManagementChainIdMismatchResolved(
            proceed: false,
            connectionFailedTitle: 'Connection failed',
          ),
        );
        await expectLater(
          bloc.stream,
          emitsThrough(
            isA<NodeManagementState>().having(
              (NodeManagementState s) =>
                  s.pendingChainIdMismatch?.reconnectFailed,
              'reconnectFailed',
              true,
            ),
          ),
        );

        // Start retry reconnect, then concurrently dispatch proceed: true.
        bloc
          ..add(
            const NodeManagementChainIdMismatchResolved(
              proceed: false,
              connectionFailedTitle: 'Connection failed',
            ),
          )
          ..add(
            const NodeManagementChainIdMismatchResolved(
              proceed: true,
              connectionFailedTitle: 'Connection failed',
            ),
          );
        await Future<void>.delayed(Duration.zero);

        secondReconnectCompleter.complete(true);
        await expectLater(
          bloc.stream,
          emitsThrough(
            isA<NodeManagementState>()
                .having(
                  (NodeManagementState s) => s.pendingChainIdMismatch,
                  'cleared mismatch',
                  isNull,
                )
                .having(
                  (NodeManagementState s) => s.confirmedNode,
                  'confirmedNode remains previous',
                  kEmbeddedNode,
                ),
          ),
        );

        // Candidate node was only dialed once initially, never re-dialed or
        // committed by the dropped concurrent proceed event.
        verify(
          () => repository.connectToNode(kLocalhostDefaultNodeUrl),
        ).called(1);
        verifyNever(() => repository.saveSelectedNode(any()));
      },
    );

    test('releases node-switch guard once terminal state is published before '
        'post-commit notification completes', () async {
      final Completer<void> firstNotification = Completer<void>();
      int notificationCalls = 0;
      when(() => repository.addNotification(any())).thenAnswer((_) {
        notificationCalls++;
        return notificationCalls == 1
            ? firstNotification.future
            : Future<void>.value();
      });

      final NodeManagementBloc bloc = buildBloc();
      addTearDown(bloc.close);

      bloc
        ..add(const NodeManagementNodeSelected(node: kLocalhostDefaultNodeUrl))
        ..add(
          const NodeManagementConfirmNodeRequested(
            successTitle: 'Connected',
            successDetails: 'Connected',
            connectionUnavailableMessage: 'Failed',
            connectionFailedTitle: 'Connection failed',
          ),
        );
      await expectLater(
        bloc.stream,
        emitsThrough(
          isA<NodeManagementState>()
              .having(
                (NodeManagementState s) => s.confirmedNode,
                'first confirmed',
                kLocalhostDefaultNodeUrl,
              )
              .having(
                (NodeManagementState s) => s.isConfirmingNode,
                'not confirming',
                false,
              ),
        ),
      );

      // Confirm another node while first notification is still pending.
      bloc
        ..add(const NodeManagementNodeSelected(node: kEmbeddedNode))
        ..add(
          const NodeManagementConfirmNodeRequested(
            successTitle: 'Connected',
            successDetails: 'Connected',
            connectionUnavailableMessage: 'Failed',
            connectionFailedTitle: 'Connection failed',
          ),
        );
      await expectLater(
        bloc.stream,
        emitsThrough(
          isA<NodeManagementState>().having(
            (NodeManagementState s) => s.confirmedNode,
            'second confirmed',
            kEmbeddedNode,
          ),
        ),
      );

      firstNotification.complete();
      await Future<void>.delayed(Duration.zero);
      verify(() => repository.saveSelectedNode(kEmbeddedNode)).called(1);
    });

    test(
      'prompts again if retry proceed observes a different mismatched chain ID',
      () async {
        int frontierCalls = 0;
        when(() => repository.getFrontierChainId()).thenAnswer((_) async {
          frontierCalls++;
          return frontierCalls == 1 ? 2 : 3;
        });
        when(
          () => repository.connectToNode(kEmbeddedNode),
        ).thenAnswer((_) async => false);

        final NodeManagementBloc bloc = buildBloc();
        addTearDown(bloc.close);

        bloc
          ..add(
            const NodeManagementNodeSelected(node: kLocalhostDefaultNodeUrl),
          )
          ..add(
            const NodeManagementConfirmNodeRequested(
              successTitle: 'Connected',
              successDetails: 'Connected',
              connectionUnavailableMessage: 'Failed',
              connectionFailedTitle: 'Connection failed',
            ),
          );
        await expectLater(
          bloc.stream,
          emitsThrough(
            isA<NodeManagementState>().having(
              (NodeManagementState s) => s.pendingChainIdMismatch?.nodeChainId,
              'initial chain 2',
              2,
            ),
          ),
        );

        // Cancel reconnect fails -> banner retained for chain 2.
        bloc.add(
          const NodeManagementChainIdMismatchResolved(
            proceed: false,
            connectionFailedTitle: 'Connection failed',
          ),
        );
        await expectLater(
          bloc.stream,
          emitsThrough(
            isA<NodeManagementState>().having(
              (NodeManagementState s) =>
                  s.pendingChainIdMismatch?.reconnectFailed,
              'reconnectFailed',
              true,
            ),
          ),
        );

        // User clicks Proceed anyway -> node now reports chain 3 -> must prompt
        // again rather than finalizing silently.
        bloc.add(
          const NodeManagementChainIdMismatchResolved(
            proceed: true,
            connectionFailedTitle: 'Connection failed',
          ),
        );
        await expectLater(
          bloc.stream,
          emitsThrough(
            isA<NodeManagementState>()
                .having(
                  (NodeManagementState s) =>
                      s.pendingChainIdMismatch?.nodeChainId,
                  'new prompt chain 3',
                  3,
                )
                .having(
                  (NodeManagementState s) =>
                      s.pendingChainIdMismatch?.reconnectFailed,
                  'fresh prompt',
                  false,
                ),
          ),
        );

        verifyNever(() => repository.saveSelectedNode(any()));
      },
    );

    test(
      'blocks client chain-ID changes while a node switch operation is active',
      () async {
        final Completer<void> saveCompleter = Completer<void>();
        when(
          () => repository.saveSelectedNode(kLocalhostDefaultNodeUrl),
        ).thenAnswer((_) async {
          await saveCompleter.future;
          currentNode = kLocalhostDefaultNodeUrl;
        });

        final NodeManagementBloc bloc = buildBloc();
        addTearDown(bloc.close);

        bloc
          ..add(
            const NodeManagementNodeSelected(node: kLocalhostDefaultNodeUrl),
          )
          ..add(
            const NodeManagementConfirmNodeRequested(
              successTitle: 'Connected',
              successDetails: 'Connected',
              connectionUnavailableMessage: 'Failed',
              connectionFailedTitle: 'Connection failed',
            ),
          );
        await Future<void>.delayed(Duration.zero);

        // Attempt to change clientChainId while node switch is awaiting commit.
        bloc.add(
          const NodeManagementChainIdChanged(
            newChainId: 9,
            successTitle: 'Chain changed',
            successDetails: '1 -> 9',
            errorTitle: 'Chain error',
          ),
        );
        await Future<void>.delayed(Duration.zero);

        saveCompleter.complete();
        await expectLater(
          bloc.stream,
          emitsThrough(
            isA<NodeManagementState>()
                .having(
                  (NodeManagementState s) => s.confirmedNode,
                  'confirmedNode',
                  kLocalhostDefaultNodeUrl,
                )
                .having(
                  (NodeManagementState s) => s.clientChainId,
                  'clientChainId unchanged',
                  1,
                ),
          ),
        );

        verifyNever(() => repository.saveClientChainId(any()));
      },
    );

    test(
      're-reads live frontier chain ID on Proceed even without reconnecting',
      () async {
        int frontierCalls = 0;
        when(() => repository.getFrontierChainId()).thenAnswer((_) async {
          frontierCalls++;
          return frontierCalls == 1 ? 2 : 4;
        });

        final NodeManagementBloc bloc = buildBloc();
        addTearDown(bloc.close);

        bloc
          ..add(
            const NodeManagementNodeSelected(node: kLocalhostDefaultNodeUrl),
          )
          ..add(
            const NodeManagementConfirmNodeRequested(
              successTitle: 'Connected',
              successDetails: 'Connected',
              connectionUnavailableMessage: 'Failed',
              connectionFailedTitle: 'Connection failed',
            ),
          );
        await expectLater(
          bloc.stream,
          emitsThrough(
            isA<NodeManagementState>().having(
              (NodeManagementState s) => s.pendingChainIdMismatch?.nodeChainId,
              'initial mismatch 2',
              2,
            ),
          ),
        );

        // While dialog is open, endpoint changes to chain 4.
        bloc.add(
          const NodeManagementChainIdMismatchResolved(
            proceed: true,
            connectionFailedTitle: 'Connection failed',
          ),
        );
        await expectLater(
          bloc.stream,
          emitsThrough(
            isA<NodeManagementState>()
                .having(
                  (NodeManagementState s) =>
                      s.pendingChainIdMismatch?.nodeChainId,
                  're-prompted with live chain 4',
                  4,
                )
                .having(
                  (NodeManagementState s) =>
                      s.pendingChainIdMismatch?.reconnectFailed,
                  'fresh prompt',
                  false,
                ),
          ),
        );

        verify(() => repository.getFrontierChainId()).called(2);
        verifyNever(() => repository.saveSelectedNode(any()));
      },
    );

    test('never rolls back committed switch when both addNotification and '
        'reportError throw post-commit', () async {
      when(
        () => repository.addNotification(any()),
      ).thenThrow(StateError('notification failed'));
      when(
        () => repository.reportError(any(), any()),
      ).thenThrow(StateError('report failed'));

      final NodeManagementBloc bloc = buildBloc();
      addTearDown(bloc.close);

      bloc
        ..add(const NodeManagementNodeSelected(node: kLocalhostDefaultNodeUrl))
        ..add(
          const NodeManagementConfirmNodeRequested(
            successTitle: 'Connected',
            successDetails: 'Connected',
            connectionUnavailableMessage: 'Failed',
            connectionFailedTitle: 'Connection failed',
          ),
        );
      await expectLater(
        bloc.stream,
        emitsThrough(
          isA<NodeManagementState>()
              .having(
                (NodeManagementState s) => s.confirmedNode,
                'committed node',
                kLocalhostDefaultNodeUrl,
              )
              .having(
                (NodeManagementState s) => s.isDisconnected,
                'still connected',
                false,
              ),
        ),
      );
      await Future<void>.delayed(Duration.zero);

      verifyNever(() => repository.disconnectFromNode());
      verifyNever(() => repository.connectToNode(kEmbeddedNode));
    });

    test('restores previous connection on frontier failure even if reportError '
        'throws', () async {
      int frontierCalls = 0;
      when(() => repository.getFrontierChainId()).thenAnswer((_) async {
        frontierCalls++;
        if (frontierCalls == 1) {
          throw StateError('frontier failed');
        }
        return 1;
      });
      when(
        () => repository.reportError(any(), any()),
      ).thenThrow(StateError('report failed'));

      final NodeManagementBloc bloc = buildBloc();
      addTearDown(bloc.close);

      bloc
        ..add(const NodeManagementNodeSelected(node: kLocalhostDefaultNodeUrl))
        ..add(
          const NodeManagementConfirmNodeRequested(
            successTitle: 'Connected',
            successDetails: 'Connected',
            connectionUnavailableMessage: 'Failed',
            connectionFailedTitle: 'Connection failed',
          ),
        );
      await expectLater(
        bloc.stream,
        emitsThrough(
          isA<NodeManagementState>()
              .having(
                (NodeManagementState s) => s.isConfirmingNode,
                'isConfirmingNode',
                false,
              )
              .having(
                (NodeManagementState s) => s.selectedNode,
                'restored selectedNode',
                kEmbeddedNode,
              )
              .having(
                (NodeManagementState s) => s.isDisconnected,
                'isDisconnected',
                false,
              ),
        ),
      );

      verify(() => repository.connectToNode(kEmbeddedNode)).called(1);
    });

    test(
      'releases operation token after failed chain-ID save before reportError '
      'completes',
      () async {
        final Completer<void> reportCompleter = Completer<void>();
        when(
          () => repository.saveClientChainId(9),
        ).thenThrow(StateError('write failed'));
        when(
          () => repository.reportError(any(), 'Chain error'),
        ).thenAnswer((_) => reportCompleter.future);

        final NodeManagementBloc bloc = buildBloc();
        addTearDown(bloc.close);

        bloc.add(
          const NodeManagementChainIdChanged(
            newChainId: 9,
            successTitle: 'Chain changed',
            successDetails: '1 -> 9',
            errorTitle: 'Chain error',
          ),
        );
        await expectLater(
          bloc.stream,
          emitsThrough(
            isA<NodeManagementState>().having(
              (NodeManagementState s) => s.isConfirmingChainId,
              'isConfirmingChainId cleared',
              false,
            ),
          ),
        );

        // Immediately start a node switch while reportError is still pending.
        bloc
          ..add(
            const NodeManagementNodeSelected(node: kLocalhostDefaultNodeUrl),
          )
          ..add(
            const NodeManagementConfirmNodeRequested(
              successTitle: 'Connected',
              successDetails: 'Connected',
              connectionUnavailableMessage: 'Failed',
              connectionFailedTitle: 'Connection failed',
            ),
          );
        await expectLater(
          bloc.stream,
          emitsThrough(
            isA<NodeManagementState>().having(
              (NodeManagementState s) => s.confirmedNode,
              'confirmedNode',
              kLocalhostDefaultNodeUrl,
            ),
          ),
        );

        reportCompleter.complete();
        await Future<void>.delayed(Duration.zero);
        verify(
          () => repository.saveSelectedNode(kLocalhostDefaultNodeUrl),
        ).called(1);
      },
    );

    blocTest<NodeManagementBloc, NodeManagementState>(
      'adds, edits, and deletes a custom node',
      build: buildBloc,
      act: (NodeManagementBloc bloc) async {
        bloc.add(
          const NodeManagementAddNodeRequested(
            node: customNode,
            duplicateDetails: 'dup',
            duplicateTitle: 'dup',
            successTitle: 'added',
            successDetails: 'added',
            errorTitle: 'err',
          ),
        );
        await Future<void>.delayed(Duration.zero);
        bloc.add(
          const NodeManagementEditNodeRequested(
            oldNode: customNode,
            newNode: editedNode,
            emptyErrorMessage: 'empty',
            tooLongErrorMessage: 'long',
            duplicateErrorMessage: 'dup',
            errorTitle: 'err',
          ),
        );
        await Future<void>.delayed(Duration.zero);
        bloc.add(
          const NodeManagementDeleteNodeRequested(
            node: editedNode,
            errorTitle: 'del err',
          ),
        );
      },
      verify: (_) {
        verify(() => repository.addCustomNode(customNode)).called(1);
        verify(
          () => repository.updateCustomNode(
            oldNode: customNode,
            newNode: editedNode,
          ),
        ).called(1);
        verify(() => repository.deleteCustomNode(editedNode)).called(1);
      },
    );

    blocTest<NodeManagementBloc, NodeManagementState>(
      'updates client chain identifier and notifies',
      build: buildBloc,
      act: (NodeManagementBloc bloc) => bloc.add(
        const NodeManagementChainIdChanged(
          newChainId: 3,
          successTitle: 'Chain changed',
          successDetails: '1 -> 3',
          errorTitle: 'Chain error',
        ),
      ),
      expect: () => <Matcher>[
        isA<NodeManagementState>().having(
          (NodeManagementState s) => s.isConfirmingChainId,
          'isConfirmingChainId',
          true,
        ),
        isA<NodeManagementState>()
            .having(
              (NodeManagementState s) => s.clientChainId,
              'clientChainId',
              3,
            )
            .having(
              (NodeManagementState s) => s.chainIdChangedNonce,
              'nonce',
              1,
            ),
      ],
      verify: (_) {
        verify(() => repository.saveClientChainId(3)).called(1);
        verify(() => repository.notifyClientChainIdChanged(3)).called(1);
      },
    );

    blocTest<NodeManagementBloc, NodeManagementState>(
      'commits client chain ID to UI even if WalletConnect notification fails',
      setUp: () {
        when(
          () => repository.notifyClientChainIdChanged(any()),
        ).thenThrow(StateError('wc failed'));
      },
      build: buildBloc,
      act: (NodeManagementBloc bloc) => bloc.add(
        const NodeManagementChainIdChanged(
          newChainId: 4,
          successTitle: 'Chain changed',
          successDetails: '1 -> 4',
          errorTitle: 'Chain error',
        ),
      ),
      expect: () => <Matcher>[
        isA<NodeManagementState>().having(
          (NodeManagementState s) => s.isConfirmingChainId,
          'isConfirmingChainId',
          true,
        ),
        isA<NodeManagementState>()
            .having(
              (NodeManagementState s) => s.clientChainId,
              'clientChainId',
              4,
            )
            .having(
              (NodeManagementState s) => s.chainIdChangedNonce,
              'nonce',
              1,
            ),
      ],
      verify: (_) {
        verify(() => repository.reportError(any(), 'Chain error')).called(1);
      },
    );

    blocTest<NodeManagementBloc, NodeManagementState>(
      'toggles auto-receive preference',
      build: () => buildBloc(
        checkChainIdMismatch: false,
        resetHtlcBlockHeightOnChange: false,
      ),
      act: (NodeManagementBloc bloc) => bloc.add(
        const NodeManagementAutoReceiveToggled(
          enabled: false,
          notificationTitle: 'Disabled',
          notificationDetails: 'Disabled',
          errorTitle: 'Error',
        ),
      ),
      expect: () => <Matcher>[
        isA<NodeManagementState>().having(
          (NodeManagementState s) => s.autoReceive,
          'autoReceive',
          false,
        ),
      ],
      verify: (_) {
        verify(() => repository.saveAutoReceive(enabled: false)).called(1);
        verify(() => repository.clearAutoReceivePool()).called(1);
      },
    );
  });

  group('DefaultNodeManagementRepository.saveClientChainId', () {
    late int previousSdkChainId;

    setUp(() {
      previousSdkChainId = getChainIdentifier();
      setChainIdentifier();
    });

    tearDown(() {
      setChainIdentifier(chainIdentifier: previousSdkChainId);
    });

    test(
      'leaves SDK chain identifier unchanged when prefs.put throws',
      () async {
        final MockSharedPrefsService prefs = MockSharedPrefsService();
        when(
          () => prefs.put(kChainIdKey, 2),
        ).thenThrow(StateError('disk full'));

        final DefaultNodeManagementRepository repository =
            DefaultNodeManagementRepository(prefsService: prefs);

        await expectLater(
          () => repository.saveClientChainId(2),
          throwsStateError,
        );
        expect(getChainIdentifier(), 1);
      },
    );

    test('updates SDK chain identifier after prefs.put succeeds', () async {
      final MockSharedPrefsService prefs = MockSharedPrefsService();
      when(() => prefs.put(kChainIdKey, 2)).thenAnswer((_) async {});

      final DefaultNodeManagementRepository repository =
          DefaultNodeManagementRepository(prefsService: prefs);

      await repository.saveClientChainId(2);
      verify(() => prefs.put(kChainIdKey, 2)).called(1);
      expect(getChainIdentifier(), 2);
    });
  });

  group('DefaultNodeManagementRepository.clearAutoReceivePool', () {
    test(
      'delegates to AutoReceiveTxWorker.clearPool and emits pendingCount 0',
      () async {
        final AutoReceiveTxWorker worker = AutoReceiveTxWorker(
          isAutoReceiveEnabled: () => true,
          isHtlcAutoUnlocking: () => false,
          onRefreshPendingTransactions: () {},
          onTransactionReceived: () {},
          onNotification: (_) {},
        );
        final bool hadPrevious = sl.isRegistered<AutoReceiveTxWorker>();
        final AutoReceiveTxWorker? previous = hadPrevious
            ? sl<AutoReceiveTxWorker>()
            : null;
        if (hadPrevious) {
          sl.unregister<AutoReceiveTxWorker>();
        }
        sl.registerSingleton<AutoReceiveTxWorker>(worker);
        addTearDown(() async {
          if (sl.isRegistered<AutoReceiveTxWorker>()) {
            sl.unregister<AutoReceiveTxWorker>();
          }
          if (previous != null) {
            sl.registerSingleton<AutoReceiveTxWorker>(previous);
          }
          await worker.close();
        });

        worker.pool.add(Hash.digest(<int>[4, 5, 6]));
        worker.emit(const AutoReceiveTxState(pendingCount: 1));
        expect(worker.state.pendingCount, 1);

        final DefaultNodeManagementRepository repository =
            DefaultNodeManagementRepository();

        final Future<void> stateCleared = expectLater(
          worker.stream,
          emits(const AutoReceiveTxState()),
        );

        repository.clearAutoReceivePool();
        await stateCleared;

        expect(worker.pool, isEmpty);
        expect(worker.state.pendingCount, 0);
      },
    );
  });
}
