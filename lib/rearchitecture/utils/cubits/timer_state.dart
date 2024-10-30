part of 'timer_cubit.dart';

/// Represents the various statuses a cubit's request can have.
///
/// This enum is used to track and emit states with different statuses.
enum TimerStatus {
  /// Indicates that the cubit has encountered an error.
  failure,

  /// The initial state before any data has been loaded.
  initial,

  /// Data is currently being fetched.
  loading,

  /// Data has been successfully loaded.
  success,
}

/// An abstract class that defines the common structure for all cubit states
///
/// The [TimerState] is designed to be generic, with [T] representing the
/// type of data that is managed by each specific cubit state (e.g., balances,
/// transactions, etc.). Subclasses like [BalanceState] extend this class to
/// handle specific data types.
///
/// The state includes:
/// - [status]: A [TimerStatus] that indicates the current state (loading,
/// success, etc.).
/// - [data]: The data of type [T] that is managed by the cubit.
/// - [error]: An optional [error] object that contains error details if the
/// cubit is in a failure state.
abstract class TimerState<T> extends Equatable {
  /// Constructs a [TimerState] with an [status], [data], and
  /// [error].
  ///
  /// - The [status] defaults to [TimerStatus.initial] if not provided.
  /// - The [data] and [error] can be null, indicating that either no data has
  /// been fetched yet, or an error has occurred.
  const TimerState({
    this.status = TimerStatus.initial,
    this.data,
    this.error,
  }) : assert(
          (status == TimerStatus.initial && data == null && error == null) ||
              (status == TimerStatus.success && data != null) ||
              (status == TimerStatus.failure && error != null) ||
              (status == TimerStatus.loading),
          'when status is initial, data and error must be null, '
          'when status is success, data must be different than null, '
          'when status is failure, error must be different than null',
        );

  /// Represents the current status of the cubit, such as loading, success, or
  /// failure.
  final TimerStatus status;

  /// The data of type [T] managed by the cubit, which can be null if no data
  /// has been loaded or if there was an error.
  final T? data;

  /// An optional error object that holds a message to be presented to the user.
  final SyriusException? error;

  /// Creates a copy of the current state with the option to modify specific
  /// fields.
  ///
  /// - [status]: The new status of the cubit (e.g., loading, success).
  /// - [data]: The new data of type [T], if it has changed.
  /// - [error]: The new error, if any occurred.
  TimerState<T> copyWith({
    TimerStatus? status,
    T? data,
    SyriusException? error,
  });

  @override
  List<Object?> get props => <Object?>[status, data, error];
}
