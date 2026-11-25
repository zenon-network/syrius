part of 'create_phase_bloc.dart';

/// Base event for [CreatePhaseBloc].
sealed class CreatePhaseEvent extends Equatable {
  /// Creates a [CreatePhaseEvent].
  const CreatePhaseEvent();

  @override
  List<Object?> get props => <Object?>[];
}

/// Requests adding a new phase to an Accelerator project.
final class CreatePhaseRequested extends CreatePhaseEvent {
  /// Creates a [CreatePhaseRequested] event.
  const CreatePhaseRequested({
    required this.address,
    required this.projectId,
    required this.name,
    required this.description,
    required this.url,
    required this.znnFundsNeeded,
    required this.qsrFundsNeeded,
  });

  /// Project owner address signing the phase creation transaction.
  final Address address;

  /// Identifier of the parent project.
  final Hash projectId;

  /// Phase title.
  final String name;

  /// Phase summary description.
  final String description;

  /// Phase URL.
  final String url;

  /// Requested ZNN funds for this phase in base units.
  final BigInt znnFundsNeeded;

  /// Requested QSR funds for this phase in base units.
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
