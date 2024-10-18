part of 'dashboard_cubit.dart';

/// Represents the various statuses a cubit can have during its lifecycle.
///
/// This enum is used to track and emit different states:
/// - [failure]: Indicates that the cubit has encountered an error.
/// - [initial]: The initial state before any data has been loaded.
/// - [loading]: Data is currently being fetched.
/// - [success]: Data has been successfully loaded.
enum CubitStatus {
  failure,
  initial,
  loading,
  success,
}

/// An abstract class that defines the common structure for all cubit states
///
/// The [DashboardState] is designed to be generic, with [T] representing the
/// type of data that is managed by each specific cubit state (e.g., balances,
/// transactions, etc.). Subclasses like `BalanceState` extend this class to
/// handle specific data types.
///
/// The state includes:
/// - [status]: A [CubitStatus] that indicates the current state (loading, success, etc.).
/// - [data]: The data of type [T] that is managed by the cubit.
/// - [error]: An optional [error] object that contains error details if the cubit is in a failure state.
abstract class DashboardState<T> extends Equatable {

  /// Constructs a [DashboardState] with an optional [status], [data], and [error].
  ///
  /// - The [status] defaults to [CubitStatus.initial] if not provided.
  /// - The [data] and [error] can be null, indicating that either no data has been fetched yet, or an error has occurred.
  const DashboardState({
    this.status = CubitStatus.initial,
    this.data,
    this.error,
  });
  /// Represents the current status of the cubit, such as loading, success, or failure.
  final CubitStatus status;

  /// The data of type [T] managed by the cubit, which can be null if no data has been loaded or if there was an error.
  final T? data;

  /// An optional error object that holds error details in case of failure.
  final Object? error;

  /// Creates a copy of the current state with the option to modify specific fields.
  ///
  /// - [status]: The new status of the cubit (e.g., loading, success).
  /// - [data]: The new data of type [T], if it has changed.
  /// - [error]: The new error, if any occurred.
  ///
  /// Returns a new [DashboardState] with the updated fields. Subclasses (like `BalanceState`) will implement this to
  /// ensure type safety and return the appropriate state class.
  DashboardState<T> copyWith({
    CubitStatus? status,
    T? data,
    Object? error,
  });

  @override
  List<Object?> get props => [status, data, error];
}
