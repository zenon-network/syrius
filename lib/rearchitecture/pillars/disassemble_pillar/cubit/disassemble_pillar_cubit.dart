import 'package:equatable/equatable.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'disassemble_pillar_cubit.g.dart';

part 'disassemble_pillar_state.dart';

/// A cubit responsible for handling the disassembly of a Pillar.
class DisassemblePillarCubit extends HydratedCubit<DisassemblePillarState> {
  /// Creates a new instance of [DisassemblePillarCubit].
  DisassemblePillarCubit({
    required this.zenon,
    AccountBlockUtils? accountBlockUtilsHelper,
    ZenonAddressUtils? zenonAddressUtilsHelper,
  })  : zenonAddressUtilsHelper =
            zenonAddressUtilsHelper ?? ZenonAddressUtils(),
        accountBlockUtilsHelper =
            accountBlockUtilsHelper ?? AccountBlockUtils(),
        super(const DisassemblePillarState());

  /// The Zenon SDK instance used for network interactions.
  final Zenon zenon;

  /// Helper class with the purpose of facilitating dependency injections.
  final AccountBlockUtils accountBlockUtilsHelper;

  /// Helper class with the purpose of facilitating dependency injections.
  final ZenonAddressUtils zenonAddressUtilsHelper;

  /// Initiates the disassembly of a Pillar with the given [pillarName].
  Future<void> disassemblePillar(String pillarName) async {
    try {
      emit(state.copyWith(status: DisassemblePillarStatus.loading));

      final AccountBlockTemplate transactionParams =
          zenon.embedded.pillar.revoke(
        pillarName,
      );

      final AccountBlockTemplate response =
          await accountBlockUtilsHelper.createAccountBlock(
        transactionParams,
        'disassemble Pillar',
        waitForRequiredPlasma: true,
      );

      zenonAddressUtilsHelper.refreshBalance();

      emit(
        state.copyWith(
          status: DisassemblePillarStatus.success,
          data: response,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          status: DisassemblePillarStatus.failure,
          error: e,
        ),
      );
    }
  }

  /// Deserializes the [DisassemblePillarState] from the provided JSON Map.
  @override
  DisassemblePillarState? fromJson(Map<String, dynamic> json) =>
      DisassemblePillarState.fromJson(json);

  /// Serializes the current [DisassemblePillarState] into a JSON Map.
  @override
  Map<String, dynamic>? toJson(DisassemblePillarState state) => state.toJson();
}
