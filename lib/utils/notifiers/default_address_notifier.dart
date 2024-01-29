import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/services/wallet_connect_service.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';

class SelectedAddressNotifier extends ChangeNotifier {
  void changeSelectedAddress(String? newSelectedAddress) {
    kSelectedAddress = newSelectedAddress;
    sl<WalletConnectService>().emitAddressChangeEvent(newSelectedAddress!);
    notifyListeners();
  }
}
