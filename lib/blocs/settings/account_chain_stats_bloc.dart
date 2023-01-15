import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class AccountChainStatsBloc
    extends BaseBlocForReloadingIndicator<AccountChainStats> {
  @override
  Future<AccountChainStats> getDataAsync() async {
    AccountInfo accountInfo = await zenon!.ledger.getAccountInfoByAddress(
      Address.parse(
        kSelectedAddress!,
      ),
    );
    List<AccountBlock> blocks = (await zenon!.ledger.getAccountBlocksByHeight(
          Address.parse(
            kSelectedAddress!,
          ),
          1,
          accountInfo.blockCount! + 1,
        ))
            .list ??
        [];
    if (accountInfo.blockCount! > 0) {
      return AccountChainStats(
        firstHash: blocks.isNotEmpty ? blocks.first.hash : '' as Hash,
        blockCount: accountInfo.blockCount!,
        blockTypeNumOfBlocksMap: _getNumOfBlocksForEachBlockType(blocks),
      );
    } else {
      throw 'Empty account-chain';
    }
  }

  Map<BlockTypeEnum, int> _getNumOfBlocksForEachBlockType(
          List<AccountBlock> blocks) =>
      BlockTypeEnum.values.fold<Map<BlockTypeEnum, int>>(
        {},
        (previousValue, blockType) {
          previousValue[blockType] =
              _getNumOfBlockForBlockType(blocks, blockType);
          return previousValue;
        },
      );

  int _getNumOfBlockForBlockType(
          List<AccountBlock> blocks, BlockTypeEnum blockType) =>
      blocks.fold<int>(
        0,
        (dynamic previousValue, element) {
          if (element.blockType == blockType.index) {
            return previousValue + 1;
          }
          return previousValue;
        },
      );
}
