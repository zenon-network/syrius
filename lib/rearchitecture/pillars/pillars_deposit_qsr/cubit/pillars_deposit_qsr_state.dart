part of 'pillars_deposit_qsr_cubit.dart';

/// Represents the possible statuses for the QSR deposit operation.
enum PillarsDepositQsrStatus{
  /// {@macro initial_status}
  initial,

  /// {@macro loading_status}
  loading,

  /// {@macro failure_status}
  failure,

  /// {@macro success_status}
  success,
}

/// Holds the state for [PillarsDepositQsrCubit], including status, data,
/// and error information.
@JsonSerializable(explicitToJson: true)
class PillarsDepositQsrState extends Equatable {
  /// Creates a new instance of [PillarsDepositQsrState].
  ///
  /// The [status] defaults to [PillarsDepositQsrStatus.initial].
  const PillarsDepositQsrState({
    this.status = PillarsDepositQsrStatus.initial,
    this.data,
    this.error,
  });

  /// {@macro instance_from_json}
  factory PillarsDepositQsrState.fromJson(Map<String, dynamic> json) =>
      _$PillarsDepositQsrStateFromJson(json);

  /// The current status of the QSR deposit operation for Pillar slots.
  final PillarsDepositQsrStatus status;

  /// The response data from the QSR deposit operation.
  final AccountBlockTemplate? data;

  /// An error message representing any error occurring during the operation.
  final Object? error;

  /// {@macro state_copy_with}
  PillarsDepositQsrState copyWith({
    PillarsDepositQsrStatus? status,
    AccountBlockTemplate? data,
    Object? error,
  }) {
    return PillarsDepositQsrState(
      status: status ?? this.status,
      data: data ?? this.data,
      error: error ?? this.error,
    );
  }

  /// {@macro state_to_json}
  Map<String, dynamic> toJson() => _$PillarsDepositQsrStateToJson(this);

  @override
  List<Object?> get props => <Object?>[status, data, error];
}
