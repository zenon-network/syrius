import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';

class PlasmaBeneficiaryAddressNotifier extends ChangeNotifier {
  String? _plasmaBeneficiaryAddress = kSelectedAddress;

  changePlasmaBeneficiaryAddress(String? newAddress) {
    _plasmaBeneficiaryAddress = newAddress;
    notifyListeners();
  }

  String? getBeneficiaryAddress() => _plasmaBeneficiaryAddress;
}
