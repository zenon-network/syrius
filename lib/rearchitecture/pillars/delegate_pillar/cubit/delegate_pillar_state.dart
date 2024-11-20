part of 'delegate_pillar_cubit.dart';

/// Represents the possible statuses for the delegate pillar operation.
enum DelegatePillarStatus {
  /// {@template initial_status}
  /// The initial state before any action has been taken.
  /// {@endtemplate}
  initial,

  /// {@template loading_status}
  /// Indicates that the data is currently being loaded.
  /// {@endtemplate}
  loading,

  /// {@template failure_status}
  /// Indicates that an error occurred during the data fetching process.
  /// {@endtemplate}
  failure,

  /// {@template success_status}
  /// Indicates that data has been successfully fetched.
  /// {@endtemplate}
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

  /// {@macro instance_from_json}
  factory DelegatePillarState.fromJson(Map<String, dynamic> json) =>
      _$DelegatePillarStateFromJson(json);

  /// The current status of the delegate pillar operation.
  final DelegatePillarStatus status;

  /// The response data from the delegate operation.
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
