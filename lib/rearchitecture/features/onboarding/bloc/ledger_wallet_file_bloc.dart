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

part 'ledger_wallet_file_event.dart';
part 'ledger_wallet_file_state.dart';

/// BLoC responsible for creating a Ledger hardware wallet file and
/// initializing the wallet session.
class LedgerWalletFileBloc
    extends Bloc<LedgerWalletFileEvent, LedgerWalletFileState> {
  /// Creates a [LedgerWalletFileBloc].
  LedgerWalletFileBloc({
    Future<void> Function(
      String walletId,
      String password, {
      String? walletName,
    })?
    createLedgerWalletFile,
    Future<void> Function(List<int> cipherKey)? initWalletAfterDecryption,
    WalletFile? Function()? getWalletFile,
  }) : _createLedgerWalletFile =
           createLedgerWalletFile ?? WalletUtils.createLedgerWalletFile,
       _initWalletAfterDecryption =
           initWalletAfterDecryption ?? InitUtils.initWalletAfterDecryption,
       _getWalletFile = getWalletFile ?? _defaultGetWalletFile,
       super(const LedgerWalletFileInitial()) {
    on<LedgerWalletFileCreateRequested>(
      _onCreateRequested,
      transformer: droppable(),
    );
  }

  final Future<void> Function(
    String walletId,
    String password, {
    String? walletName,
  })
  _createLedgerWalletFile;
  final Future<void> Function(List<int> cipherKey) _initWalletAfterDecryption;
  final WalletFile? Function() _getWalletFile;

  Future<void> _onCreateRequested(
    LedgerWalletFileCreateRequested event,
    Emitter<LedgerWalletFileState> emit,
  ) async {
    emit(const LedgerWalletFileLoading());
    try {
      await _createLedgerWalletFile(
        event.walletId,
        event.password,
        walletName: event.walletName,
      );
      await _initWalletAfterDecryption(
        Crypto.digest(utf8.encode(event.password)),
      );
      final WalletFile? walletFile = _getWalletFile();
      if (walletFile is! LedgerWalletFile) {
        throw StateError('Created wallet file is not a LedgerWalletFile');
      }
      emit(LedgerWalletFileSuccess(walletFile: walletFile));
    } on Object catch (error, stackTrace) {
      addError(error, stackTrace);
      emit(LedgerWalletFileFailure(error));
    }
  }

  static WalletFile? _defaultGetWalletFile() => kWalletFile;
}
