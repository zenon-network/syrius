import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'transfer_token_event.dart';

part 'transfer_token_state.dart';

/// A bloc that transfers ownership of a ZTS token on-chain.
class TransferTokenBloc extends Bloc<TransferTokenEvent, TransferTokenState> {
  /// Creates a [TransferTokenBloc].
  TransferTokenBloc({
    required this._accountBlockUtils,
    required this._zenon,
  }) : super(const TransferTokenInitial()) {
    on<TransferTokenRequested>(_onTransferTokenRequested);
  }

  final AccountBlockUtils _accountBlockUtils;
  final Zenon _zenon;

  FutureOr<void> _onTransferTokenRequested(
    TransferTokenRequested event,
    Emitter<TransferTokenState> emit,
  ) async {
    try {
      emit(const TransferTokenLoading());

      final AccountBlockTemplate transactionParams = _zenon.embedded.token
          .updateToken(
            event.token.tokenStandard,
            event.newOwnerAddress,
            event.token.isMintable,
            event.token.isBurnable,
          );

      final AccountBlockTemplate response = await _accountBlockUtils
          .createAccountBlock(
            transactionParams,
            'transfer token',
            waitForRequiredPlasma: true,
          );

      emit(TransferTokenDone(accountBlock: response));
    } on SyriusException catch (e, stackTrace) {
      addError(e, stackTrace);
      emit(TransferTokenFailure(exception: e));
    } on Exception catch (e, stackTrace) {
      addError(e, stackTrace);
      emit(TransferTokenFailure(exception: FailureException()));
    }
  }
}
