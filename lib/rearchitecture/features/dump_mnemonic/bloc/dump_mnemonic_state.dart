part of 'dump_mnemonic_bloc.dart';

/// Base state for [DumpMnemonicBloc].
sealed class DumpMnemonicState extends Equatable {
  /// Creates a [DumpMnemonicState].
  const DumpMnemonicState();

  @override
  List<Object?> get props => <Object?>[];
}

/// Initial locked state awaiting password entry.
final class DumpMnemonicInitial extends DumpMnemonicState {
  /// Creates a [DumpMnemonicInitial] state.
  const DumpMnemonicInitial();
}

/// State emitted while decrypting the wallet file.
final class DumpMnemonicLoading extends DumpMnemonicState {
  /// Creates a [DumpMnemonicLoading] state.
  const DumpMnemonicLoading();
}

/// State emitted when the wallet mnemonic words have been decrypted.
final class DumpMnemonicUnlocked extends DumpMnemonicState {
  /// Creates a [DumpMnemonicUnlocked] state.
  const DumpMnemonicUnlocked({required this.seedWords});

  /// Ordered mnemonic words for display in `SeedGrid`.
  final List<String> seedWords;

  @override
  List<Object?> get props => <Object?>[seedWords];
}

/// State emitted when the entered password does not match the wallet file.
final class DumpMnemonicIncorrectPassword extends DumpMnemonicState {
  /// Creates a [DumpMnemonicIncorrectPassword] state.
  const DumpMnemonicIncorrectPassword();
}

/// State emitted when decrypting or reading the mnemonic fails unexpectedly.
final class DumpMnemonicFailure extends DumpMnemonicState {
  /// Creates a [DumpMnemonicFailure] state.
  const DumpMnemonicFailure({required this.errorMessage});

  /// Error details to display under the password field.
  final String errorMessage;

  @override
  List<Object?> get props => <Object?>[errorMessage];
}
