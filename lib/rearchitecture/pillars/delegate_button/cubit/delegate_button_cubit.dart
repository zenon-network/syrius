import 'package:equatable/equatable.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:zenon_syrius_wallet_flutter/utils/account_block_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'delegate_button_cubit.g.dart';
part 'delegate_button_state.dart';

/// A cubit responsible for handling delegation to a Pillar.
class DelegateButtonCubit extends HydratedCubit<DelegateButtonState> {
  /// Creates a new instance of [DelegateButtonCubit].
  DelegateButtonCubit(this.zenon) : super(const DelegateButtonState());

  /// The Zenon SDK instance used for network interactions.
  final Zenon zenon;

  /// Initiates delegation to a Pillar with the given [pillarName].
  Future<void> delegateToPillar(String pillarName) async {
    try {
      emit(state.copyWith(status: DelegateButtonStatus.loading));

      final AccountBlockTemplate transactionParams =
          zenon.embedded.pillar.delegate(pillarName);

      final AccountBlockTemplate response =
          await AccountBlockUtils.createAccountBlock(
        transactionParams,
        'delegate to Pillar',
        waitForRequiredPlasma: true,
      );

      // Optionally delay after account block creation
      await Future.delayed(kDelayAfterAccountBlockCreationCall);

      emit(state.copyWith(
        status: DelegateButtonStatus.success,
        data: response,
      ));
    } catch (e) {
      emit(
        state.copyWith(
          status: DelegateButtonStatus.failure,
          error: e,
        ),
      );
    }
  }

  /// Deserializes the JSON map into a [DelegateButtonState].
  @override
  DelegateButtonState? fromJson(Map<String, dynamic> json) =>
      DelegateButtonState.fromJson(json);

  /// Serializes the current state into a JSON map.
  @override
  Map<String, dynamic>? toJson(DelegateButtonState state) => state.toJson();
}
