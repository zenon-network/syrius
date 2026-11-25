part of 'accelerator_pillar_bloc.dart';

/// Base state for [AcceleratorPillarBloc].
sealed class AcceleratorPillarState extends Equatable {
  /// Creates an [AcceleratorPillarState].
  const AcceleratorPillarState();

  @override
  List<Object?> get props => <Object?>[];
}

/// Initial state before any Pillar lookup has started.
final class AcceleratorPillarInitial extends AcceleratorPillarState {
  /// Creates an [AcceleratorPillarInitial] state.
  const AcceleratorPillarInitial();
}

/// State emitted while resolving the Pillar for an address.
final class AcceleratorPillarLoading extends AcceleratorPillarState {
  /// Creates an [AcceleratorPillarLoading] state.
  const AcceleratorPillarLoading({required this.address});

  /// Address currently being resolved.
  final Address address;

  @override
  List<Object?> get props => <Object?>[address];
}

/// State emitted once Pillar resolution completes.
///
/// [pillarInfo] is `null` when [address] has no Pillar owner or producer role.
final class AcceleratorPillarPopulated extends AcceleratorPillarState {
  /// Creates an [AcceleratorPillarPopulated] state.
  const AcceleratorPillarPopulated({
    required this.address,
    required this.pillarInfo,
    this.activePillarCount,
  });

  /// Address that was resolved.
  final Address address;

  /// Resolved Pillar info, or `null` if the address has no Pillar role.
  final PillarInfo? pillarInfo;

  /// Active Pillar count if discovered during lookup.
  final int? activePillarCount;

  @override
  List<Object?> get props => <Object?>[address, pillarInfo, activePillarCount];
}

/// State emitted when Pillar resolution fails.
final class AcceleratorPillarFailure extends AcceleratorPillarState {
  /// Creates an [AcceleratorPillarFailure] state.
  const AcceleratorPillarFailure({required this.exception});

  /// The failure describing why resolution did not complete.
  final SyriusException exception;

  @override
  List<Object?> get props => <Object?>[exception];
}
