import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'pillar_deposit_qsr_event.dart';

part 'pillar_deposit_qsr_state.dart';

/// A bloc that helps with depositing the needed QSR for the creation of a
/// pillar
class PillarDepositQsrBloc extends Bloc<PillarDepositQsrEvent, PillarDepositQsrState> {
  /// Creates a new [PillarDepositQsrBloc].
  ///
  /// The optional [_postTransactionDelay] is used to wait for chain sync after
  /// account block creation.
  PillarDepositQsrBloc({
    required this._accountBlockUtils,
    required this._zenon,
    required this._zenonAddressUtils,
    this._postTransactionDelay = kDelayAfterAccountBlockCreationCall,
  }) : super(const PillarDepositQsrInitial()) {
    on<PillarDepositQsrRequested>(_onDepositQsrRequested);
  }

  final Zenon _zenon;
  final AccountBlockUtils _accountBlockUtils;
  final ZenonAddressUtils _zenonAddressUtils;
  final Duration _postTransactionDelay;

  FutureOr<void> _onDepositQsrRequested(
    PillarDepositQsrRequested event,
    Emitter<PillarDepositQsrState> emit,
  ) async {
    try {
      emit(const PillarDepositQsrLoading());
      final AccountBlockTemplate transactionParams = _zenon.embedded.pillar
          .depositQsr(event.amount);

      await _accountBlockUtils
          .createAccountBlock(
            transactionParams,
            'deposit ${kQsrCoin.symbol} from Pillar Slot',
            address: event.address,
            waitForRequiredPlasma: true,
          );

      // Needed delay to make sure that the blockchain synced
      await Future<void>.delayed(_postTransactionDelay);

      _zenonAddressUtils.refreshBalance();

      emit(const PillarDepositQsrDone());
    } on SyriusException catch (e, stackTrace) {
      addError(e, stackTrace);
      emit(PillarDepositQsrFailure(exception: e));
    } on Exception catch (e, stackTrace) {
      addError(e, stackTrace);
      emit(PillarDepositQsrFailure(exception: FailureException()));
    }
  }
}
