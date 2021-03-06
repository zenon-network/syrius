import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class AccountChainStats {
  final Hash firstHash;
  final int blockCount;
  final Map<BlockTypeEnum, int> blockTypeNumOfBlocksMap;

  AccountChainStats({
    required this.firstHash,
    required this.blockCount,
    required this.blockTypeNumOfBlocksMap,
  });
}
