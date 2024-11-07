import 'package:equatable/equatable.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:zenon_syrius_wallet_flutter/utils/account_block_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'undelegate_button_cubit.g.dart';

part 'undelegate_button_state.dart';

/// A cubit responsible for handling the undelegation from a Pillar.
class UndelegateButtonCubit extends HydratedCubit<UndelegateButtonState> {
  /// Creates a new instance of [UndelegateButtonCubit].
  UndelegateButtonCubit(this.zenon) : super(const UndelegateButtonState());

  /// The Zenon SDK instance used for network interactions.
  final Zenon zenon;

  /// Initiates the undelegation process.
  Future<void> cancelPillarVoting() async {
    try {
      emit(state.copyWith(status: UndelegateButtonStatus.loading));

      final AccountBlockTemplate transactionParams =
          zenon.embedded.pillar.undelegate();

      final AccountBlockTemplate response =
          await AccountBlockUtils.createAccountBlock(
        transactionParams,
        'undelegate',
        waitForRequiredPlasma: true,
      );

      // Optionally delay after account block creation
      await Future.delayed(kDelayAfterAccountBlockCreationCall);

      emit(
        state.copyWith(
          status: UndelegateButtonStatus.success,
          data: response,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: UndelegateButtonStatus.failure,
          error: e,
        ),
      );
    }
  }

  /// Deserializes the [UndelegateButtonState] from the provided JSON [Map].
  @override
  UndelegateButtonState? fromJson(Map<String, dynamic> json) =>
      UndelegateButtonState.fromJson(json);

  /// Serializes the current [UndelegateButtonState] into a JSON [Map].
  @override
  Map<String, dynamic>? toJson(UndelegateButtonState state) => state.toJson();
}
