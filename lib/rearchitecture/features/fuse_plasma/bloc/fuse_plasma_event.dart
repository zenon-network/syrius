part of 'fuse_plasma_bloc.dart';

/// Base class for all fuse plasma events.
sealed class FusePlasmaEvent extends Equatable {
  /// Creates a new [FusePlasmaEvent].
  const FusePlasmaEvent();

  @override
  List<Object> get props => <Object>[];
}

/// Requests fusing QSR for Plasma.
final class FusePlasmaRequested extends FusePlasmaEvent {
  /// Creates a [FusePlasmaRequested] event.
  const FusePlasmaRequested({
    required this.beneficiaryAddress,
    required this.amount,
  });

  /// Address that will receive the generated Plasma.
  final String beneficiaryAddress;

  /// QSR amount to fuse, without decimals.
  final BigInt amount;

  @override
  List<Object> get props => <Object>[beneficiaryAddress, amount];
}
