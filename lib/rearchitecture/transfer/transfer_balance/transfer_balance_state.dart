part of 'transfer_balance_bloc.dart';

/// Represents the status of the balance fetching process.
enum TransferBalanceStatus {
  /// The initial state before any balance fetching has occurred.
  initial,

  /// Indicates that balance fetching is currently in progress.
  loading,

  /// Indicates that balance fetching was successful.
  success,

  /// Indicates that an error occurred during balance fetching.
  failure,
}

/// Holds the state of [TransferBalanceBloc], including status, data,
/// and error information.
@JsonSerializable(explicitToJson: true)
class TransferBalanceState extends Equatable {
  /// Creates a new instance of [TransferBalanceState].
  ///
  /// The [status] defaults to [TransferBalanceStatus.initial] if not specified.
  const TransferBalanceState({
    this.status = TransferBalanceStatus.initial,
    this.data,
    this.error,
  });

  /// Creates a new instance from a JSON map.
  factory TransferBalanceState.fromJson(Map<String, dynamic> json) =>
      _$TransferBalanceStateFromJson(json);

  /// The current status of the balance fetching operation.
  final TransferBalanceStatus status;

  /// A map of addresses to their corresponding [AccountInfo].
  ///
  /// Contains the balance information for each address.
  final Map<String, AccountInfo>? data;

  /// An object representing any error that occurred during balance fetching.
  final Object? error;

  /// {@macro state_copy_with}
  TransferBalanceState copyWith({
    TransferBalanceStatus? status,
    Map<String, AccountInfo>? data,
    Object? error,
  }) {
    return TransferBalanceState(
      status: status ?? this.status,
      data: data ?? this.data,
      error: error ?? this.error,
    );
  }

  /// {@macro state_to_json}
  Map<String, dynamic> toJson() => _$TransferBalanceStateToJson(this);


  @override
  List<Object?> get props => <Object?>[status, data, error];
}
