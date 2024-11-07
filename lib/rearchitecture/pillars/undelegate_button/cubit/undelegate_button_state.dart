part of 'undelegate_button_cubit.dart';

/// Represents the possible statuses for the undelegate button operation.
enum UndelegateButtonStatus {
  /// The initial state before any action has been taken.
  initial,

  /// Indicates that the data is currently being loaded.
  loading,

  /// Indicates that an error occurred during the data fetching process.
  failure,

  /// Indicates that data has been successfully fetched.
  success,
}

/// Holds the state for [UndelegateButtonCubit], including status, data,
/// and error information.
@JsonSerializable(explicitToJson: true)
class UndelegateButtonState extends Equatable {
  /// Creates a new instance of [UndelegateButtonState].
  ///
  /// The [status] defaults to [UndelegateButtonStatus.initial].
  const UndelegateButtonState({
    this.status = UndelegateButtonStatus.initial,
    this.data,
    this.error,
  });

  /// Creates a new instance from a JSON map.
  factory UndelegateButtonState.fromJson(Map<String, dynamic> json) =>
      _$UndelegateButtonStateFromJson(json);

  /// The current status of the undelegate button operation.
  final UndelegateButtonStatus status;

  /// The response data from the undelegation operation.
  ///
  /// Contains the [AccountBlockTemplate] resulting from the undelegation.
  final AccountBlockTemplate? data;

  /// An error message representing any error occurring during the operation.
  final Object? error;

  /// {@macro state_copy_with}
  UndelegateButtonState copyWith({
    UndelegateButtonStatus? status,
    AccountBlockTemplate? data,
    Object? error,
  }) {
    return UndelegateButtonState(
      status: status ?? this.status,
      data: data ?? this.data,
      error: error ?? this.error,
    );
  }

  /// {@macro state_to_json}
  Map<String, dynamic> toJson() => _$UndelegateButtonStateToJson(this);

  @override
  List<Object?> get props => <Object?>[status, data, error];
}
