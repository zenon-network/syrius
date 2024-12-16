part of 'balance_cubit.dart';

/// The class used by the [BalanceCubit] to send state updates to the
/// listening widgets.
///
/// The data hold, when the status is [TimerStatus.success], is of type
/// [AccountInfo].
@JsonSerializable(explicitToJson: true)
class BalanceState extends TimerState<AccountInfo> {
  /// Constructs a new BalanceState.
  ///
  /// This state uses the default [status], [data], and [error] from the parent
  /// [TimerState] class
  const BalanceState({
    super.status,
    super.data,
    super.error,
  });

  /// {@template instance_from_json}
  /// Creates a new instance from a JSON map.
  /// {@endtemplate}
  factory BalanceState.fromJson(Map<String, dynamic> json) =>
      _$BalanceStateFromJson(json);

  /// {@template state_copy_with}
  /// Creates a copy of the current state with updated values for [status],
  /// [data], or [error], if provided, otherwise retaining the
  /// existing values.
  /// {@endtemplate}
  @override
  TimerState<AccountInfo> copyWith({
    TimerStatus? status,
    AccountInfo? data,
    SyriusException? error,
  }) {
    return BalanceState(
      status: status ?? this.status,
      data: data ?? this.data,
      error: error ?? this.error,
    );
  }

  /// {@template state_to_json}
  /// Converts this instance to a JSON map.
  /// {@endtemplate}
  Map<String, dynamic> toJson() => _$BalanceStateToJson(this);
}
