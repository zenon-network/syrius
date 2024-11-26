import 'dart:async';

import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';


/// A cubit responsible for fetching and managing the list of pending
/// transactions for an address.
class PendingTransactionsBloc extends InfiniteListBloc<AccountBlock> {
  /// Creates a new [PendingTransactionsBloc] instance.
  ///
  /// Requires a [Zenon] instance to interact with the ledger
  PendingTransactionsBloc({
    required super.zenon,
  }) : super(
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
        await zenon.ledger.getUnreceivedBlocksByAddress(
      address,
      pageIndex: pageIndex,
      pageSize: kPageSize,
    );

    return accountBlock.list!;
  }
}
