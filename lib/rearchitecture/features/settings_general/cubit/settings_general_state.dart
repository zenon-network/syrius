part of 'settings_general_cubit.dart';

/// State emitted by [SettingsGeneralCubit].
@JsonSerializable(explicitToJson: true)
class SettingsGeneralState extends TimerState<SettingsGeneralData> {
  /// Creates a [SettingsGeneralState].
  const SettingsGeneralState({super.status, super.data, super.error});

  /// Creates a [SettingsGeneralState] from JSON.
  factory SettingsGeneralState.fromJson(Map<String, dynamic> json) =>
      _$SettingsGeneralStateFromJson(json);

  @override
  TimerState<SettingsGeneralData> copyWith({
    TimerStatus? status,
    SettingsGeneralData? data,
    SyriusException? error,
  }) {
    return SettingsGeneralState(
      status: status ?? this.status,
      data: data ?? this.data,
      error: error ?? this.error,
    );
  }

  /// Converts this state to JSON.
  Map<String, dynamic> toJson() => _$SettingsGeneralStateToJson(this);
}
