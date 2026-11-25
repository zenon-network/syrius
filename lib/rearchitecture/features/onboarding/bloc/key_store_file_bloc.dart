import 'dart:async';
import 'dart:convert';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:zenon_syrius_wallet_flutter/utils/init_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/wallet_file.dart';
import 'package:zenon_syrius_wallet_flutter/utils/wallet_utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'key_store_file_event.dart';
part 'key_store_file_state.dart';

/// BLoC responsible for creating a keystore wallet file and initializing
/// the decrypted wallet session.
class KeyStoreFileBloc extends Bloc<KeyStoreFileEvent, KeyStoreFileState> {
  /// Creates a [KeyStoreFileBloc].
  KeyStoreFileBloc({
    Future<void> Function(String mnemonic, String password)?
    createKeyStoreWalletFile,
    Future<void> Function(List<int> cipherKey)? initWalletAfterDecryption,
    WalletFile? Function()? getWalletFile,
  }) : _createKeyStoreWalletFile =
           createKeyStoreWalletFile ?? WalletUtils.createKeyStoreWalletFile,
       _initWalletAfterDecryption =
           initWalletAfterDecryption ?? InitUtils.initWalletAfterDecryption,
       _getWalletFile = getWalletFile ?? _defaultGetWalletFile,
       super(const KeyStoreFileInitial()) {
    on<KeyStoreFileCreateRequested>(
      _onCreateRequested,
      transformer: droppable(),
    );
  }

  final Future<void> Function(String mnemonic, String password)
  _createKeyStoreWalletFile;
  final Future<void> Function(List<int> cipherKey) _initWalletAfterDecryption;
  final WalletFile? Function() _getWalletFile;

  Future<void> _onCreateRequested(
    KeyStoreFileCreateRequested event,
    Emitter<KeyStoreFileState> emit,
  ) async {
    emit(const KeyStoreFileLoading());
    try {
      await _createKeyStoreWalletFile(event.mnemonic, event.password);
      await _initWalletAfterDecryption(
        Crypto.digest(utf8.encode(event.password)),
      );
      final WalletFile? walletFile = _getWalletFile();
      if (walletFile is! KeyStoreWalletFile) {
        throw StateError('Created wallet file is not a KeyStoreWalletFile');
      }
      emit(KeyStoreFileSuccess(walletFile: walletFile));
    } on Object catch (error, stackTrace) {
      addError(error, stackTrace);
      emit(KeyStoreFileFailure(error));
    }
  }

  static WalletFile? _defaultGetWalletFile() => kWalletFile;
}
