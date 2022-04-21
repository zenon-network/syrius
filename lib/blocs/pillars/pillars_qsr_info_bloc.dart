import 'package:zenon_syrius_wallet_flutter/blocs/base_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/model/pillars_qsr_info.dart';
import 'package:zenon_syrius_wallet_flutter/utils/extensions.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/modular_widgets/pillars_widgets/pillars_stepper_container.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class PillarsQsrInfoBloc extends BaseBloc<PillarsQsrInfo?> {
  Future<void> getQsrManagementInfo(
    PillarType? pillarType,
    String address,
  ) async {
    try {
      addEvent(null);
      num deposit = (await zenon!.embedded.pillar.getDepositedQsr(
        Address.parse(address),
      ))
          .addDecimals(
        qsrDecimals,
      );
      num cost = (pillarType == PillarType.legacyPillar
              ? pillarRegisterQsrAmount
              : await zenon!.embedded.pillar.getQsrRegistrationCost())
          .addDecimals(qsrDecimals);
      addEvent(
        PillarsQsrInfo(
          deposit: deposit,
          cost: cost,
        ),
      );
    } catch (e) {
      addError(e);
    }
  }
}
