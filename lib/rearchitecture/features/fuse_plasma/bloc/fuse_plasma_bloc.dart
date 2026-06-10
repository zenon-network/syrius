import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'fuse_plasma_event.dart';

part 'fuse_plasma_state.dart';

/// A bloc that helps with fusing QSR for Plasma.
class FusePlasmaBloc extends Bloc<FusePlasmaEvent, FusePlasmaState> {
  /// Creates a [FusePlasmaBloc].
  FusePlasmaBloc({
    required this._accountBlockUtils,
    required this._zenon,
    required this._zenonAddressUtils,
  }) : super(const FusePlasmaInitial()) {
    on<FusePlasmaRequested>(_onFusePlasmaRequested);
  }

  final AccountBlockUtils _accountBlockUtils;
  final Zenon _zenon;
  final ZenonAddressUtils _zenonAddressUtils;

  FutureOr<void> _onFusePlasmaRequested(
    FusePlasmaRequested event,
    Emitter<FusePlasmaState> emit,
  ) async {
    try {
      emit(const FusePlasmaLoading());
      final AccountBlockTemplate transactionParams = _zenon.embedded.plasma
          .fuse(
            Address.parse(event.beneficiaryAddress),
            event.amount,
          );

      final AccountBlockTemplate accountBlock = await _accountBlockUtils
          .createAccountBlock(
            transactionParams,
            'fuse ${kQsrCoin.symbol} for Plasma',
            waitForRequiredPlasma: true,
          );

      _zenonAddressUtils.refreshBalance();
      emit(FusePlasmaDone(accountBlock: accountBlock));
    } on SyriusException catch (e, stackTrace) {
      addError(e, stackTrace);
      emit(FusePlasmaFailure(exception: e));
    } on Exception catch (e, stackTrace) {
      addError(e, stackTrace);
      emit(FusePlasmaFailure(exception: FailureException()));
    }
  }
}
