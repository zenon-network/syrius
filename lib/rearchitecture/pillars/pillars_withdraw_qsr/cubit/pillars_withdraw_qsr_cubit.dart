import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'pillars_withdraw_qsr_cubit.g.dart';

part 'pillars_withdraw_qsr_state.dart';

/// A cubit responsible for handling the QSR withdrawal from Pillar slots.
class PillarsWithdrawQsrCubit extends HydratedCubit<PillarsWithdrawQsrState> {
  /// Creates a new instance of [PillarsWithdrawQsrCubit].
  PillarsWithdrawQsrCubit({
    required this.zenon,
    this.duration = kDelayAfterAccountBlockCreationCall,
    AccountBlockUtils? accountBlockUtilsHelper,
    ZenonAddressUtils? zenonAddressUtilsHelper,
  })  : zenonAddressUtilsHelper =
            zenonAddressUtilsHelper ?? ZenonAddressUtils(),
        accountBlockUtilsHelper =
            accountBlockUtilsHelper ?? AccountBlockUtils(),
        super(const PillarsWithdrawQsrState());

  /// The Zenon SDK instance used for network interactions.
  final Zenon zenon;

  /// The delay duration after account block creation.
  final Duration duration;

  /// Helper class with the purpose of facilitating dependency injections.
  final AccountBlockUtils accountBlockUtilsHelper;

  /// Helper class with the purpose of facilitating dependency injections.
  final ZenonAddressUtils zenonAddressUtilsHelper;

  /// Initiates the QSR withdrawal from a Pillar slot.
  Future<void> withdrawQsr(String address) async {
    try {
      emit(state.copyWith(status: PillarsWithdrawQsrStatus.loading));

      final AccountBlockTemplate transactionParams =
          zenon.embedded.pillar.withdrawQsr();

      final AccountBlockTemplate response =
          await accountBlockUtilsHelper.createAccountBlock(
        transactionParams,
        'withdraw ${kQsrCoin.symbol} from Pillar Slot',
        waitForRequiredPlasma: true,
      );

      await Future.delayed(duration);

      zenonAddressUtilsHelper.refreshBalance();

      emit(
        state.copyWith(
          status: PillarsWithdrawQsrStatus.success,
          data: response,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: PillarsWithdrawQsrStatus.failure,
          error: e,
        ),
      );
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
