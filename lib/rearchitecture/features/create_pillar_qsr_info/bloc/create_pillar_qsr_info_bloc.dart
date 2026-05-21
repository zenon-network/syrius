import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class CreatePillarQsrInfoBloc extends FetchBloc<CreatePillarQsrInfoData> {
  CreatePillarQsrInfoBloc({required super.zenon})
    : super(
        fromJsonT: CreatePillarQsrInfoData.fromJson,
        toJsonT: (CreatePillarQsrInfoData data) => data.toJson(),
      );

  @override
  Future<CreatePillarQsrInfoData> getData({required Address address}) async {
    final BigInt deposit = await zenon.embedded.pillar.getDepositedQsr(
      address,
    );
    final BigInt cost = await zenon.embedded.pillar.getQsrRegistrationCost();

    return CreatePillarQsrInfoData(
      deposit: deposit,
      cost: cost,
    );
  }
}
