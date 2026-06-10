import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// A bloc that fetches staking entries for a wallet address.
class StakingsBloc extends InfiniteListBloc<StakeEntry> {
  /// Creates a new [StakingsBloc].
  StakingsBloc({required super.zenon, super.pageSize = kPageSize})
    : super(
        fromJsonT: (Object? map) => StakeEntry.fromJson(
          map! as Map<String, dynamic>,
        ),
        toJsonT: (StakeEntry stakeEntry) => stakeEntry.toJson(),
      );

  @override
  Future<List<StakeEntry>> paginationFetch({
    required Address? address,
    required int pageIndex,
    required int pageSize,
  }) async {
    final StakeList stakeList = await zenon.embedded.stake.getEntriesByAddress(
      address!,
      pageIndex: pageIndex,
      pageSize: pageSize,
    );

    return stakeList.list;
  }
}
