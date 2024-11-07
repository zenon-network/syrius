part of 'disassemble_pillar_cubit.dart';

/// Represents the possible statuses for the disassemble pillar operation.
enum DisassemblePillarStatus {
  /// The initial state before any action has been taken.
  initial,

  /// Indicates that the data is currently being loaded.
  loading,

  /// Indicates that an error occurred during the data fetching process.
  failure,

  /// Indicates that data has been successfully fetched.
  success,
}

/// Holds the state for [DisassemblePillarCubit], including status, data,
/// and error information.
@JsonSerializable(explicitToJson: true)
class DisassemblePillarState extends Equatable {
  /// Creates a new instance of [DisassemblePillarState].
  ///
  /// The [status] defaults to [DisassemblePillarStatus.initial].
  const DisassemblePillarState({
    this.status = DisassemblePillarStatus.initial,
    this.data,
    this.error,
  });

  /// Creates a new instance from a JSON map.
  factory DisassemblePillarState.fromJson(Map<String, dynamic> json) =>
      _$DisassemblePillarStateFromJson(json);

  /// The current status of the disassemble pillar operation.
  final DisassemblePillarStatus status;

  /// The response data from the disassemble operation.
  ///
  /// Contains the [AccountBlockTemplate] resulting from the disassembly.
  final AccountBlockTemplate? data;

  /// An error message representing any error occurring during the operation.
  final Object? error;

  /// {@macro state_copy_with}
  DisassemblePillarState copyWith({
    DisassemblePillarStatus? status,
    AccountBlockTemplate? data,
    Object? error,
  }) {
    return DisassemblePillarState(
      status: status ?? this.status,
      data: data ?? this.data,
      error: error ?? this.error,
    );
  }

  /// {@macro state_to_json}
  Map<String, dynamic> toJson() => _$DisassemblePillarStateToJson(this);

  @override
  List<Object?> get props => <Object?>[status, data, error];
}
