import 'package:equatable/equatable.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/dependency_injection_helpers/account_block_utils_helper.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'undelegate_button_cubit.g.dart';

part 'undelegate_button_state.dart';

/// A cubit responsible for handling the undelegation from a Pillar.
class UndelegateButtonCubit extends HydratedCubit<UndelegateButtonState> {
  /// Creates a new instance of [UndelegateButtonCubit].
  UndelegateButtonCubit({
    required this.zenon,
    this.duration = kDelayAfterAccountBlockCreationCall,
    AccountBlockUtilsHelper? accountBlockUtilsHelper,
  })  : accountBlockUtilsHelper =
            accountBlockUtilsHelper ?? AccountBlockUtilsHelper(),
        super(const UndelegateButtonState());

  /// The Zenon SDK instance used for network interactions.
  final Zenon zenon;

  /// The delay duration after account block creation.
  final Duration duration;

  /// Helper class with the purpose of facilitating dependency injections.
  final AccountBlockUtilsHelper accountBlockUtilsHelper;

  /// Initiates the undelegation process.
  Future<void> cancelPillarVoting() async {
    try {
      emit(state.copyWith(status: UndelegateButtonStatus.loading));

      final AccountBlockTemplate transactionParams =
          zenon.embedded.pillar.undelegate();

      final AccountBlockTemplate response =
          await accountBlockUtilsHelper.createAccountBlock(
        transactionParams,
        'undelegate',
        waitForRequiredPlasma: true,
      );

      await Future.delayed(duration);

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
