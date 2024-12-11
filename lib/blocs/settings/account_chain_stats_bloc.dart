import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class AccountChainStatsBloc
    extends BaseBlocForReloadingIndicator<AccountChainStats> {
  @override
  Future<AccountChainStats> getDataAsync() async {
    final AccountInfo accountInfo = await zenon!.ledger.getAccountInfoByAddress(
      Address.parse(
        kSelectedAddress!,
      ),
    );

    final int pageSize = accountInfo.blockCount!;
    final int pageCount = ((pageSize + 1) / rpcMaxPageSize).ceil();

    if (pageSize > 0) {
      final List<AccountBlock> allBlocks = <AccountBlock>[];

      for (int i = 0; i < pageCount; i++) {
        allBlocks.addAll((await zenon!.ledger.getAccountBlocksByHeight(
              Address.parse(
                kSelectedAddress!,
              ),
              (rpcMaxPageSize * i) + 1,
            ))
                .list ??
            <AccountBlock>[],);
      }

      return AccountChainStats(
        firstHash: allBlocks.isNotEmpty ? allBlocks.first.hash : emptyHash,
        blockCount: pageSize,
        blockTypeNumOfBlocksMap: _getNumOfBlocksForEachBlockType(allBlocks),
      );
    } else {
      throw 'Empty account-chain';
    }
  }

  Map<BlockTypeEnum, int> _getNumOfBlocksForEachBlockType(
          List<AccountBlock> blocks,) =>
      BlockTypeEnum.values.fold<Map<BlockTypeEnum, int>>(
        <BlockTypeEnum, int>{},
        (Map<BlockTypeEnum, int> previousValue, BlockTypeEnum blockType) {
          previousValue[blockType] =
              _getNumOfBlockForBlockType(blocks, blockType);
          return previousValue;
        },
      );

  int _getNumOfBlockForBlockType(
          List<AccountBlock> blocks, BlockTypeEnum blockType,) =>
      blocks.fold<int>(
        0,
        (int previousValue, AccountBlock element) {
          if (element.blockType == blockType.index) {
            return previousValue + 1;
          }
          return previousValue;
        },
      );
}
