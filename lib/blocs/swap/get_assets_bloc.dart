import 'dart:async';

import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/utils/address_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:zenon_syrius_wallet_flutter/utils/pair.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';
import 'package:znn_swap_utility/znn_swap_utility.dart';

class GetAssetsBloc
    extends BaseBloc<Pair<List<SwapAssetEntry>, List<SwapFileEntry>>?> {
  Future<void> getAssetAndSwapFileEntries(
    List<SwapFileEntry> swapFileEntries,
  ) async {
    try {
      addEvent(null);
      List<SwapAssetEntry> swapAssetEntries = [];
      Iterable<String> keyIds = swapFileEntries.map((e) => e.keyIdHashHex);
      Map<String, SwapAssetEntry> keyIdAssetsMap =
          await zenon!.embedded.swap.getAssets();
      for (var key in keyIds) {
        if (keyIdAssetsMap.containsKey(key)) {
          keyIdAssetsMap[key]!.keyIdHash = Hash.parse(key);
          swapAssetEntries.add(keyIdAssetsMap[key]!);
        }
      }
      var filteredSwapFileEntries = swapFileEntries
          .where((swapFileEntry) => swapAssetEntries
              .map((e) => e.keyIdHash.toString())
              .toList()
              .contains(swapFileEntry.keyIdHashHex))
          .toList();
      if (swapAssetEntries.length > kDefaultAddressList.length) {
        int numOfAddressesNeeded =
            swapAssetEntries.length - kDefaultAddressList.length;
        await Future.forEach(
          List.generate(numOfAddressesNeeded, (index) => null),
          (element) async => await AddressUtils.generateNewAddress(),
        );
      }
      addEvent(Pair(swapAssetEntries, filteredSwapFileEntries));
    } catch (e) {
      addError(e);
    }
  }
}
