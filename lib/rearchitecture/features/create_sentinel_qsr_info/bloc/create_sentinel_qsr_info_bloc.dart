import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/create_sentinel_qsr_info/model/create_sentinel_qsr_info_data.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// Fetches QSR deposit and registration cost for sentinel creation.
class CreateSentinelQsrInfoBloc extends FetchBloc<CreateSentinelQsrInfoData> {
  /// Creates a new [CreateSentinelQsrInfoBloc].
  CreateSentinelQsrInfoBloc({required super.zenon})
    : super(
        fromJsonT: CreateSentinelQsrInfoData.fromJson,
        toJsonT: (CreateSentinelQsrInfoData data) => data.toJson(),
      );

  @override
  Future<CreateSentinelQsrInfoData> getData({required Address address}) async {
    final BigInt deposit = await zenon.embedded.sentinel.getDepositedQsr(
      address,
    );

    return CreateSentinelQsrInfoData(
      deposit: deposit,
      cost: sentinelRegisterQsrAmount,
    );
  }
}
