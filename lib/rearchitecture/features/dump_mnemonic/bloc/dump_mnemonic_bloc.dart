import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/wallet_file.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'dump_mnemonic_event.dart';
part 'dump_mnemonic_state.dart';

/// Decrypts the active software wallet file to display its mnemonic words.
class DumpMnemonicBloc extends Bloc<DumpMnemonicEvent, DumpMnemonicState> {
  /// Creates a [DumpMnemonicBloc].
  DumpMnemonicBloc({
    Future<WalletFile> Function(String walletPath, String password)?
    decryptWalletFile,
    String? Function()? walletPathProvider,
  }) : _decryptWalletFile = decryptWalletFile ?? WalletUtils.decryptWalletFile,
       _walletPathProvider = walletPathProvider ?? _defaultWalletPath,
       super(const DumpMnemonicInitial()) {
    on<DumpMnemonicSubmitted>(_onSubmitted, transformer: droppable());
    on<DumpMnemonicErrorCleared>(_onErrorCleared);
  }

  final Future<WalletFile> Function(String walletPath, String password)
  _decryptWalletFile;
  final String? Function() _walletPathProvider;

  static String? _defaultWalletPath() => kWalletPath;

  void _onErrorCleared(
    DumpMnemonicErrorCleared event,
    Emitter<DumpMnemonicState> emit,
  ) {
    if (state is DumpMnemonicIncorrectPassword ||
        state is DumpMnemonicFailure) {
      emit(const DumpMnemonicInitial());
    }
  }

  FutureOr<void> _onSubmitted(
    DumpMnemonicSubmitted event,
    Emitter<DumpMnemonicState> emit,
  ) async {
    if (state is DumpMnemonicLoading || event.password.isEmpty) {
      return;
    }

    emit(const DumpMnemonicLoading());
    try {
      final WalletFile walletFile = await _decryptWalletFile(
        _walletPathProvider()!,
        event.password,
      );
      final List<String> seedWords = await walletFile.access<List<String>>(
        (Wallet wallet) async => (wallet as KeyStore).mnemonic!.split(' '),
      );
      emit(DumpMnemonicUnlocked(seedWords: seedWords));
    } on IncorrectPasswordException {
      emit(const DumpMnemonicIncorrectPassword());
    } on Object catch (error, stackTrace) {
      addError(error, stackTrace);
      emit(DumpMnemonicFailure(errorMessage: error.toString()));
    }
  }
}
