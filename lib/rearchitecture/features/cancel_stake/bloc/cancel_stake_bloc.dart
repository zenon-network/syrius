import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'cancel_stake_event.dart';

part 'cancel_stake_state.dart';

/// A bloc that helps with cancelling expired stakes.
class CancelStakeBloc extends Bloc<CancelStakeEvent, CancelStakeState> {
  /// Creates a new [CancelStakeBloc].
  CancelStakeBloc({
    required this._accountBlockUtils,
    required this._zenon,
    required this._zenonAddressUtils,
  }) : super(const CancelStakeInitial()) {
    on<CancelStakeRequested>(_onCancelStakeRequested);
  }

  final AccountBlockUtils _accountBlockUtils;
  final Zenon _zenon;
  final ZenonAddressUtils _zenonAddressUtils;

  FutureOr<void> _onCancelStakeRequested(
    CancelStakeRequested event,
    Emitter<CancelStakeState> emit,
  ) async {
    try {
      emit(const CancelStakeLoading());
      final AccountBlockTemplate transactionParams = _zenon.embedded.stake
          .cancel(event.stakeHash);

      await _accountBlockUtils.createAccountBlock(
        transactionParams,
        'cancel stake',
        waitForRequiredPlasma: true,
      );

      _zenonAddressUtils.refreshBalance();

      emit(const CancelStakeDone());
    } on SyriusException catch (e, stackTrace) {
      addError(e, stackTrace);
      emit(CancelStakeFailure(exception: e));
    } on Exception catch (e, stackTrace) {
      addError(e, stackTrace);
      emit(CancelStakeFailure(exception: FailureException()));
    }
  }
}
