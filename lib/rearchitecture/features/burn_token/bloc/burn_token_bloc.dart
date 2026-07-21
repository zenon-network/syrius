import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'burn_token_event.dart';

part 'burn_token_state.dart';

/// A bloc that burns an amount of a ZTS token on-chain.
class BurnTokenBloc extends Bloc<BurnTokenEvent, BurnTokenState> {
  /// Creates a [BurnTokenBloc].
  BurnTokenBloc({
    required AccountBlockUtils accountBlockUtils,
    required Zenon zenon,
    required ZenonAddressUtils zenonAddressUtils,
  }) : _accountBlockUtils = accountBlockUtils,
       _zenon = zenon,
       _zenonAddressUtils = zenonAddressUtils,
       super(const BurnTokenInitial()) {
    on<BurnTokenRequested>(_onBurnTokenRequested);
  }

  final AccountBlockUtils _accountBlockUtils;
  final Zenon _zenon;
  final ZenonAddressUtils _zenonAddressUtils;

  FutureOr<void> _onBurnTokenRequested(
    BurnTokenRequested event,
    Emitter<BurnTokenState> emit,
  ) async {
    try {
      emit(const BurnTokenLoading());

      final AccountBlockTemplate transactionParams = _zenon.embedded.token
          .burnToken(
            event.token.tokenStandard,
            event.amount,
          );

      final AccountBlockTemplate response = await _accountBlockUtils
          .createAccountBlock(
            transactionParams,
            'burn token',
            waitForRequiredPlasma: true,
          );

      _zenonAddressUtils.refreshBalance();
      emit(BurnTokenDone(accountBlock: response));
    } on SyriusException catch (e, stackTrace) {
      addError(e, stackTrace);
      emit(BurnTokenFailure(exception: e));
    } on Exception catch (e, stackTrace) {
      addError(e, stackTrace);
      emit(BurnTokenFailure(exception: FailureException()));
    }
  }
}
