part of 'delegate_pillar_cubit.dart';

/// Represents the possible statuses for the delegate pillar operation.
enum DelegatePillarStatus {
  /// The initial state before any action has been taken.
  initial,

  /// Indicates that the data is currently being loaded.
  loading,

  /// Indicates that an error occurred during the data fetching process.
  failure,

  /// Indicates that data has been successfully fetched.
  success,
}

/// Holds the state for [DelegatePillarCubit], including status, data,
/// and error information.
@JsonSerializable(explicitToJson: true)
class DelegatePillarState extends Equatable {
  /// Creates a new instance of [DelegatePillarState].
  ///
  /// The [status] defaults to [DelegatePillarStatus.initial] if not specified.
  const DelegatePillarState({
    this.status = DelegatePillarStatus.initial,
    this.data,
    this.error,
  });

  /// Creates a new instance from a JSON object.
  factory DelegatePillarState.fromJson(Map<String, dynamic> json) =>
      _$DelegatePillarStateFromJson(json);

  /// The current status of the delegate pillar operation.
  final DelegatePillarStatus status;

  /// The response data from the delegate operation.
  ///
  /// Contains the [AccountBlockTemplate] resulting from the delegation.
  final AccountBlockTemplate? data;

  /// An object representing any error occurring during the delegate operation.
  final Object? error;

  /// {@macro state_copy_with}
  DelegatePillarState copyWith({
    DelegatePillarStatus? status,
    AccountBlockTemplate? data,
    Object? error,
  }) {
    return DelegatePillarState(
      status: status ?? this.status,
      data: data ?? this.data,
      error: error ?? this.error,
    );
  }

  /// {@macro state_to_json}
  Map<String, dynamic> toJson() => _$DelegatePillarStateToJson(this);

  @override
  List<Object?> get props => <Object?>[status, data, error];
}
