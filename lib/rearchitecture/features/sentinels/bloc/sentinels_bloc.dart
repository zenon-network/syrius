import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// A bloc that fetches the list of active sentinels.
class SentinelsBloc extends InfiniteListBloc<SentinelInfo> {
  /// {@macro default_constructor}
  SentinelsBloc({required super.zenon, super.pageSize = kPageSize})
    : super(
        fromJsonT: (Object? map) => SentinelInfo.fromJson(
          map! as Map<String, dynamic>,
        ),
        toJsonT: (SentinelInfo sentinelInfo) => sentinelInfo.toJson(),
      );

  @override
  Future<List<SentinelInfo>> paginationFetch({
    required int pageIndex,
    required int pageSize,
    Address? address,
  }) async {
    final SentinelInfoList sentinelInfoList = await zenon.embedded.sentinel
        .getAllActive(
          pageIndex: pageIndex,
          pageSize: pageSize,
        );

    return sentinelInfoList.list;
  }
}
