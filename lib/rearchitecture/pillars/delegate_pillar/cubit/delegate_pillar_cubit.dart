import 'package:equatable/equatable.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'delegate_pillar_cubit.g.dart';
part 'delegate_pillar_state.dart';

/// A cubit responsible for handling delegation to a Pillar.
class DelegatePillarCubit extends HydratedCubit<DelegatePillarState> {
  /// Creates a new instance of [DelegatePillarCubit].
  DelegatePillarCubit({
    required this.zenon,
    this.duration = kDelayAfterAccountBlockCreationCall,
    AccountBlockUtilsHelper? accountBlockUtilsHelper,
  })  : accountBlockUtilsHelper =
            accountBlockUtilsHelper ?? AccountBlockUtilsHelper(),
        super(const DelegatePillarState());

  /// The Zenon SDK instance used for network interactions.
  final Zenon zenon;

  /// The delay duration after account block creation.
  final Duration duration;

  /// Helper class with the purpose of facilitating dependency injections.
  final AccountBlockUtilsHelper accountBlockUtilsHelper;

  /// Initiates delegation to a Pillar with the given [pillarName].
  Future<void> delegateToPillar(String pillarName) async {
    try {
      emit(state.copyWith(status: DelegatePillarStatus.loading));

      final AccountBlockTemplate transactionParams =
          zenon.embedded.pillar.delegate(pillarName);

      final AccountBlockTemplate response =
          await accountBlockUtilsHelper.createAccountBlock(
        transactionParams,
        'delegate to Pillar',
        waitForRequiredPlasma: true,
      );

      await Future.delayed(duration);

      emit(
        state.copyWith(
          status: DelegatePillarStatus.success,
          data: response,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: DelegatePillarStatus.failure,
          error: e,
        ),
      );
    }
  }

  /// Deserializes the JSON map into a [DelegatePillarState].
  @override
  DelegatePillarState? fromJson(Map<String, dynamic> json) =>
      DelegatePillarState.fromJson(json);

  /// Serializes the current state into a JSON map.
  @override
  Map<String, dynamic>? toJson(DelegatePillarState state) => state.toJson();
}
