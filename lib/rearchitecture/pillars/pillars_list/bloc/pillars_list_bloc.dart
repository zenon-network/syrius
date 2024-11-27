import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// A bloc that manages the list of pillars.
class PillarsListBloc extends InfiniteListBloc<PillarInfo> {
  /// Constructs a new instance of the bloc.
  PillarsListBloc({required super.zenon, super.pageSize = kPageSize})
      : super(
          fromJsonT: (Object? map) => PillarInfo.fromJson(
            map! as Map<String, dynamic>,
          ),
          toJsonT: (PillarInfo pillarInfo) => pillarInfo.toJson(),
        );

  @override
  Future<List<PillarInfo>> paginationFetch({
    required int pageIndex,
    required int pageSize,
    Address? address,
  }) async {
    final PillarInfoList pillarInfoList = await zenon.embedded.pillar.getAll(
      pageIndex: pageIndex,
      pageSize: pageSize,
    );

    return pillarInfoList.list;
  }
}
