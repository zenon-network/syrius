part of 'node_management_bloc.dart';

/// Base class for [NodeManagementBloc] events.
sealed class NodeManagementEvent extends Equatable {
  /// Creates a [NodeManagementEvent].
  const NodeManagementEvent();

  @override
  List<Object?> get props => <Object?>[];
}

/// Loads initial node chain identifier from the currently connected node.
final class NodeManagementChainIdLoaded extends NodeManagementEvent {
  /// Creates a [NodeManagementChainIdLoaded] event.
  const NodeManagementChainIdLoaded();
}

/// Updates the currently highlighted radio node selection.
final class NodeManagementNodeSelected extends NodeManagementEvent {
  /// Creates a [NodeManagementNodeSelected] event.
  const NodeManagementNodeSelected({required this.node});

  /// Selected node identifier or WebSocket URL.
  final String node;

  @override
  List<Object?> get props => <Object?>[node];
}

/// Confirms connecting to the currently selected node.
final class NodeManagementConfirmNodeRequested extends NodeManagementEvent {
  /// Creates a [NodeManagementConfirmNodeRequested] event.
  const NodeManagementConfirmNodeRequested({
    required this.successTitle,
    required this.successDetails,
    required this.connectionUnavailableMessage,
    required this.connectionFailedTitle,
  });

  /// Localized notification title on success.
  final String successTitle;

  /// Localized notification details on success.
  final String successDetails;

  /// Localized error message if connection returns false.
  final String connectionUnavailableMessage;

  /// Localized error notification title on failure.
  final String connectionFailedTitle;

  @override
  List<Object?> get props => <Object?>[
    successTitle,
    successDetails,
    connectionUnavailableMessage,
    connectionFailedTitle,
  ];
}

/// Resolves a pending chain identifier mismatch confirmation prompt.
final class NodeManagementChainIdMismatchResolved extends NodeManagementEvent {
  /// Creates a [NodeManagementChainIdMismatchResolved] event.
  const NodeManagementChainIdMismatchResolved({
    required this.proceed,
    required this.connectionFailedTitle,
  });

  /// Whether the user chose to proceed despite the chain ID mismatch.
  final bool proceed;

  /// Localized error notification title if fallback reconnect fails.
  final String connectionFailedTitle;

  @override
  List<Object?> get props => <Object?>[proceed, connectionFailedTitle];
}

/// Adds a new custom node URL.
final class NodeManagementAddNodeRequested extends NodeManagementEvent {
  /// Creates a [NodeManagementAddNodeRequested] event.
  const NodeManagementAddNodeRequested({
    required this.node,
    required this.duplicateDetails,
    required this.duplicateTitle,
    required this.successTitle,
    required this.successDetails,
    required this.errorTitle,
  });

  /// Node URL to add.
  final String node;

  /// Localized duplicate node error details.
  final String duplicateDetails;

  /// Localized duplicate node error title.
  final String duplicateTitle;

  /// Localized notification title on success.
  final String successTitle;

  /// Localized notification details on success.
  final String successDetails;

  /// Localized error title on unexpected failure.
  final String errorTitle;

  @override
  List<Object?> get props => <Object?>[
    node,
    duplicateDetails,
    duplicateTitle,
    successTitle,
    successDetails,
    errorTitle,
  ];
}

/// Updates an existing custom node URL.
final class NodeManagementEditNodeRequested extends NodeManagementEvent {
  /// Creates a [NodeManagementEditNodeRequested] event.
  const NodeManagementEditNodeRequested({
    required this.oldNode,
    required this.newNode,
    required this.emptyErrorMessage,
    required this.tooLongErrorMessage,
    required this.duplicateErrorMessage,
    required this.errorTitle,
  });

  /// Existing node URL.
  final String oldNode;

  /// Replacement node URL.
  final String newNode;

  /// Localized error when [newNode] is empty.
  final String emptyErrorMessage;

  /// Localized error when [newNode] exceeds max length.
  final String tooLongErrorMessage;

  /// Localized error when [newNode] already exists.
  final String duplicateErrorMessage;

  /// Localized notification error title on unexpected failure.
  final String errorTitle;

  @override
  List<Object?> get props => <Object?>[
    oldNode,
    newNode,
    emptyErrorMessage,
    tooLongErrorMessage,
    duplicateErrorMessage,
    errorTitle,
  ];
}

/// Deletes a custom node URL from Hive storage.
final class NodeManagementDeleteNodeRequested extends NodeManagementEvent {
  /// Creates a [NodeManagementDeleteNodeRequested] event.
  const NodeManagementDeleteNodeRequested({
    required this.node,
    required this.errorTitle,
  });

  /// Node URL to remove.
  final String node;

  /// Localized error notification title on failure.
  final String errorTitle;

  @override
  List<Object?> get props => <Object?>[node, errorTitle];
}

/// Persists a new client chain identifier.
final class NodeManagementChainIdChanged extends NodeManagementEvent {
  /// Creates a [NodeManagementChainIdChanged] event.
  const NodeManagementChainIdChanged({
    required this.newChainId,
    required this.successTitle,
    required this.successDetails,
    required this.errorTitle,
  });

  /// Target client chain identifier.
  final int newChainId;

  /// Localized notification title on success.
  final String successTitle;

  /// Localized notification details on success.
  final String successDetails;

  /// Localized error title on failure.
  final String errorTitle;

  @override
  List<Object?> get props => <Object?>[
    newChainId,
    successTitle,
    successDetails,
    errorTitle,
  ];
}

/// Toggles auto-receive preference on the standalone Node Management screen.
final class NodeManagementAutoReceiveToggled extends NodeManagementEvent {
  /// Creates a [NodeManagementAutoReceiveToggled] event.
  const NodeManagementAutoReceiveToggled({
    required this.enabled,
    required this.notificationTitle,
    required this.notificationDetails,
    required this.errorTitle,
  });

  /// Desired auto-receive setting.
  final bool enabled;

  /// Localized notification title on success.
  final String notificationTitle;

  /// Localized notification details on success.
  final String notificationDetails;

  /// Localized error title on failure.
  final String errorTitle;

  @override
  List<Object?> get props => <Object?>[
    enabled,
    notificationTitle,
    notificationDetails,
    errorTitle,
  ];
}
