import 'package:equatable/equatable.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// Aggregated statistics for a wallet address account-chain.
class AccountChainStats extends Equatable {
  /// Creates an [AccountChainStats] instance.
  const AccountChainStats({
    required this.firstHash,
    required this.blockCount,
    required this.blockTypeNumOfBlocksMap,
  });

  /// Creates an [AccountChainStats] instance from a JSON map.
  factory AccountChainStats.fromJson(Map<String, dynamic> json) {
    final Map<String, dynamic> rawMap =
        json['blockTypeNumOfBlocksMap'] as Map<String, dynamic>;
    final Map<BlockTypeEnum, int> parsedMap = <BlockTypeEnum, int>{
      for (final MapEntry<String, dynamic> entry in rawMap.entries)
        BlockTypeEnum.values[int.parse(entry.key)]: entry.value as int,
    };

    return AccountChainStats(
      firstHash: Hash.parse(json['firstHash'] as String),
      blockCount: json['blockCount'] as int,
      blockTypeNumOfBlocksMap: parsedMap,
    );
  }

  /// Hash of the first block in the account-chain.
  final Hash firstHash;

  /// Total number of blocks in the account-chain.
  final int blockCount;

  /// Block counts grouped by [BlockTypeEnum].
  final Map<BlockTypeEnum, int> blockTypeNumOfBlocksMap;

  /// Converts this [AccountChainStats] instance into a JSON map.
  Map<String, dynamic> toJson() => <String, dynamic>{
    'firstHash': firstHash.toString(),
    'blockCount': blockCount,
    'blockTypeNumOfBlocksMap': <String, int>{
      for (final MapEntry<BlockTypeEnum, int> entry
          in blockTypeNumOfBlocksMap.entries)
        entry.key.index.toString(): entry.value,
    },
  };

  @override
  List<Object?> get props => <Object?>[
    firstHash,
    blockCount,
    blockTypeNumOfBlocksMap,
  ];
}
