import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:zenon_syrius_wallet_flutter/utils/account_block_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/address_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/utils/zts_utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'pillars_withdraw_qsr_cubit.g.dart';
part 'pillars_withdraw_qsr_state.dart';

/// A cubit responsible for handling the QSR withdrawal from Pillar slots.
class PillarsWithdrawQsrCubit extends HydratedCubit<PillarsWithdrawQsrState> {
  /// Creates a new instance of [PillarsWithdrawQsrCubit].
  PillarsWithdrawQsrCubit(this.zenon) : super(const PillarsWithdrawQsrState());

  /// The Zenon SDK instance used for network interactions.
  final Zenon zenon;

  /// Initiates the QSR withdrawal from a Pillar slot.
  Future<void> withdrawQsr(String address) async {
    try {
      emit(state.copyWith(status: PillarsWithdrawQsrStatus.loading));

      final AccountBlockTemplate transactionParams =
      zenon.embedded.pillar.withdrawQsr();

      final AccountBlockTemplate response = await AccountBlockUtils.createAccountBlock(
        transactionParams,
        'withdraw ${kQsrCoin.symbol} from Pillar Slot',
        waitForRequiredPlasma: true,
      );

      await Future.delayed(kDelayAfterAccountBlockCreationCall);

      ZenonAddressUtils.refreshBalance();

      emit(state.copyWith(
        status: PillarsWithdrawQsrStatus.success,
        data: response,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: PillarsWithdrawQsrStatus.failure,
        error: e,
      ));
    }
  }

  /// Deserializes the [PillarsWithdrawQsrState] from the provided JSON [Map].
  @override
  PillarsWithdrawQsrState? fromJson(Map<String, dynamic> json) =>
      PillarsWithdrawQsrState.fromJson(json);

  /// Serializes the current [PillarsWithdrawQsrState] into a JSON [Map].
  @override
  Map<String, dynamic>? toJson(PillarsWithdrawQsrState state) => state.toJson();
}
