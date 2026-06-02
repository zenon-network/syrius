import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'revoke_pillar_event.dart';

part 'revoke_pillar_state.dart';

/// A bloc that helps with revoking a pillar
///
/// To be remembered that this operation can be done only in a certain window
/// of time
class RevokePillarBloc extends Bloc<RevokePillarEvent, RevokePillarState> {
  /// Creates a new [RevokePillarBloc].
  RevokePillarBloc({
    required this._accountBlockUtils,
    required this._zenon,
    required this._zenonAddressUtils,
  }) : super(const RevokePillarInitial()) {
    on<RevokePillarRequested>(_onRevokePillarRequested);
  }

  final Zenon _zenon;
  final AccountBlockUtils _accountBlockUtils;
  final ZenonAddressUtils _zenonAddressUtils;

  FutureOr<void> _onRevokePillarRequested(
    RevokePillarRequested event,
    Emitter<RevokePillarState> emit,
  ) async {
    try {
      emit(const RevokePillarLoading());
      final AccountBlockTemplate transactionParams = _zenon.embedded.pillar
          .revoke(
            event.pillarName,
          );
      await _accountBlockUtils
          .createAccountBlock(
            transactionParams,
            'disassemble Pillar',
            waitForRequiredPlasma: true,
          )
          .then(
            (AccountBlockTemplate response) {},
          );

      _zenonAddressUtils.refreshBalance();

      emit(const RevokePillarDone());
    } on SyriusException catch (e, stackTrace) {
      addError(e, stackTrace);
      emit(RevokePillarFailure(exception: e));
    } on Exception catch (e, stackTrace) {
      addError(e, stackTrace);
      emit(RevokePillarFailure(exception: FailureException()));
    }
  }
}
