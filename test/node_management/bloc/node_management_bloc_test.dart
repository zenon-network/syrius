import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/node_management/node_management.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';

class MockNodeManagementRepository extends Mock
    implements NodeManagementRepository {}

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

    setUp(() {
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
      when(() => repository.saveSelectedNode(any())).thenAnswer((
        Invocation invocation,
      ) async {
        currentNode = invocation.positionalArguments.first as String;
      });
      when(
        () => repository.resetLastCheckedHtlcBlockHeight(),
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
        () => repository.saveAutoReceive(enabled: any(named: 'enabled')),
      ).thenAnswer((Invocation invocation) async {
        autoReceive = invocation.namedArguments[#enabled] as bool;
      });
      when(() => repository.triggerAutoReceive()).thenAnswer((_) async {});
      when(() => repository.clearAutoReceivePool()).thenReturn(null);
      when(() => repository.addNotification(any())).thenAnswer((_) async {});
      when(() => repository.reportError(any(), any())).thenAnswer((_) async {});
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
        verify(() => repository.resetLastCheckedHtlcBlockHeight()).called(1);
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
        when(() => repository.getNodeChainId()).thenAnswer((_) async => 2);
        when(() => repository.getFrontierChainId()).thenAnswer((_) async => 2);
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
        verify(() => repository.connectToNode(kEmbeddedNode)).called(1);
        verifyNever(() => repository.saveSelectedNode(any()));
        verifyNever(() => repository.resetLastCheckedHtlcBlockHeight());
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
}
