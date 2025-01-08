import 'package:equatable/equatable.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/exceptions/exceptions.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// Represents the various statuses a cubit's request can have.
enum CubitWithRefreshOptionStatus {
  /// {@macro failure_status}
  failure,

  /// {@macro loading_status}
  loading,

  /// {@macro success_status}
  success,
}

/// An abstract class that defines the common structure for cubit states.
///
/// The [CubitWithRefreshOptionState] is designed to be generic, with [T]
/// representing the type of data that is managed by each specific cubit state.
///
/// The state includes:
/// - [status]: An [CubitWithRefreshOptionStatus] that indicates the current
/// state (loading, success, etc.).
/// - [data]: The data of type [T] that is managed by the cubit.
/// - [error]: An optional [error] object that contains error details if the
/// cubit is in a failure state.
abstract class CubitWithRefreshOptionState<T> extends Equatable {
  /// Constructs an [CubitWithRefreshOptionState] with a [status], [data], and
  /// [error].
  ///
  /// - The [status] defaults to [CubitWithRefreshOptionStatus.loading] if not
  /// provided.
  /// - The [data] and [error] can be null, indicating that either no data has
  /// been fetched yet, or an error has occurred.
  const CubitWithRefreshOptionState({
    this.address,
    this.status = CubitWithRefreshOptionStatus.loading,
    this.data,
    this.error,
  }) : assert(
      (status == CubitWithRefreshOptionStatus.success && data != null) ||
      (status == CubitWithRefreshOptionStatus.failure && error != null) ||
      (status == CubitWithRefreshOptionStatus.loading),
  'when status is initial, data and error must be null, '
      'when status is success, data must be different than null, '
      'when status is failure, error must be different than null',
  );

  /// The address for witch data is fetched. Can change along the way.
  final Address? address;

  /// Represents the current status of the cubit.
  final CubitWithRefreshOptionStatus status;

  /// The data of type [T] managed by the cubit, which can be null if no data
  /// has been loaded or if there was an error.
  final T? data;

  /// An optional error object that holds a message to be presented to the user.
  final SyriusException? error;

  /// {@macro state_copy_with}
  CubitWithRefreshOptionState<T> copyWith({
    Address? address,
    CubitWithRefreshOptionStatus? status,
    T? data,
    SyriusException? error,
  });

  @override
  List<Object?> get props => <Object?>[status, data, error];
}
