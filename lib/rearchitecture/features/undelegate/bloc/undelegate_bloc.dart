import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'undelegate_event.dart';

part 'undelegate_state.dart';

/// A bloc that removes an address delegation from its current pillar.
class UndelegateBloc extends Bloc<UndelegateEvent, UndelegateState> {
  /// Creates a new [UndelegateBloc].
  ///
  /// The optional [_postTransactionDelay] is used to wait for chain sync after
  /// account block creation.
  UndelegateBloc({
    required this._accountBlockUtils,
    required this._zenon,
    this._postTransactionDelay = kDelayAfterAccountBlockCreationCall,
  }) : super(const UndelegateInitial()) {
    on<UndelegateRequested>(_onUndelegateRequested);
  }

  final Zenon _zenon;
  final AccountBlockUtils _accountBlockUtils;
  final Duration _postTransactionDelay;

  FutureOr<void> _onUndelegateRequested(
    UndelegateRequested event,
    Emitter<UndelegateState> emit,
  ) async {
    try {
      emit(const UndelegateLoading());
      final AccountBlockTemplate transactionParams = _zenon.embedded.pillar
          .undelegate();
      await _accountBlockUtils.createAccountBlock(
        transactionParams,
        'undelegate',
        address: event.address,
        waitForRequiredPlasma: true,
      );

      // Needed delay to make sure that the blockchain synced
      await Future<void>.delayed(_postTransactionDelay);

      emit(const UndelegateDone());
    } on SyriusException catch (e, stackTrace) {
      addError(e, stackTrace);
      emit(UndelegateFailure(exception: e));
    } on Exception catch (e, stackTrace) {
      addError(e, stackTrace);
      emit(UndelegateFailure(exception: FailureException()));
    }
  }
}
