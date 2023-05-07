import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class PillarsQsrInfoBloc extends BaseBloc<PillarsQsrInfo?> {
  Future<void> getQsrManagementInfo(
    PillarType? pillarType,
    String address,
  ) async {
    try {
      addEvent(null);
      BigInt deposit = (await zenon!.embedded.pillar.getDepositedQsr(
        Address.parse(address),
      ));
      BigInt cost = (await zenon!.embedded.pillar.getQsrRegistrationCost());
      addEvent(
        PillarsQsrInfo(
          deposit: deposit,
          cost: cost,
        ),
      );
    } catch (e, stackTrace) {
      addError(e, stackTrace);
    }
  }
}
