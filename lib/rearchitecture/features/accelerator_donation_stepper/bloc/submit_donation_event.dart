part of 'submit_donation_bloc.dart';

/// Base event for [SubmitDonationBloc].
sealed class SubmitDonationEvent extends Equatable {
  /// Creates a [SubmitDonationEvent].
  const SubmitDonationEvent();

  @override
  List<Object?> get props => <Object?>[];
}

/// Requests submitting a ZNN and/or QSR donation to the Accelerator treasury.
final class SubmitDonationRequested extends SubmitDonationEvent {
  /// Creates a [SubmitDonationRequested] event.
  const SubmitDonationRequested({
    required this.address,
    required this.znnAmount,
    required this.qsrAmount,
  });

  /// Wallet address signing and funding the donation transaction(s).
  final Address address;

  /// Amount of ZNN (in base units) to donate.
  final BigInt znnAmount;

  /// Amount of QSR (in base units) to donate.
  final BigInt qsrAmount;

  @override
  List<Object?> get props => <Object?>[address, znnAmount, qsrAmount];
}
