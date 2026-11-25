import 'dart:async';

import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/account_chain_stats/exceptions/empty_account_chain_exception.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/account_chain_stats/model/account_chain_stats.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// Fetches account-chain block statistics for a given wallet address.
class AccountChainStatsBloc extends FetchBloc<AccountChainStats> {
  /// Creates an [AccountChainStatsBloc].
  AccountChainStatsBloc({required super.zenon, Stream<bool>? wsRestartedStream})
    : super(
        fromJsonT: AccountChainStats.fromJson,
        toJsonT: (AccountChainStats data) => data.toJson(),
      ) {
    _wsRestartSubscription = wsRestartedStream?.listen((bool restarted) {
      final Address? address = _lastRequestedAddress;
      if (restarted && address != null && !isClosed) {
        add(FetchRequestData(address: address));
      }
    });
  }

  StreamSubscription<bool>? _wsRestartSubscription;
  Address? _lastRequestedAddress;

  @override
  Future<AccountChainStats> getData({required Address address}) async {
    _lastRequestedAddress = address;
    final AccountInfo accountInfo = await zenon.ledger.getAccountInfoByAddress(
      address,
    );

    final int blockCount = accountInfo.blockCount ?? 0;

    if (blockCount <= 0) {
      throw EmptyAccountChainException();
    }

    final int pageCount = (blockCount / rpcMaxPageSize).ceil();
    final List<AccountBlock> allBlocks = <AccountBlock>[];

    for (int i = 0; i < pageCount; i++) {
      final AccountBlockList response = await zenon.ledger
          .getAccountBlocksByHeight(address, (rpcMaxPageSize * i) + 1);
      allBlocks.addAll(response.list ?? <AccountBlock>[]);
    }

    return AccountChainStats(
      firstHash: allBlocks.isNotEmpty ? allBlocks.first.hash : emptyHash,
      blockCount: blockCount,
      blockTypeNumOfBlocksMap: _countBlocksByType(allBlocks),
    );
  }

  Map<BlockTypeEnum, int> _countBlocksByType(List<AccountBlock> blocks) {
    final Map<BlockTypeEnum, int> counts = <BlockTypeEnum, int>{
      for (final BlockTypeEnum blockType in BlockTypeEnum.values) blockType: 0,
    };
    for (final AccountBlock block in blocks) {
      final int typeIndex = block.blockType;
      if (typeIndex >= 0 && typeIndex < BlockTypeEnum.values.length) {
        final BlockTypeEnum blockType = BlockTypeEnum.values[typeIndex];
        counts[blockType] = (counts[blockType] ?? 0) + 1;
      }
    }
    return counts;
  }

  @override
  Future<void> close() async {
    await _wsRestartSubscription?.cancel();
    await super.close();
  }
}
