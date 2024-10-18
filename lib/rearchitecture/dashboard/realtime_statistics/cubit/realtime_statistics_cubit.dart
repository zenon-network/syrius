import 'package:zenon_syrius_wallet_flutter/rearchitecture/dashboard/dashboard.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'realtime_statistics_state.dart';

/// `RealtimeStatisticsCubit` manages the fetching and state of real-time
/// account block statistics for a specific address.
///
/// This cubit extends `DashboardCubit<List<AccountBlock>>`, using a list of
/// `AccountBlock` objects to represent the account blocks fetched from the Zenon network.
class RealtimeStatisticsCubit extends DashboardCubit<List<AccountBlock>, RealtimeStatisticsState> {
  /// Constructs a `RealtimeStatisticsCubit`, passing the `zenon` client and the initial state
  /// to the parent class.
  ///
  /// The `zenon` client is used to interact with the Zenon network to retrieve account block information.
  RealtimeStatisticsCubit(super.zenon, super.initialState);

  /// Fetches a list of account blocks for the specified address over the past week.
  ///
  /// This method retrieves the account blocks by:
  /// - Determining the chain height using the `getFrontierMomentum()` method.
  /// - Calculating the starting height based on the momentums per week.
  /// - Fetching account blocks page by page until there are no more blocks to retrieve.
  /// - The loop continues until either the blocks are exhausted or the last block's momentum height
  ///   is less than the calculated height.
  ///
  /// Returns:
  /// - A list of `AccountBlock` objects representing the account blocks fetched from the network.
  ///
  /// Throws:
  /// - An error if no data is available or if any exception occurs during the fetching process.
  @override
  Future<List<AccountBlock>> fetch() async {
    try {
      // Get the current chain height
      final chainHeight = (await zenon.ledger.getFrontierMomentum()).height;
      // Calculate the starting height for the block retrieval
      final height = chainHeight - kMomentumsPerWeek > 0
          ? chainHeight - kMomentumsPerWeek
          : 1;
      var pageIndex = 0; // Start from the first page
      const pageSize = 10; // Number of blocks to fetch per page
      var isLastPage = false; // Flag to determine if it's the last page
      final blockList = <AccountBlock>[]; // List to store fetched account blocks

      // Fetch account blocks until the last page is reached
      while (!isLastPage) {
        // Fetch account blocks for the current page
        final response =
            (await zenon.ledger.getAccountBlocksByPage(
              Address.parse(kSelectedAddress!),
              pageIndex: pageIndex,
              pageSize: pageSize,
            ))
                .list ?? // Default to an empty list if no blocks are found
                [];

        if (response.isEmpty) {
          break; // Exit the loop if no more blocks are found
        }

        blockList.addAll(response); // Add the fetched blocks to the list

        // Check if the last block's momentum height is less than the calculated height
        if (response.last.confirmationDetail!.momentumHeight <= height) {
          break; // Exit if we've fetched enough data
        }

        pageIndex += 1; // Increment the page index for the next fetch
        isLastPage = response.length < pageSize; // Check if this is the last page
      }

      if (blockList.isNotEmpty) {
        return blockList; // Return the list of fetched blocks if available
      } else {
        throw 'No available data'; // Throw an error if no data is found
      }
    } catch (e) {
      rethrow;
    }
  }
}