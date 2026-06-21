import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'cancel_plasma_event.dart';

part 'cancel_plasma_state.dart';

/// A bloc that helps with cancelling revocable Plasma fusions.
class CancelPlasmaBloc extends Bloc<CancelPlasmaEvent, CancelPlasmaState> {
  /// Creates a new [CancelPlasmaBloc].
  CancelPlasmaBloc({
    required this._accountBlockUtils,
    required this._zenon,
    required this._zenonAddressUtils,
  }) : super(const CancelPlasmaInitial()) {
    on<CancelPlasmaRequested>(_onCancelPlasmaRequested);
  }

  final AccountBlockUtils _accountBlockUtils;
  final Zenon _zenon;
  final ZenonAddressUtils _zenonAddressUtils;

  FutureOr<void> _onCancelPlasmaRequested(
    CancelPlasmaRequested event,
    Emitter<CancelPlasmaState> emit,
  ) async {
    try {
      emit(const CancelPlasmaLoading());
      final AccountBlockTemplate transactionParams = _zenon.embedded.plasma
          .cancel(
            event.plasmaHash,
          );

      await _accountBlockUtils.createAccountBlock(
        transactionParams,
        'cancel Plasma',
        waitForRequiredPlasma: true,
      );

      _zenonAddressUtils.refreshBalance();

      emit(const CancelPlasmaDone());
    } on SyriusException catch (e, stackTrace) {
      addError(e, stackTrace);
      emit(CancelPlasmaFailure(exception: e));
    } on Exception catch (e, stackTrace) {
      addError(e, stackTrace);
      emit(CancelPlasmaFailure(exception: FailureException()));
    }
  }
}
