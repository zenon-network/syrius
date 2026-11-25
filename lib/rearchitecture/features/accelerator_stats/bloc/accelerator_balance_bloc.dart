import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/accelerator_stats/exceptions/accelerator_fund_empty_exception.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/exceptions/exceptions.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'accelerator_balance_event.dart';
part 'accelerator_balance_state.dart';

/// Fetches the current ZNN and QSR balance of the Accelerator contract.
class AcceleratorBalanceBloc
    extends Bloc<AcceleratorBalanceEvent, AcceleratorBalanceState> {
  /// Creates an [AcceleratorBalanceBloc].
  AcceleratorBalanceBloc({required this._zenon})
    : super(const AcceleratorBalanceInitial()) {
    on<AcceleratorBalanceRequested>(_onAcceleratorBalanceRequested);
  }

  final Zenon _zenon;

  Future<void> _onAcceleratorBalanceRequested(
    AcceleratorBalanceRequested event,
    Emitter<AcceleratorBalanceState> emit,
  ) async {
    emit(const AcceleratorBalanceLoading());

    try {
      final AccountInfo accountInfo = await _zenon.ledger
          .getAccountInfoByAddress(acceleratorAddress);
      final BigInt znnBalance = accountInfo.znn() ?? BigInt.zero;
      final BigInt qsrBalance = accountInfo.qsr() ?? BigInt.zero;

      if (qsrBalance > BigInt.zero || znnBalance > BigInt.zero) {
        emit(AcceleratorBalancePopulated(accountInfo: accountInfo));
      } else {
        emit(
          AcceleratorBalanceFailure(exception: AcceleratorFundEmptyException()),
        );
      }
    } on SyriusException catch (e, stackTrace) {
      addError(e, stackTrace);
      emit(AcceleratorBalanceFailure(exception: e));
    } on Object catch (e, stackTrace) {
      addError(e, stackTrace);
      emit(AcceleratorBalanceFailure(exception: FailureException()));
    }
  }
}
