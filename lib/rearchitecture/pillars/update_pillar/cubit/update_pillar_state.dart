part of 'update_pillar_cubit.dart';

/// Represents the possible statuses for the pillar update operation.
enum UpdatePillarStatus{
  /// {@macro initial_status}
  initial,

  /// {@macro loading_status}
  loading,

  /// {@macro failure_status}
  failure,

  /// {@macro success_status}
  success,
}

/// Holds the state for [UpdatePillarCubit], including status, data,
/// and error information.
@JsonSerializable(explicitToJson: true)
class UpdatePillarState extends Equatable {
  /// Creates a new instance of [UpdatePillarState].
  ///
  /// The [status] defaults to [UpdatePillarStatus.initial] if not specified.
  const UpdatePillarState({
    this.status = UpdatePillarStatus.initial,
    this.data,
    this.error,
  });

  /// {@macro instance_from_json}
  factory UpdatePillarState.fromJson(Map<String, dynamic> json) =>
      _$UpdatePillarStateFromJson(json);

  /// The current status of the pillar update operation.
  final UpdatePillarStatus status;

  /// The response data from the pillar update operation.
  final AccountBlockTemplate? data;

  /// An error message representing any error occurring during the operation.
  final Object? error;

  /// {@macro state_copy_with}
  UpdatePillarState copyWith({
    UpdatePillarStatus? status,
    AccountBlockTemplate? data,
    Object? error,
  }) {
    return UpdatePillarState(
      status: status ?? this.status,
      data: data ?? this.data,
      error: error ?? this.error,
    );
  }

  /// {@macro state_to_json}
  Map<String, dynamic> toJson() => _$UpdatePillarStateToJson(this);

  @override
  List<Object?> get props => <Object?>[status, data, error];
}
