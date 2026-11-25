part of 'dump_mnemonic_bloc.dart';

/// Base class for [DumpMnemonicBloc] events.
sealed class DumpMnemonicEvent extends Equatable {
  /// Creates a [DumpMnemonicEvent].
  const DumpMnemonicEvent();

  @override
  List<Object?> get props => <Object?>[];
}

/// Attempts to decrypt the active wallet file and reveal its mnemonic words.
final class DumpMnemonicSubmitted extends DumpMnemonicEvent {
  /// Creates a [DumpMnemonicSubmitted] event.
  const DumpMnemonicSubmitted({required this.password});

  /// Wallet password entered by the user.
  final String password;

  @override
  List<Object?> get props => <Object?>[password];
}

/// Clears any displayed password error when the user edits the input.
final class DumpMnemonicErrorCleared extends DumpMnemonicEvent {
  /// Creates a [DumpMnemonicErrorCleared] event.
  const DumpMnemonicErrorCleared();
}
