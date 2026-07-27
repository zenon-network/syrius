import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'deploy_sentinel_event.dart';

part 'deploy_sentinel_state.dart';

/// A bloc that registers a new sentinel on-chain.
class DeploySentinelBloc
    extends Bloc<DeploySentinelEvent, DeploySentinelState> {
  /// Creates a new [DeploySentinelBloc].
  DeploySentinelBloc({
    required this._accountBlockUtils,
    required this._zenon,
    required this._zenonAddressUtils,
  }) : super(const DeploySentinelInitial()) {
    on<DeploySentinelRequested>(_onDeploySentinelRequested);
  }

  final Zenon _zenon;
  final AccountBlockUtils _accountBlockUtils;
  final ZenonAddressUtils _zenonAddressUtils;

  FutureOr<void> _onDeploySentinelRequested(
    DeploySentinelRequested event,
    Emitter<DeploySentinelState> emit,
  ) async {
    try {
      emit(const DeploySentinelLoading());
      final AccountBlockTemplate transactionParams = _zenon.embedded.sentinel
          .register();

      await _accountBlockUtils.createAccountBlock(
        transactionParams,
        'register Sentinel',
        waitForRequiredPlasma: true,
      );

      _zenonAddressUtils.refreshBalance();

      emit(const DeploySentinelDone());
    } on SyriusException catch (e, stackTrace) {
      addError(e, stackTrace);
      emit(DeploySentinelFailure(exception: e));
    } on Exception catch (e, stackTrace) {
      addError(e, stackTrace);
      emit(DeploySentinelFailure(exception: FailureException()));
    }
  }
}
