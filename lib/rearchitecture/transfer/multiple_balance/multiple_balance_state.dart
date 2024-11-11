part of 'multiple_balance_bloc.dart';

/// Represents the status of the balance fetching process.
enum MultipleBalanceStatus {
  /// The initial state before any balance fetching has occurred.
  initial,

  /// Indicates that balance fetching is currently in progress.
  loading,

  /// Indicates that balance fetching was successful.
  success,

  /// Indicates that an error occurred during balance fetching.
  failure,
}

/// Holds the state of [MultipleBalanceBloc], including status, data,
/// and error information.
@JsonSerializable(explicitToJson: true)
class MultipleBalanceState extends Equatable {
  /// Creates a new instance of [MultipleBalanceState].
  ///
  /// The [status] defaults to [MultipleBalanceStatus.initial] if not specified.
  const MultipleBalanceState({
    this.status = MultipleBalanceStatus.initial,
    this.data,
    this.error,
  });

  /// Creates a new instance from a JSON map.
  factory MultipleBalanceState.fromJson(Map<String, dynamic> json) =>
      _$MultipleBalanceStateFromJson(json);

  /// The current status of the balance fetching operation.
  final MultipleBalanceStatus status;

  /// A map of addresses to their corresponding [AccountInfo].
  ///
  /// Contains the balance information for each address.
  final Map<String, AccountInfo>? data;

  /// An object representing any error that occurred during balance fetching.
  final Object? error;

  /// {@macro state_copy_with}
  MultipleBalanceState copyWith({
    MultipleBalanceStatus? status,
    Map<String, AccountInfo>? data,
    Object? error,
  }) {
    return MultipleBalanceState(
      status: status ?? this.status,
      data: data ?? this.data,
      error: error ?? this.error,
    );
  }

  /// {@macro state_to_json}
  Map<String, dynamic> toJson() => _$MultipleBalanceStateToJson(this);


  @override
  List<Object?> get props => <Object?>[status, data, error];
}
