import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'mint_token_event.dart';

part 'mint_token_state.dart';

/// A bloc that mints an amount of a ZTS token on-chain.
class MintTokenBloc extends Bloc<MintTokenEvent, MintTokenState> {
  /// Creates a [MintTokenBloc].
  MintTokenBloc({
    required AccountBlockUtils accountBlockUtils,
    required Zenon zenon,
    required ZenonAddressUtils zenonAddressUtils,
  }) : _accountBlockUtils = accountBlockUtils,
       _zenon = zenon,
       _zenonAddressUtils = zenonAddressUtils,
       super(const MintTokenInitial()) {
    on<MintTokenRequested>(_onMintTokenRequested);
  }

  final AccountBlockUtils _accountBlockUtils;
  final Zenon _zenon;
  final ZenonAddressUtils _zenonAddressUtils;

  FutureOr<void> _onMintTokenRequested(
    MintTokenRequested event,
    Emitter<MintTokenState> emit,
  ) async {
    try {
      emit(const MintTokenLoading());

      final AccountBlockTemplate transactionParams = _zenon.embedded.token
          .mintToken(
            event.token.tokenStandard,
            event.amount,
            event.beneficiaryAddress,
          );

      final AccountBlockTemplate response = await _accountBlockUtils
          .createAccountBlock(
            transactionParams,
            'mint token',
            waitForRequiredPlasma: true,
          );

      response.amount = event.amount;
      _zenonAddressUtils.refreshBalance();
      emit(MintTokenDone(accountBlock: response));
    } on SyriusException catch (e, stackTrace) {
      addError(e, stackTrace);
      emit(MintTokenFailure(exception: e));
    } on Exception catch (e, stackTrace) {
      addError(e, stackTrace);
      emit(MintTokenFailure(exception: FailureException()));
    }
  }
}
