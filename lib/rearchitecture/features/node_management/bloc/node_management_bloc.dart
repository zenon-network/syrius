import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/node_management/repository/node_management_repository.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';

part 'node_management_event.dart';
part 'node_management_state.dart';

/// Manages node selection, custom node CRUD, chain identifier updates, and
/// auto-receive toggle for both Settings NodeManagementCard and
/// NodeManagementScreen.
class NodeManagementBloc
    extends Bloc<NodeManagementEvent, NodeManagementState> {
  /// Creates a [NodeManagementBloc].
  factory NodeManagementBloc({
    required bool checkChainIdMismatch,
    required bool resetHtlcBlockHeightOnChange,
    NodeManagementRepository? repository,
    bool shuffleCommunityNodes = true,
  }) {
    final NodeManagementRepository resolvedRepository =
        repository ?? DefaultNodeManagementRepository();
    if (shuffleCommunityNodes) {
      resolvedRepository.shuffleCommunityNodes();
    }
    final String currentNode = resolvedRepository.getCurrentNode(
      fallback: kEmbeddedNode,
    );
    return NodeManagementBloc._(
      repository: resolvedRepository,
      checkChainIdMismatch: checkChainIdMismatch,
      resetHtlcBlockHeightOnChange: resetHtlcBlockHeightOnChange,
      initialState: NodeManagementState(
        nodes: resolvedRepository.getAvailableNodes(),
        selectedNode: currentNode,
        confirmedNode: currentNode,
        clientChainId: resolvedRepository.getClientChainId(),
        connectedNodeChainId: kNodeChainId ?? kChainIdDefaultValue,
        autoReceive: resolvedRepository.getAutoReceive(),
      ),
    );
  }

  NodeManagementBloc._({
    required this._repository,
    required this._checkChainIdMismatch,
    required this._resetHtlcBlockHeightOnChange,
    required NodeManagementState initialState,
  }) : super(initialState) {
    on<NodeManagementChainIdLoaded>(_onChainIdLoaded);
    on<NodeManagementNodeSelected>(_onNodeSelected);
    on<NodeManagementConfirmNodeRequested>(_onConfirmNodeRequested);
    on<NodeManagementChainIdMismatchResolved>(_onChainIdMismatchResolved);
    on<NodeManagementAddNodeRequested>(_onAddNodeRequested);
    on<NodeManagementEditNodeRequested>(_onEditNodeRequested);
    on<NodeManagementDeleteNodeRequested>(_onDeleteNodeRequested);
    on<NodeManagementChainIdChanged>(_onChainIdChanged);
    on<NodeManagementAutoReceiveToggled>(_onAutoReceiveToggled);
  }

  final NodeManagementRepository _repository;
  final bool _checkChainIdMismatch;
  final bool _resetHtlcBlockHeightOnChange;
  int? _activeNodeConnectionOperationId;
  int _nextNodeConnectionOperationId = 0;

  int? _tryAcquireNodeConnectionOperation() {
    if (_activeNodeConnectionOperationId != null) {
      return null;
    }
    final int operationId = ++_nextNodeConnectionOperationId;
    _activeNodeConnectionOperationId = operationId;
    return operationId;
  }

  void _releaseNodeConnectionOperation(int operationId) {
    if (_activeNodeConnectionOperationId == operationId) {
      _activeNodeConnectionOperationId = null;
    }
  }

  /// Whether [node] is a built-in default node.
  bool isDefaultNode(String node) => _repository.isDefaultNode(node);

  /// Whether [node] is a community node.
  bool isCommunityNode(String node) => _repository.isCommunityNode(node);

  FutureOr<void> _onChainIdLoaded(
    NodeManagementChainIdLoaded event,
    Emitter<NodeManagementState> emit,
  ) async {
    final int nodeChainId = await _repository.getNodeChainId();
    emit(state.copyWith(connectedNodeChainId: nodeChainId));
  }

  void _onNodeSelected(
    NodeManagementNodeSelected event,
    Emitter<NodeManagementState> emit,
  ) {
    emit(state.copyWith(selectedNode: event.node));
  }

  FutureOr<void> _onConfirmNodeRequested(
    NodeManagementConfirmNodeRequested event,
    Emitter<NodeManagementState> emit,
  ) async {
    final int? operationId = _tryAcquireNodeConnectionOperation();
    if (operationId == null) {
      return;
    }
    final String targetNode = state.selectedNode;
    final String previousNode = _repository.getCurrentNode(
      fallback: state.confirmedNode,
    );
    bool connectedToTarget = false;

    emit(
      state.copyWith(isConfirmingNode: true, clearPendingChainIdMismatch: true),
    );

    try {
      final bool connected = await _repository.connectToNode(targetNode);
      if (!connected) {
        throw SyriusException(event.connectionUnavailableMessage);
      }
      connectedToTarget = true;

      int? verifiedChainId;
      if (_checkChainIdMismatch || _resetHtlcBlockHeightOnChange) {
        verifiedChainId = await _repository.getFrontierChainId();
        if (_checkChainIdMismatch && verifiedChainId != state.clientChainId) {
          emit(
            state.copyWith(
              pendingChainIdMismatch: NodeChainIdMismatchPrompt(
                node: targetNode,
                previousNode: previousNode,
                nodeChainId: verifiedChainId,
                clientChainId: state.clientChainId,
                successTitle: event.successTitle,
                successDetails: event.successDetails,
              ),
            ),
          );
          return;
        }
      }

      await _finalizeNodeSwitch(
        emit: emit,
        operationId: operationId,
        targetNode: targetNode,
        verifiedChainId: verifiedChainId,
        successTitle: event.successTitle,
        successDetails: event.successDetails,
        connectionFailedTitle: event.connectionFailedTitle,
      );
    } on Object catch (error, stackTrace) {
      addError(error, stackTrace);
      await _repository.reportError(error, event.connectionFailedTitle);
      await _recoverAfterPreCommitFailure(
        emit: emit,
        previousNode: previousNode,
        targetNode: targetNode,
        connectedToTarget: connectedToTarget,
        connectionFailedTitle: event.connectionFailedTitle,
        connectionUnavailableMessage: event.connectionUnavailableMessage,
      );
    } finally {
      _releaseNodeConnectionOperation(operationId);
    }
  }

  FutureOr<void> _onChainIdMismatchResolved(
    NodeManagementChainIdMismatchResolved event,
    Emitter<NodeManagementState> emit,
  ) async {
    final NodeChainIdMismatchPrompt? prompt = state.pendingChainIdMismatch;
    if (prompt == null) {
      return;
    }
    final int? operationId = _tryAcquireNodeConnectionOperation();
    if (operationId == null) {
      return;
    }

    try {
      if (event.proceed) {
        bool connectedToTarget =
            !prompt.reconnectFailed && !state.isDisconnected;
        emit(state.copyWith(isConfirmingNode: true));
        try {
          int verifiedChainId = prompt.nodeChainId;
          if (!connectedToTarget) {
            final bool connected = await _repository.connectToNode(prompt.node);
            if (!connected) {
              throw SyriusException(
                event.connectionUnavailableMessage ??
                    event.connectionFailedTitle,
              );
            }
            connectedToTarget = true;
            verifiedChainId = await _repository.getFrontierChainId();
            if (_checkChainIdMismatch &&
                verifiedChainId != state.clientChainId &&
                verifiedChainId != prompt.nodeChainId) {
              emit(
                state.copyWith(
                  isDisconnected: false,
                  pendingChainIdMismatch: NodeChainIdMismatchPrompt(
                    node: prompt.node,
                    previousNode: prompt.previousNode,
                    nodeChainId: verifiedChainId,
                    clientChainId: state.clientChainId,
                    successTitle: prompt.successTitle,
                    successDetails: prompt.successDetails,
                  ),
                ),
              );
              return;
            }
          }
          await _finalizeNodeSwitch(
            emit: emit,
            operationId: operationId,
            targetNode: prompt.node,
            verifiedChainId: verifiedChainId,
            successTitle: prompt.successTitle,
            successDetails: prompt.successDetails,
            connectionFailedTitle: event.connectionFailedTitle,
          );
        } on Object catch (error, stackTrace) {
          addError(error, stackTrace);
          await _repository.reportError(error, event.connectionFailedTitle);
          await _recoverAfterPreCommitFailure(
            emit: emit,
            previousNode: prompt.previousNode,
            targetNode: prompt.node,
            connectedToTarget: connectedToTarget,
            connectionFailedTitle: event.connectionFailedTitle,
            connectionUnavailableMessage:
                event.connectionUnavailableMessage ??
                event.connectionFailedTitle,
          );
        }
        return;
      }

      final String previousNode = prompt.previousNode;
      emit(state.copyWith(isConfirmingNode: true));
      try {
        // Close candidate WebSocket while running so a failed dial cannot
        // retain the unconfirmed candidate RPC client.
        _repository.disconnectFromNode();
        final bool reconnected = await _repository.connectToNode(previousNode);
        if (!reconnected) {
          throw SyriusException(
            event.connectionUnavailableMessage ?? event.connectionFailedTitle,
          );
        }
        final int restoredChainId = await _repository.getFrontierChainId();
        kNodeChainId = restoredChainId;
        emit(
          state.copyWith(
            isConfirmingNode: false,
            isDisconnected: false,
            selectedNode: previousNode,
            connectedNodeChainId: restoredChainId,
            clearPendingChainIdMismatch: true,
          ),
        );
      } on Object catch (error, stackTrace) {
        addError(error, stackTrace);
        _repository.disconnectFromNode();
        await _repository.reportError(error, event.connectionFailedTitle);
        emit(
          state.copyWith(
            isConfirmingNode: false,
            isDisconnected: true,
            pendingChainIdMismatch: prompt.copyWith(reconnectFailed: true),
          ),
        );
      }
    } finally {
      _releaseNodeConnectionOperation(operationId);
    }
  }

  Future<void> _finalizeNodeSwitch({
    required Emitter<NodeManagementState> emit,
    required int operationId,
    required String targetNode,
    required int? verifiedChainId,
    required String successTitle,
    required String successDetails,
    required String connectionFailedTitle,
  }) async {
    // Pre-commit phase: any failure throws back to caller for rollback.
    if (_resetHtlcBlockHeightOnChange) {
      final int chainId =
          verifiedChainId ?? await _repository.getFrontierChainId();
      await _repository.resetLastCheckedHtlcBlockHeight(chainId: chainId);
    }
    await _repository.saveSelectedNode(targetNode);

    // Commit boundary crossed: update live state, release the connection
    // operation guard before awaiting post-commit notification delivery, and
    // never roll back on notification failure.
    if (verifiedChainId != null) {
      kNodeChainId = verifiedChainId;
    }
    emit(
      state.copyWith(
        isConfirmingNode: false,
        isDisconnected: false,
        confirmedNode: targetNode,
        selectedNode: targetNode,
        connectedNodeChainId: verifiedChainId ?? state.connectedNodeChainId,
        nodes: _repository.getAvailableNodes(),
        clearPendingChainIdMismatch: true,
        nodeConfirmedNonce: state.nodeConfirmedNonce + 1,
      ),
    );
    _releaseNodeConnectionOperation(operationId);

    try {
      await _repository.addNotification(
        WalletNotification(
          title: successTitle,
          timestamp: DateTime.now().millisecondsSinceEpoch,
          details: successDetails,
          type: NotificationType.changedNode,
        ),
      );
    } on Object catch (error, stackTrace) {
      addError(error, stackTrace);
      await _repository.reportError(error, connectionFailedTitle);
    }
  }

  Future<void> _recoverAfterPreCommitFailure({
    required Emitter<NodeManagementState> emit,
    required String previousNode,
    required String targetNode,
    required bool connectedToTarget,
    required String connectionFailedTitle,
    required String connectionUnavailableMessage,
  }) async {
    if (connectedToTarget && targetNode != previousNode) {
      try {
        _repository.disconnectFromNode();
        final bool restored = await _repository.connectToNode(previousNode);
        if (!restored) {
          throw SyriusException(connectionUnavailableMessage);
        }
        final int restoredChainId = await _repository.getFrontierChainId();
        kNodeChainId = restoredChainId;
        emit(
          state.copyWith(
            isConfirmingNode: false,
            isDisconnected: false,
            selectedNode: previousNode,
            connectedNodeChainId: restoredChainId,
            clearPendingChainIdMismatch: true,
          ),
        );
        return;
      } on Object catch (restoreError, restoreStackTrace) {
        addError(restoreError, restoreStackTrace);
        _repository.disconnectFromNode();
        await _repository.reportError(restoreError, connectionFailedTitle);
        emit(
          state.copyWith(
            isConfirmingNode: false,
            isDisconnected: true,
            selectedNode: previousNode,
            clearPendingChainIdMismatch: true,
          ),
        );
        return;
      }
    }

    emit(
      state.copyWith(
        isConfirmingNode: false,
        selectedNode: previousNode,
        clearPendingChainIdMismatch: true,
      ),
    );
  }

  FutureOr<void> _onAddNodeRequested(
    NodeManagementAddNodeRequested event,
    Emitter<NodeManagementState> emit,
  ) async {
    final List<String> existingNodes = _repository.getAvailableNodes();
    if (existingNodes.contains(event.node)) {
      await _repository.reportError(
        event.duplicateDetails,
        event.duplicateTitle,
      );
      return;
    }

    emit(state.copyWith(isAddingNode: true));
    try {
      await _repository.addCustomNode(event.node);
      await _repository.addNotification(
        WalletNotification(
          title: event.successTitle,
          timestamp: DateTime.now().millisecondsSinceEpoch,
          details: event.successDetails,
          type: NotificationType.changedNode,
        ),
      );
      emit(
        state.copyWith(
          isAddingNode: false,
          nodes: _repository.getAvailableNodes(),
          nodeAddedNonce: state.nodeAddedNonce + 1,
        ),
      );
    } on Object catch (error, stackTrace) {
      addError(error, stackTrace);
      emit(state.copyWith(isAddingNode: false));
      await _repository.reportError(error, event.errorTitle);
    }
  }

  FutureOr<void> _onEditNodeRequested(
    NodeManagementEditNodeRequested event,
    Emitter<NodeManagementState> emit,
  ) async {
    final String newNode = event.newNode;
    if (newNode.isEmpty) {
      emit(
        state.copyWith(
          editNodeError: event.emptyErrorMessage,
          editNodeErrorTarget: event.oldNode,
        ),
      );
      return;
    }
    if (newNode.length > kAddressLabelMaxLength) {
      emit(
        state.copyWith(
          editNodeError: event.tooLongErrorMessage,
          editNodeErrorTarget: event.oldNode,
        ),
      );
      return;
    }
    if (_repository.getAvailableNodes().contains(newNode)) {
      emit(
        state.copyWith(
          editNodeError: event.duplicateErrorMessage,
          editNodeErrorTarget: event.oldNode,
        ),
      );
      return;
    }

    emit(state.copyWith(editingNode: event.oldNode, clearEditNodeError: true));
    try {
      await _repository.updateCustomNode(
        oldNode: event.oldNode,
        newNode: newNode,
      );
      final String updatedSelected = state.selectedNode == event.oldNode
          ? newNode
          : state.selectedNode;
      emit(
        state.copyWith(
          nodes: _repository.getAvailableNodes(),
          selectedNode: updatedSelected,
          clearEditingNode: true,
          clearEditNodeError: true,
          nodeEditedNonce: state.nodeEditedNonce + 1,
        ),
      );
    } on Object catch (error, stackTrace) {
      addError(error, stackTrace);
      emit(state.copyWith(clearEditingNode: true));
      await _repository.reportError(error, event.errorTitle);
    }
  }

  FutureOr<void> _onDeleteNodeRequested(
    NodeManagementDeleteNodeRequested event,
    Emitter<NodeManagementState> emit,
  ) async {
    try {
      await _repository.deleteCustomNode(event.node);
      final List<String> updatedNodes = _repository.getAvailableNodes();
      final String updatedSelected = state.selectedNode == event.node
          ? state.confirmedNode
          : state.selectedNode;
      emit(state.copyWith(nodes: updatedNodes, selectedNode: updatedSelected));
    } on Object catch (error, stackTrace) {
      addError(error, stackTrace);
      await _repository.reportError(error, event.errorTitle);
    }
  }

  FutureOr<void> _onChainIdChanged(
    NodeManagementChainIdChanged event,
    Emitter<NodeManagementState> emit,
  ) async {
    emit(state.copyWith(isConfirmingChainId: true));
    try {
      await _repository.saveClientChainId(event.newChainId);
    } on Object catch (error, stackTrace) {
      addError(error, stackTrace);
      emit(state.copyWith(isConfirmingChainId: false));
      await _repository.reportError(error, event.errorTitle);
      return;
    }

    emit(
      state.copyWith(
        isConfirmingChainId: false,
        clientChainId: _repository.getClientChainId(),
        chainIdChangedNonce: state.chainIdChangedNonce + 1,
      ),
    );

    try {
      await _repository.notifyClientChainIdChanged(event.newChainId);
      await _repository.addNotification(
        WalletNotification(
          title: event.successTitle,
          timestamp: DateTime.now().millisecondsSinceEpoch,
          details: event.successDetails,
          type: NotificationType.changedNode,
        ),
      );
    } on Object catch (error, stackTrace) {
      addError(error, stackTrace);
      await _repository.reportError(error, event.errorTitle);
    }
  }

  FutureOr<void> _onAutoReceiveToggled(
    NodeManagementAutoReceiveToggled event,
    Emitter<NodeManagementState> emit,
  ) async {
    final bool previous = state.autoReceive;
    emit(state.copyWith(autoReceive: event.enabled));
    try {
      await _repository.saveAutoReceive(enabled: event.enabled);
    } on Object catch (error, stackTrace) {
      addError(error, stackTrace);
      emit(state.copyWith(autoReceive: previous));
      await _repository.reportError(error, event.errorTitle);
      return;
    }
    try {
      if (event.enabled) {
        unawaited(_repository.triggerAutoReceive());
      } else {
        _repository.clearAutoReceivePool();
      }
      await _repository.addNotification(
        WalletNotification(
          title: event.notificationTitle,
          details: event.notificationDetails,
          timestamp: DateTime.now().millisecondsSinceEpoch,
          type: NotificationType.paymentSent,
        ),
      );
    } on Object catch (error, stackTrace) {
      addError(error, stackTrace);
      await _repository.reportError(error, event.errorTitle);
    }
  }
}
