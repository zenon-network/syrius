import 'package:json_annotation/json_annotation.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'realtime_statistics_cubit.g.dart';

part 'realtime_statistics_state.dart';

/// [RealtimeStatisticsCubit] manages the fetching and state of real-time
/// account block statistics for a specific address.
///
/// It uses a list of [AccountBlock] objects to represent the account blocks
/// fetched from the Zenon network.
class RealtimeStatisticsCubit
    extends TimerCubit<List<AccountBlock>, RealtimeStatisticsState> {
  /// Constructs a [RealtimeStatisticsCubit], passing the [zenon] client and
  /// the initial state to the parent class.
  ///
  /// The [zenon] client is used to interact with the Zenon network to retrieve
  /// account block information.
  RealtimeStatisticsCubit({
    required this.address,
    required super.zenon,
    super.initialState = const RealtimeStatisticsState(),
  });

  ///The address for which the list of account blocks is fetched
  final Address address;

  /// Fetches a list of account blocks for the specified address over the past
  /// week.
  ///
  /// This method retrieves the account blocks by:
  /// - Determining the chain height.
  /// - Calculating the starting height based on the momentums per week.
  /// - Fetching account blocks page by page until there are no more blocks to
  /// retrieve.
  /// - The loop continues until either the blocks are exhausted or the last
  /// block's momentum height is less than the calculated height.
  ///
  /// Returns:
  /// - A list of [AccountBlock] objects representing the account blocks
  /// fetched from the network.
  ///
  /// Throws:
  /// - An [NoBlocksAvailableException] if no data is available
  @override
  Future<List<AccountBlock>> fetch() async {
    // Get the current chain height
    final int chainHeight = (await zenon.ledger.getFrontierMomentum()).height;
    // Calculate the starting height for the block retrieval
    final int height = chainHeight - kMomentumsPerWeek > 0
        ? chainHeight - kMomentumsPerWeek
        : 1;
    int pageIndex = 0; // Start from the first page
    const int pageSize = 10; // Number of blocks to fetch per page
    bool isLastPage = false; // Flag to determine if it's the last page
    final List<AccountBlock> blockList =
        <AccountBlock>[]; // List to store fetched account blocks

    // Fetch account blocks until the last page is reached
    while (!isLastPage) {
      // Fetch account blocks for the current page
      final AccountBlockList accountBlockList =
          await zenon.ledger.getAccountBlocksByPage(
        address,
        pageIndex: pageIndex,
        pageSize: pageSize,
      );
      // Default to an empty list if no blocks are found
      final List<AccountBlock> response =
          accountBlockList.list ?? <AccountBlock>[];

      if (response.isEmpty) {
        break; // Exit the loop if no more blocks are found
      }

      blockList.addAll(response); // Add the fetched blocks to the list

      // Check if the last block's momentum height is less than the
      // calculated height
      if (response.last.confirmationDetail!.momentumHeight <= height) {
        break; // Exit if we've fetched enough data
      }

      pageIndex += 1; // Increment the page index for the next fetch
      isLastPage = response.length < pageSize; // Check if this is the last page
    }

    if (blockList.isNotEmpty) {
      return blockList; // Return the list of fetched blocks if available
    } else {
      throw NoBlocksAvailableException();
    }
  }

  @override
  RealtimeStatisticsState? fromJson(Map<String, dynamic> json) =>
      RealtimeStatisticsState.fromJson(
        json,
      );

  @override
  Map<String, dynamic>? toJson(RealtimeStatisticsState state) => state.toJson();
}
