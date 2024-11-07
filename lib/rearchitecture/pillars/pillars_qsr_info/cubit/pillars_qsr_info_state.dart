part of 'pillars_qsr_info_cubit.dart';

/// Represents the possible statuses for the QSR management operation.
enum PillarsQsrInfoStatus {
  /// The initial state before any action has been taken.
  initial,

  /// Indicates that the data is currently being loaded.
  loading,

  /// Indicates that an error occurred during the data fetching process.
  failure,

  /// Indicates that data has been successfully fetched.
  success,
}

/// Holds the state for [PillarsQsrInfoCubit], including status, data,
/// and error information.
@JsonSerializable(explicitToJson: true)
class PillarsQsrInfoState extends Equatable {
  /// Creates a new instance of [PillarsQsrInfoState].
  ///
  /// The [status] defaults to [PillarsQsrInfoStatus.initial] if not specified.
  const PillarsQsrInfoState({
    this.status = PillarsQsrInfoStatus.initial,
    this.data,
    this.error,
  });

  /// Creates a new instance from a JSON map.
  factory PillarsQsrInfoState.fromJson(Map<String, dynamic> json) =>
      _$PillarsQsrInfoStateFromJson(json);

  /// The current status of the QSR management information operation.
  final PillarsQsrInfoStatus status;

  /// The QSR management information data.
  ///
  /// Contains the [PillarsQsrInfo] object with deposit and cost information.
  final PillarsQsrInfo? data;

  /// An error message representing any error occurring during the operation.
  final Object? error;

  /// {@macro state_copy_with}
  PillarsQsrInfoState copyWith({
    PillarsQsrInfoStatus? status,
    PillarsQsrInfo? data,
    Object? error,
  }) {
    return PillarsQsrInfoState(
      status: status ?? this.status,
      data: data ?? this.data,
      error: error ?? this.error,
    );
  }

  /// {@macro state_to_json}
  Map<String, dynamic> toJson() => _$PillarsQsrInfoStateToJson(this);

  @override
  List<Object?> get props => <Object?>[status, data, error];
}
