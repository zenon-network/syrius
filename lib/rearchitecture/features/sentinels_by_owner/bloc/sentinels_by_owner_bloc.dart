import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/blocs/blocs.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// Fetches the sentinel owned by an address.
///
/// The SDK returns a nullable [SentinelInfo]. This bloc normalizes that value
/// into a list so consumers can share the same [FetchBloc] shape used by other
/// address-based features.
class SentinelsByOwnerBloc extends FetchBloc<List<SentinelInfo>> {
  /// {@macro default_constructor}
  SentinelsByOwnerBloc({required super.zenon})
    : super(
        fromJsonT: (Map<String, dynamic> data) =>
            List.castFrom<dynamic, Map<String, dynamic>>(
              data['list'],
            ).map(SentinelInfo.fromJson).toList(),
        toJsonT: (List<SentinelInfo> list) => <String, dynamic>{
          'list': list.map((SentinelInfo entry) => entry.toJson()).toList(),
        },
      );

  @override
  Future<List<SentinelInfo>> getData({required Address address}) async {
    final SentinelInfo? sentinelInfo = await zenon.embedded.sentinel.getByOwner(
      address,
    );

    return sentinelInfo == null
        ? <SentinelInfo>[]
        : <SentinelInfo>[sentinelInfo];
  }
}
