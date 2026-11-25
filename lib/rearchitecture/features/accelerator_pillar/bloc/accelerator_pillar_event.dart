part of 'accelerator_pillar_bloc.dart';

/// Base event for [AcceleratorPillarBloc].
sealed class AcceleratorPillarEvent extends Equatable {
  /// Creates an [AcceleratorPillarEvent].
  const AcceleratorPillarEvent();

  @override
  List<Object?> get props => <Object?>[];
}

/// Requests resolving the Pillar role for [address].
final class AcceleratorPillarRequested extends AcceleratorPillarEvent {
  /// Creates an [AcceleratorPillarRequested] event.
  const AcceleratorPillarRequested({required this.address});

  /// Wallet address to resolve against Pillar owner and producer addresses.
  final Address address;

  @override
  List<Object?> get props => <Object?>[address];
}
