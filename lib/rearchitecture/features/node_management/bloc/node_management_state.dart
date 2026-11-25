part of 'node_management_bloc.dart';

/// Pending chain identifier mismatch details awaiting user confirmation.
class NodeChainIdMismatchPrompt extends Equatable {
  /// Creates a [NodeChainIdMismatchPrompt].
  const NodeChainIdMismatchPrompt({
    required this.node,
    required this.nodeChainId,
    required this.clientChainId,
    required this.successTitle,
    required this.successDetails,
  });

  /// Target node that reported a mismatched chain identifier.
  final String node;

  /// Chain identifier reported by [node].
  final int nodeChainId;

  /// Currently configured client chain identifier.
  final int clientChainId;

  /// Localized notification title if the user confirms switching.
  final String successTitle;

  /// Localized notification details if the user confirms switching.
  final String successDetails;

  @override
  List<Object?> get props => <Object?>[
    node,
    nodeChainId,
    clientChainId,
    successTitle,
    successDetails,
  ];
}

/// State emitted by [NodeManagementBloc].
class NodeManagementState extends Equatable {
  /// Creates a [NodeManagementState].
  const NodeManagementState({
    required this.nodes,
    required this.selectedNode,
    required this.confirmedNode,
    required this.clientChainId,
    required this.connectedNodeChainId,
    required this.autoReceive,
    this.isConfirmingNode = false,
    this.isAddingNode = false,
    this.isConfirmingChainId = false,
    this.editingNode,
    this.editNodeError,
    this.editNodeErrorTarget,
    this.pendingChainIdMismatch,
    this.nodeConfirmedNonce = 0,
    this.nodeAddedNonce = 0,
    this.chainIdChangedNonce = 0,
    this.nodeEditedNonce = 0,
  });

  /// All available node options.
  final List<String> nodes;

  /// Currently selected radio node option.
  final String selectedNode;

  /// Currently active/confirmed connected node.
  final String confirmedNode;

  /// Configured client chain identifier.
  final int clientChainId;

  /// Chain identifier reported by the currently connected node.
  final int connectedNodeChainId;

  /// Auto-receive preference value (used by NodeManagementScreen).
  final bool autoReceive;

  /// Whether node connection confirmation is in progress.
  final bool isConfirmingNode;

  /// Whether adding a custom node is in progress.
  final bool isAddingNode;

  /// Whether saving a new client chain ID is in progress.
  final bool isConfirmingChainId;

  /// Custom node currently being edited, if any.
  final String? editingNode;

  /// Validation error message from the last node edit attempt, if any.
  final String? editNodeError;

  /// Node associated with [editNodeError], if any.
  final String? editNodeErrorTarget;

  /// Pending chain ID mismatch prompt requiring user confirmation, if any.
  final NodeChainIdMismatchPrompt? pendingChainIdMismatch;

  /// Incremented whenever a node switch completes successfully.
  final int nodeConfirmedNonce;

  /// Incremented whenever a custom node is added successfully.
  final int nodeAddedNonce;

  /// Incremented whenever the client chain ID is updated successfully.
  final int chainIdChangedNonce;

  /// Incremented whenever a custom node edit succeeds.
  final int nodeEditedNonce;

  /// Returns a copy of this state with updated fields.
  NodeManagementState copyWith({
    List<String>? nodes,
    String? selectedNode,
    String? confirmedNode,
    int? clientChainId,
    int? connectedNodeChainId,
    bool? autoReceive,
    bool? isConfirmingNode,
    bool? isAddingNode,
    bool? isConfirmingChainId,
    String? editingNode,
    bool clearEditingNode = false,
    String? editNodeError,
    String? editNodeErrorTarget,
    bool clearEditNodeError = false,
    NodeChainIdMismatchPrompt? pendingChainIdMismatch,
    bool clearPendingChainIdMismatch = false,
    int? nodeConfirmedNonce,
    int? nodeAddedNonce,
    int? chainIdChangedNonce,
    int? nodeEditedNonce,
  }) {
    return NodeManagementState(
      nodes: nodes ?? this.nodes,
      selectedNode: selectedNode ?? this.selectedNode,
      confirmedNode: confirmedNode ?? this.confirmedNode,
      clientChainId: clientChainId ?? this.clientChainId,
      connectedNodeChainId: connectedNodeChainId ?? this.connectedNodeChainId,
      autoReceive: autoReceive ?? this.autoReceive,
      isConfirmingNode: isConfirmingNode ?? this.isConfirmingNode,
      isAddingNode: isAddingNode ?? this.isAddingNode,
      isConfirmingChainId: isConfirmingChainId ?? this.isConfirmingChainId,
      editingNode: clearEditingNode ? null : (editingNode ?? this.editingNode),
      editNodeError: clearEditNodeError
          ? null
          : (editNodeError ?? this.editNodeError),
      editNodeErrorTarget: clearEditNodeError
          ? null
          : (editNodeErrorTarget ?? this.editNodeErrorTarget),
      pendingChainIdMismatch: clearPendingChainIdMismatch
          ? null
          : (pendingChainIdMismatch ?? this.pendingChainIdMismatch),
      nodeConfirmedNonce: nodeConfirmedNonce ?? this.nodeConfirmedNonce,
      nodeAddedNonce: nodeAddedNonce ?? this.nodeAddedNonce,
      chainIdChangedNonce: chainIdChangedNonce ?? this.chainIdChangedNonce,
      nodeEditedNonce: nodeEditedNonce ?? this.nodeEditedNonce,
    );
  }

  @override
  List<Object?> get props => <Object?>[
    nodes,
    selectedNode,
    confirmedNode,
    clientChainId,
    connectedNodeChainId,
    autoReceive,
    isConfirmingNode,
    isAddingNode,
    isConfirmingChainId,
    editingNode,
    editNodeError,
    editNodeErrorTarget,
    pendingChainIdMismatch,
    nodeConfirmedNonce,
    nodeAddedNonce,
    chainIdChangedNonce,
    nodeEditedNonce,
  ];
}
