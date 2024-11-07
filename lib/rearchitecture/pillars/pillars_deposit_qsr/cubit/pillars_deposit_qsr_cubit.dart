import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:zenon_syrius_wallet_flutter/utils/account_block_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/address_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/utils/zts_utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'pillars_deposit_qsr_cubit.g.dart';

part 'pillars_deposit_qsr_state.dart';

/// A cubit responsible for handling the QSR deposit for Pillar slots.
class PillarsDepositQsrCubit extends HydratedCubit<PillarsDepositQsrState> {
  /// Creates a new instance of [PillarsDepositQsrCubit].
  PillarsDepositQsrCubit(this.zenon) : super(const PillarsDepositQsrState());

  /// The Zenon SDK instance used for network interactions.
  final Zenon zenon;

  /// Initiates the QSR deposit for a Pillar slot with the specified [amount].
  Future<void> depositQsr(
    BigInt amount, {
    bool justMarkStepCompleted = false,
  }) async {
    try {
      emit(state.copyWith(status: PillarsDepositQsrStatus.loading));

      if (!justMarkStepCompleted) {
        final AccountBlockTemplate transactionParams =
            zenon.embedded.pillar.depositQsr(amount);

        final AccountBlockTemplate response =
            await AccountBlockUtils.createAccountBlock(
          transactionParams,
          'deposit ${kQsrCoin.symbol} for Pillar Slot',
          waitForRequiredPlasma: true,
        );

        await Future.delayed(kDelayAfterAccountBlockCreationCall);

        ZenonAddressUtils.refreshBalance();

        emit(
          state.copyWith(
            status: PillarsDepositQsrStatus.success,
            data: response,
          ),
        );
      } else {
        emit(state.copyWith(status: PillarsDepositQsrStatus.success));
      }
    } catch (e) {
      emit(
        state.copyWith(
          status: PillarsDepositQsrStatus.failure,
          error: e.toString(),
        ),
      );
    }
  }

  /// Deserializes the [PillarsDepositQsrState] from the provided JSON [Map].
  @override
  PillarsDepositQsrState? fromJson(Map<String, dynamic> json) =>
      PillarsDepositQsrState.fromJson(json);

  /// Serializes the current [PillarsDepositQsrState] into a JSON [Map].
  @override
  Map<String, dynamic>? toJson(PillarsDepositQsrState state) => state.toJson();
}
