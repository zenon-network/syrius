part of 'pillars_deploy_cubit.dart';

/// Represents the possible statuses for the pillar deployment operation.
enum PillarsDeployStatus {
  /// The initial state before any action has been taken.
  initial,

  /// Indicates that the data is currently being loaded.
  loading,

  /// Indicates that an error occurred during the data fetching process.
  failure,

  /// Indicates that data has been successfully fetched.
  success,
}

/// Holds the state for [PillarsDeployCubit], including status, data,
/// and error information.
@JsonSerializable(explicitToJson: true)
class PillarsDeployState extends Equatable {
  /// Creates a new instance of [PillarsDeployState].
  ///
  /// The [status] defaults to [PillarsDeployStatus.initial] if not specified.
  const PillarsDeployState({
    this.status = PillarsDeployStatus.initial,
    this.data,
    this.error,
  });

  /// {@macro instance_from_json}
  factory PillarsDeployState.fromJson(Map<String, dynamic> json) =>
      _$PillarsDeployStateFromJson(json);

  /// The current status of the pillar deployment operation.
  final PillarsDeployStatus status;

  /// The response data from the pillar deployment operation.
  final AccountBlockTemplate? data;

  /// An error message representing any error occurring during the operation.
  final Object? error;

  /// {@macro state_copy_with}
  PillarsDeployState copyWith({
    PillarsDeployStatus? status,
    AccountBlockTemplate? data,
    Object? error,
  }) {
    return PillarsDeployState(
      status: status ?? this.status,
      data: data ?? this.data,
      error: error ?? this.error,
    );
  }

  /// {@macro state_to_json}
  Map<String, dynamic> toJson() => _$PillarsDeployStateToJson(this);

  @override
  List<Object?> get props => <Object?>[status, data, error];
}
