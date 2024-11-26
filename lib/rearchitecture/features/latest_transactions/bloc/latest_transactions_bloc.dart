import 'dart:async';

import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// A bloc that manages the state of the latest transactions for a specific
/// address.
class LatestTransactionsBloc extends InfiniteListBloc<AccountBlock> {
  /// Creates an instance of [LatestTransactionsBloc].
  ///
  /// The constructor requires a [Zenon] SDK instance.
  LatestTransactionsBloc({required super.zenon, super.pageSize = kPageSize})
      : super(
          fromJsonT: (Object? map) => AccountBlock.fromJson(
            map! as Map<String, dynamic>,
          ),
          toJsonT: (AccountBlock block) => block.toJson(),
        );

  @override
  Future<List<AccountBlock>> paginationFetch({
    required Address address,
    required int pageIndex,
    required int pageSize,
  }) async {
    final AccountBlockList accountBlock =
        await zenon.ledger.getAccountBlocksByPage(
      address,
      pageIndex: pageIndex,
      pageSize: kPageSize,
    );

    return accountBlock.list!;
  }
}
