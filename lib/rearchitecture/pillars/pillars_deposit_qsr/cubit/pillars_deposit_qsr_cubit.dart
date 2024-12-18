import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'pillars_deposit_qsr_cubit.g.dart';

part 'pillars_deposit_qsr_state.dart';

/// A cubit responsible for handling the QSR deposit for Pillar slots.
class PillarsDepositQsrCubit extends HydratedCubit<PillarsDepositQsrState> {
  /// Creates a new instance of [PillarsDepositQsrCubit].
  PillarsDepositQsrCubit({
    required this.zenon,
    this.duration = kDelayAfterAccountBlockCreationCall,
    AccountBlockUtils? accountBlockUtilsHelper,
    ZenonAddressUtils? zenonAddressUtilsHelper,
  })  : zenonAddressUtilsHelper =
            zenonAddressUtilsHelper ?? ZenonAddressUtils(),
        accountBlockUtilsHelper =
            accountBlockUtilsHelper ?? AccountBlockUtils(),
        super(const PillarsDepositQsrState());

  /// The Zenon SDK instance used for network interactions.
  final Zenon zenon;

  /// The delay duration after account block creation.
  final Duration duration;

  /// Helper class with the purpose of facilitating dependency injections.
  final AccountBlockUtils accountBlockUtilsHelper;

  /// Helper class with the purpose of facilitating dependency injections.
  final ZenonAddressUtils zenonAddressUtilsHelper;

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
            await accountBlockUtilsHelper.createAccountBlock(
          transactionParams,
          'deposit ${kQsrCoin.symbol} for Pillar Slot',
          waitForRequiredPlasma: true,
        );

        await Future<void>.delayed(duration);

        zenonAddressUtilsHelper.refreshBalance();

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
          error: e,
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
