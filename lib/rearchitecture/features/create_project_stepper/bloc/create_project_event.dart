part of 'create_project_bloc.dart';

/// Base event for [CreateProjectBloc].
sealed class CreateProjectEvent extends Equatable {
  /// Creates a [CreateProjectEvent].
  const CreateProjectEvent();

  @override
  List<Object?> get props => <Object?>[];
}

/// Requests submitting a new Accelerator project on-chain.
final class CreateProjectRequested extends CreateProjectEvent {
  /// Creates a [CreateProjectRequested] event.
  const CreateProjectRequested({
    required this.address,
    required this.name,
    required this.description,
    required this.url,
    required this.znnFundsNeeded,
    required this.qsrFundsNeeded,
  });

  /// Project owner address signing the creation transaction.
  final Address address;

  /// Project title.
  final String name;

  /// Project summary description.
  final String description;

  /// Project URL.
  final String url;

  /// Requested ZNN budget in base units.
  final BigInt znnFundsNeeded;

  /// Requested QSR budget in base units.
  final BigInt qsrFundsNeeded;

  @override
  List<Object?> get props => <Object?>[
    address,
    name,
    description,
    url,
    znnFundsNeeded,
    qsrFundsNeeded,
  ];
}
