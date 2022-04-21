import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';

class SelectedAddressNotifier extends ChangeNotifier {
  void changeSelectedAddress(String? newSelectedAddress) {
    kSelectedAddress = newSelectedAddress;
    notifyListeners();
  }
}
