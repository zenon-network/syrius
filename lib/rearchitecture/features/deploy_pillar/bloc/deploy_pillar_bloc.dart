import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'deploy_pillar_event.dart';

part 'deploy_pillar_state.dart';

/// A bloc that registers a new pillar on-chain.
class DeployPillarBloc extends Bloc<DeployPillarEvent, DeployPillarState> {
  /// Creates a new [DeployPillarBloc].
  DeployPillarBloc({
    required this._accountBlockUtils,
    required this._zenon,
    required this._zenonAddressUtils,
  }) : super(const DeployPillarInitial()) {
    on<DeployPillarRequested>(_onDeployPillarRequested);
  }

  final Zenon _zenon;
  final AccountBlockUtils _accountBlockUtils;
  final ZenonAddressUtils _zenonAddressUtils;

  FutureOr<void> _onDeployPillarRequested(
    DeployPillarRequested event,
    Emitter<DeployPillarState> emit,
  ) async {
    try {
      emit(const DeployPillarLoading());
      if (await _pillarNameAlreadyExists(event.pillarName)) {
        throw PillarNameAlreadyExistsException();
      }
      final AccountBlockTemplate transactionParams = _zenon.embedded.pillar
          .register(
            event.pillarName,
            event.blockProducingAddress,
            event.rewardAddress,
            event.giveBlockRewardPercentage,
            event.giveDelegateRewardPercentage,
          );
      final AccountBlockTemplate response = await _accountBlockUtils
          .createAccountBlock(
            transactionParams,
            'register Pillar',
            waitForRequiredPlasma: true,
          );

      _zenonAddressUtils.refreshBalance();

      emit(DeployPillarDone(accountBlock: response));
    } on SyriusException catch (e, stackTrace) {
      addError(e, stackTrace);
      emit(DeployPillarFailure(exception: e));
    } on Exception catch (e, stackTrace) {
      addError(e, stackTrace);
      emit(DeployPillarFailure(exception: FailureException()));
    }
  }

  Future<bool> _pillarNameAlreadyExists(String pillarName) async =>
      !(await _zenon.embedded.pillar.checkNameAvailability(
        pillarName,
      ));
}
