import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:zenon_syrius_wallet_flutter/utils/wallet_file.dart';
import 'package:zenon_syrius_wallet_flutter/utils/wallet_utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'decrypt_wallet_file_event.dart';
part 'decrypt_wallet_file_state.dart';

/// BLoC responsible for decrypting an encrypted wallet file.
class DecryptWalletFileBloc
    extends Bloc<DecryptWalletFileEvent, DecryptWalletFileState> {
  /// Creates a [DecryptWalletFileBloc].
  DecryptWalletFileBloc({
    Future<WalletFile> Function(String path, String password)?
    decryptWalletFile,
  }) : _decryptWalletFile = decryptWalletFile ?? WalletUtils.decryptWalletFile,
       super(const DecryptWalletFileInitial()) {
    on<DecryptWalletFileRequested>(
      _onDecryptRequested,
      transformer: droppable(),
    );
  }

  final Future<WalletFile> Function(String path, String password)
  _decryptWalletFile;

  Future<void> _onDecryptRequested(
    DecryptWalletFileRequested event,
    Emitter<DecryptWalletFileState> emit,
  ) async {
    emit(const DecryptWalletFileLoading());
    try {
      final WalletFile walletFile = await _decryptWalletFile(
        event.path,
        event.password,
      );
      if (isClosed || emit.isDone) {
        try {
          await walletFile.close();
        } on Object catch (_) {
          // Best-effort cleanup when the BLoC closed while decrypting.
        }
        return;
      }
      emit(DecryptWalletFileSuccess(walletFile: walletFile));
    } on IncorrectPasswordException catch (e, stackTrace) {
      addError(e, stackTrace);
      emit(DecryptWalletFileFailure(error: e, isIncorrectPassword: true));
    } on Object catch (e, stackTrace) {
      addError(e, stackTrace);
      emit(DecryptWalletFileFailure(error: e, isIncorrectPassword: false));
    }
  }
}
