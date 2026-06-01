import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'update_pillar_event.dart';

part 'update_pillar_state.dart';

/// A bloc that helps update some pillar details
class UpdatePillarBloc extends Bloc<UpdatePillarEvent, UpdatePillarState> {
  /// {@macro default_constructor}
  UpdatePillarBloc({
    required AccountBlockUtils accountBlockUtils,
    required Zenon zenon,
  }) : _accountBlockUtils = accountBlockUtils,
       _zenon = zenon,
       super(const UpdatePillarInitial()) {
    on<UpdatePillarRequested>(_onUpdatePillarRequested);
  }

  final Zenon _zenon;
  final AccountBlockUtils _accountBlockUtils;

  FutureOr<void> _onUpdatePillarRequested(
    UpdatePillarRequested event,
    Emitter<UpdatePillarState> emit,
  ) async {
    try {
      emit(const UpdatePillarLoading());
      final AccountBlockTemplate transactionParams =
      _zenon.embedded.pillar.updatePillar(
        event.pillarName,
        event.blockProducingAddress,
        event.rewardAddress,
        event.giveBlockRewardPercentage,
        event.giveDelegateRewardPercentage,
      );
      await _accountBlockUtils.createAccountBlock(
        transactionParams,
        'update pillar',
      );

      emit(const UpdatePillarDone());
    } on SyriusException catch (e, stackTrace) {
      addError(e, stackTrace);
      emit(UpdatePillarFailure(exception: e));
    } on Exception catch (e, stackTrace) {
      addError(e, stackTrace);
      emit(UpdatePillarFailure(exception: FailureException()));
    }
  }
}
