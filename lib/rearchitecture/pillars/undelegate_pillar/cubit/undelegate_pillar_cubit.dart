import 'package:equatable/equatable.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'undelegate_pillar_cubit.g.dart';
part 'undelegate_pillar_state.dart';

/// A cubit responsible for handling the undelegation from a Pillar.
class UndelegatePillarCubit extends HydratedCubit<UndelegatePillarState> {
  /// Creates a new instance of [UndelegatePillarCubit].
  UndelegatePillarCubit({
    required this.zenon,
    this.duration = kDelayAfterAccountBlockCreationCall,
    AccountBlockUtilsHelper? accountBlockUtilsHelper,
  })  : accountBlockUtilsHelper =
            accountBlockUtilsHelper ?? AccountBlockUtilsHelper(),
        super(const UndelegatePillarState());

  /// The Zenon SDK instance used for network interactions.
  final Zenon zenon;

  /// The delay duration after account block creation.
  final Duration duration;

  /// Helper class with the purpose of facilitating dependency injections.
  final AccountBlockUtilsHelper accountBlockUtilsHelper;

  /// Initiates the undelegation process.
  Future<void> cancelPillarVoting() async {
    try {
      emit(state.copyWith(status: UndelegatePillarStatus.loading));

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
          status: UndelegatePillarStatus.success,
          data: response,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: UndelegatePillarStatus.failure,
          error: e,
        ),
      );
    }
  }

  /// Deserializes the [UndelegatePillarState] from the provided JSON [Map].
  @override
  UndelegatePillarState? fromJson(Map<String, dynamic> json) =>
      UndelegatePillarState.fromJson(json);

  /// Serializes the current [UndelegatePillarState] into a JSON [Map].
  @override
  Map<String, dynamic>? toJson(UndelegatePillarState state) => state.toJson();
}
