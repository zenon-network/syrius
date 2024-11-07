import 'package:equatable/equatable.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/modular_widgets/pillar_widgets/pillar_stepper_container.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'pillars_qsr_info_cubit.g.dart';
part 'pillars_qsr_info_state.dart';

/// A cubit responsible for fetching QSR deposit and cost
/// information for a Pillar.
class PillarsQsrInfoCubit extends HydratedCubit<PillarsQsrInfoState> {
  /// Creates a new instance of [PillarsQsrInfoCubit].
  PillarsQsrInfoCubit(this.zenon) : super(const PillarsQsrInfoState());

  /// The Zenon SDK instance used for network interactions.
  final Zenon zenon;

  /// Fetches the QSR management information for a Pillar slot.
  Future<void> getQsrManagementInfo(
      PillarType? pillarType,
      String address,
      ) async {
    try {
      emit(state.copyWith(status: PillarsQsrInfoStatus.loading));

      final BigInt deposit = await zenon.embedded.pillar.getDepositedQsr(
        Address.parse(address),
      );
      final BigInt cost = await zenon.embedded.pillar.getQsrRegistrationCost();

      emit(state.copyWith(
        status: PillarsQsrInfoStatus.success,
        data: PillarsQsrInfo(deposit: deposit, cost: cost),
      ),);
    } catch (e) {
      emit(state.copyWith(
        status: PillarsQsrInfoStatus.failure,
        error: e,
      ),);
    }
  }

  /// Deserializes the [PillarsQsrInfoState] from the provided JSON [Map].
  @override
  PillarsQsrInfoState? fromJson(Map<String, dynamic> json) =>
      PillarsQsrInfoState.fromJson(json);

  /// Serializes the current [PillarsQsrInfoState] into a JSON [Map].
  @override
  Map<String, dynamic>? toJson(PillarsQsrInfoState state) => state.toJson();
}
