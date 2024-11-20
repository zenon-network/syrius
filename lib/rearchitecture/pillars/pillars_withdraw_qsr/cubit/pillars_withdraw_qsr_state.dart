part of 'pillars_withdraw_qsr_cubit.dart';

/// Represents the possible statuses for the QSR withdrawal operation.
enum PillarsWithdrawQsrStatus{
  /// The initial state before any action has been taken.
  initial,

  /// Indicates that the data is currently being loaded.
  loading,

  /// Indicates that an error occurred during the data fetching process.
  failure,

  /// Indicates that data has been successfully fetched.
  success,
}

/// Holds the state for [PillarsWithdrawQsrCubit], including status, data,
/// and error information.
@JsonSerializable(explicitToJson: true)
class PillarsWithdrawQsrState extends Equatable {
  /// Creates a new instance of [PillarsWithdrawQsrState].
  ///
  /// The [status] defaults to [PillarsWithdrawQsrStatus.initial].
  const PillarsWithdrawQsrState({
    this.status = PillarsWithdrawQsrStatus.initial,
    this.data,
    this.error,
  });

  /// {@macro instance_from_json}
  factory PillarsWithdrawQsrState.fromJson(Map<String, dynamic> json) =>
      _$PillarsWithdrawQsrStateFromJson(json);

  /// The current status of the QSR withdrawal operation for Pillar slots.
  final PillarsWithdrawQsrStatus status;

  /// The response data from the QSR withdrawal operation.
  final AccountBlockTemplate? data;

  /// An error message representing any error occurring during the operation.
  final Object? error;

  /// {@macro state_copy_with}
  PillarsWithdrawQsrState copyWith({
    PillarsWithdrawQsrStatus? status,
    AccountBlockTemplate? data,
    Object? error,
  }) {
    return PillarsWithdrawQsrState(
      status: status ?? this.status,
      data: data ?? this.data,
      error: error ?? this.error,
    );
  }

  /// {@macro state_to_json}
  Map<String, dynamic> toJson() => _$PillarsWithdrawQsrStateToJson(this);

  @override
  List<Object?> get props => <Object?>[status, data, error];
}
