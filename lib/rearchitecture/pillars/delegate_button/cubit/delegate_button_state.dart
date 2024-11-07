part of 'delegate_button_cubit.dart';

/// Represents the possible statuses for the delegate button operation.
enum DelegateButtonStatus {
  /// The initial state before any action has been taken.
  initial,

  /// Indicates that the data is currently being loaded.
  loading,

  /// Indicates that an error occurred during the data fetching process.
  failure,

  /// Indicates that data has been successfully fetched.
  success,
}

/// Holds the state for [DelegateButtonCubit], including status, data,
/// and error information.
@JsonSerializable(explicitToJson: true)
class DelegateButtonState extends Equatable {
  /// Creates a new instance of [DelegateButtonState].
  ///
  /// The [status] defaults to [DelegateButtonStatus.initial] if not specified.
  const DelegateButtonState({
    this.status = DelegateButtonStatus.initial,
    this.data,
    this.error,
  });

  /// Creates a new instance from a JSON object.
  factory DelegateButtonState.fromJson(Map<String, dynamic> json) =>
      _$DelegateButtonStateFromJson(json);

  /// The current status of the delegate button operation.
  final DelegateButtonStatus status;

  /// The response data from the delegate operation.
  ///
  /// Contains the [AccountBlockTemplate] resulting from the delegation.
  final AccountBlockTemplate? data;

  /// An object representing any error occurring during the delegate operation.
  final Object? error;

  /// {@macro state_copy_with}
  DelegateButtonState copyWith({
    DelegateButtonStatus? status,
    AccountBlockTemplate? data,
    Object? error,
  }) {
    return DelegateButtonState(
      status: status ?? this.status,
      data: data ?? this.data,
      error: error ?? this.error,
    );
  }

  /// {@macro state_to_json}
  Map<String, dynamic> toJson() => _$DelegateButtonStateToJson(this);

  @override
  List<Object?> get props => [status, data, error];
}
