part of 'initial_htlc_validation_bloc.dart';

/// Base class for initial HTLC validation states.
sealed class InitialHtlcValidationState extends Equatable {
  /// Creates an [InitialHtlcValidationState].
  const InitialHtlcValidationState();

  @override
  List<Object> get props => <Object>[];
}

/// Initial state before validation is requested.
final class InitialHtlcValidationInitial extends InitialHtlcValidationState {
  /// Creates an [InitialHtlcValidationInitial] state.
  const InitialHtlcValidationInitial();
}

/// Loading state emitted while the initial HTLC is being validated.
final class InitialHtlcValidationLoading extends InitialHtlcValidationState {
  /// Creates an [InitialHtlcValidationLoading] state.
  const InitialHtlcValidationLoading();
}

/// Success state containing the validated HTLC and data required to join it.
final class InitialHtlcValidationDone extends InitialHtlcValidationState {
  /// Creates an [InitialHtlcValidationDone] state.
  const InitialHtlcValidationDone({
    required this._accountInfo,
    required this._htlc,
    required this._token,
  });

  final AccountInfo _accountInfo;
  final HtlcInfo _htlc;
  final Token _token;

  /// Current account information for the address joining the swap.
  AccountInfo get accountInfo => _accountInfo;

  /// The fetched and validated initial HTLC.
  HtlcInfo get htlc => _htlc;

  /// Token locked in the initial HTLC.
  Token get token => _token;

  @override
  List<Object> get props => <Object>[_accountInfo, _htlc, _token];
}

/// Failure state emitted when the initial HTLC is invalid or cannot be fetched.
final class InitialHtlcValidationFailure extends InitialHtlcValidationState {
  /// Creates an [InitialHtlcValidationFailure] state.
  const InitialHtlcValidationFailure({required this._exception});

  final SyriusException _exception;

  /// Error that prevented validation from completing.
  SyriusException get exception => _exception;

  @override
  List<Object> get props => <Object>[_exception];
}
