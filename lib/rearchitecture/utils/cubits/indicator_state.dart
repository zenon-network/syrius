import 'package:equatable/equatable.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/exceptions/exceptions.dart';

/// Represents the various statuses a cubit's request can have.
enum IndicatorStatus {
  /// {@macro failure_status}
  failure,

  /// {@macro initial_status}
  initial,

  /// {@macro loading_status}
  loading,

  /// {@macro success_status}
  success,
}

/// An abstract class that defines the common structure for cubit states.
///
/// The [IndicatorState] is designed to be generic, with [T] representing the
/// type of data that is managed by each specific cubit state.
///
/// The state includes:
/// - [status]: An [IndicatorStatus] that indicates the current state (loading,
/// success, etc.).
/// - [data]: The data of type [T] that is managed by the cubit.
/// - [error]: An optional [error] object that contains error details if the
/// cubit is in a failure state.
abstract class IndicatorState<T> extends Equatable {
  /// Constructs an [IndicatorState] with a [status], [data], and
  /// [error].
  ///
  /// - The [status] defaults to [IndicatorStatus.initial] if not provided.
  /// - The [data] and [error] can be null, indicating that either no data has
  /// been fetched yet, or an error has occurred.
  const IndicatorState({
    this.status = IndicatorStatus.initial,
    this.data,
    this.error,
  }) : assert(
  (status == IndicatorStatus.initial && data == null && error == null) ||
      (status == IndicatorStatus.success && data != null) ||
      (status == IndicatorStatus.failure && error != null) ||
      (status == IndicatorStatus.loading),
  'when status is initial, data and error must be null, '
      'when status is success, data must be different than null, '
      'when status is failure, error must be different than null',
  );

  /// Represents the current status of the cubit.
  final IndicatorStatus status;

  /// The data of type [T] managed by the cubit, which can be null if no data
  /// has been loaded or if there was an error.
  final T? data;

  /// An optional error object that holds a message to be presented to the user.
  final SyriusException? error;

  /// {@macro state_copy_with}
  IndicatorState<T> copyWith({
    IndicatorStatus? status,
    T? data,
    SyriusException? error,
  });

  @override
  List<Object?> get props => <Object?>[status, data, error];
}
