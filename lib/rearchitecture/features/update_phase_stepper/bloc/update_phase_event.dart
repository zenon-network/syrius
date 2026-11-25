part of 'update_phase_bloc.dart';

/// Base event for [UpdatePhaseBloc].
sealed class UpdatePhaseEvent extends Equatable {
  /// Creates an [UpdatePhaseEvent].
  const UpdatePhaseEvent();

  @override
  List<Object?> get props => <Object?>[];
}

/// Requests updating the latest voting phase of an Accelerator project.
final class UpdatePhaseRequested extends UpdatePhaseEvent {
  /// Creates an [UpdatePhaseRequested] event.
  const UpdatePhaseRequested({
    required this.address,
    required this.projectId,
    required this.name,
    required this.description,
    required this.url,
    required this.znnFundsNeeded,
    required this.qsrFundsNeeded,
  });

  /// Project owner address signing the phase update transaction.
  final Address address;

  /// Identifier of the parent project whose active voting phase is updated.
  final Hash projectId;

  /// Updated phase title.
  final String name;

  /// Updated phase description.
  final String description;

  /// Updated phase URL.
  final String url;

  /// Updated ZNN funds requested in base units.
  final BigInt znnFundsNeeded;

  /// Updated QSR funds requested in base units.
  final BigInt qsrFundsNeeded;

  @override
  List<Object?> get props => <Object?>[
    address,
    projectId,
    name,
    description,
    url,
    znnFundsNeeded,
    qsrFundsNeeded,
  ];
}
