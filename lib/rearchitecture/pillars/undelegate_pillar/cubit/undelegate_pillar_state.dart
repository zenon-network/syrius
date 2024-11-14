part of 'undelegate_pillar_cubit.dart';

/// Represents the possible statuses for the undelegate pillar operation.
enum UndelegatePillarStatus {
  /// The initial state before any action has been taken.
  initial,

  /// Indicates that the data is currently being loaded.
  loading,

  /// Indicates that an error occurred during the data fetching process.
  failure,

  /// Indicates that data has been successfully fetched.
  success,
}

/// Holds the state for [UndelegatePillarCubit], including status, data,
/// and error information.
@JsonSerializable(explicitToJson: true)
class UndelegatePillarState extends Equatable {
  /// Creates a new instance of [UndelegatePillarState].
  ///
  /// The [status] defaults to [UndelegatePillarStatus.initial].
  const UndelegatePillarState({
    this.status = UndelegatePillarStatus.initial,
    this.data,
    this.error,
  });

  /// Creates a new instance from a JSON map.
  factory UndelegatePillarState.fromJson(Map<String, dynamic> json) =>
      _$UndelegatePillarStateFromJson(json);

  /// The current status of the undelegate pillar operation.
  final UndelegatePillarStatus status;

  /// The response data from the undelegation operation.
  ///
  /// Contains the [AccountBlockTemplate] resulting from the undelegation.
  final AccountBlockTemplate? data;

  /// An error message representing any error occurring during the operation.
  final Object? error;

  /// {@macro state_copy_with}
  UndelegatePillarState copyWith({
    UndelegatePillarStatus? status,
    AccountBlockTemplate? data,
    Object? error,
  }) {
    return UndelegatePillarState(
      status: status ?? this.status,
      data: data ?? this.data,
      error: error ?? this.error,
    );
  }

  /// {@macro state_to_json}
  Map<String, dynamic> toJson() => _$UndelegatePillarStateToJson(this);

  @override
  List<Object?> get props => <Object?>[status, data, error];
}
