import 'dart:async';

import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// A bloc that manages the state of the latest transactions for a specific
/// address, or merged across all wallet addresses when `address` is `null`.
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

  int _allAddressesNextPage = 0;
  final Set<String> _exhaustedAddresses = <String>{};

  @override
  Future<List<AccountBlock>> paginationFetch({
    required Address? address,
    required int pageIndex,
    required int pageSize,
  }) async {
    if (address != null) {
      final AccountBlockList accountBlock = await zenon.ledger
          .getAccountBlocksByPage(
            address,
            pageIndex: pageIndex,
            pageSize: pageSize,
          );
      return accountBlock.list ?? <AccountBlock>[];
    }

    if (pageIndex == 0) {
      _allAddressesNextPage = 0;
      _exhaustedAddresses.clear();
    }

    final List<String> allAddresses = kDefaultAddressList
        .whereType<String>()
        .where((String a) => a.isNotEmpty)
        .toList();
    final List<String> pendingAddresses = allAddresses
        .where((String a) => !_exhaustedAddresses.contains(a))
        .toList();
    if (pendingAddresses.isEmpty) {
      return <AccountBlock>[];
    }

    final int fetchPage = _allAddressesNextPage;
    final List<List<AccountBlock>> perAddressPages = await Future.wait(
      pendingAddresses.map((String addr) async {
        final AccountBlockList response = await zenon.ledger
            .getAccountBlocksByPage(
              Address.parse(addr),
              pageIndex: fetchPage,
              pageSize: pageSize,
            );
        final List<AccountBlock> items = response.list ?? <AccountBlock>[];
        if (items.length < pageSize) {
          _exhaustedAddresses.add(addr);
        }
        return items;
      }),
    );
    _allAddressesNextPage = fetchPage + 1;

    final Map<String, AccountBlock> deduped = <String, AccountBlock>{};
    for (final List<AccountBlock> page in perAddressPages) {
      for (final AccountBlock block in page) {
        deduped.putIfAbsent(block.hash.toString(), () => block);
      }
    }
    final List<AccountBlock> merged = deduped.values.toList()
      ..sort((AccountBlock a, AccountBlock b) {
        final int tsA = a.confirmationDetail?.momentumTimestamp ?? 0;
        final int tsB = b.confirmationDetail?.momentumTimestamp ?? 0;
        final int byTs = tsB.compareTo(tsA);
        if (byTs != 0) {
          return byTs;
        }
        return b.height.compareTo(a.height);
      });
    return merged;
  }
}
