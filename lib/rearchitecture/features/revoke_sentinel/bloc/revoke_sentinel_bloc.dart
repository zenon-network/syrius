import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'revoke_sentinel_event.dart';

part 'revoke_sentinel_state.dart';

/// A bloc that helps with revoking a sentinel.
class RevokeSentinelBloc
    extends Bloc<RevokeSentinelEvent, RevokeSentinelState> {
  /// Creates a new [RevokeSentinelBloc].
  RevokeSentinelBloc({
    required this._accountBlockUtils,
    required this._zenon,
    required this._zenonAddressUtils,
  }) : super(const RevokeSentinelInitial()) {
    on<RevokeSentinelRequested>(_onRevokeSentinelRequested);
  }

  final Zenon _zenon;
  final AccountBlockUtils _accountBlockUtils;
  final ZenonAddressUtils _zenonAddressUtils;

  FutureOr<void> _onRevokeSentinelRequested(
    RevokeSentinelRequested event,
    Emitter<RevokeSentinelState> emit,
  ) async {
    try {
      emit(const RevokeSentinelLoading());
      final AccountBlockTemplate transactionParams = _zenon.embedded.sentinel
          .revoke();
      await _accountBlockUtils.createAccountBlock(
        transactionParams,
        'disassemble Sentinel',
        waitForRequiredPlasma: true,
      );

      _zenonAddressUtils.refreshBalance();

      emit(const RevokeSentinelDone());
    } on SyriusException catch (e, stackTrace) {
      addError(e, stackTrace);
      emit(RevokeSentinelFailure(exception: e));
    } on Exception catch (e, stackTrace) {
      addError(e, stackTrace);
      emit(RevokeSentinelFailure(exception: FailureException()));
    }
  }
}
