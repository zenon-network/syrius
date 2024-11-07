part of 'pillars_deposit_qsr_cubit.dart';

/// Represents the possible statuses for the QSR deposit operation.
enum PillarsDepositQsrStatus{
  /// The initial state before any action has been taken.
  initial,

  /// Indicates that the data is currently being loaded.
  loading,

  /// Indicates that an error occurred during the data fetching process.
  failure,

  /// Indicates that data has been successfully fetched.
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

  /// Creates a new instance from a JSON map.
  factory PillarsDepositQsrState.fromJson(Map<String, dynamic> json) =>
      _$PillarsDepositQsrStateFromJson(json);

  /// The current status of the QSR deposit operation for Pillar slots.
  final PillarsDepositQsrStatus status;

  /// The response data from the QSR deposit operation.
  ///
  /// Contains the [AccountBlockTemplate] resulting from the deposit.
  final AccountBlockTemplate? data;

  /// An error message representing any error occurring during the operation.
  final Object? error;

  ///
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
