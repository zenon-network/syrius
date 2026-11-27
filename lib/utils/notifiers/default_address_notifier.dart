import 'dart:async';

import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/services/i_web3wallet_service.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';

/// Notifies listeners when the active selected wallet address changes.
class SelectedAddressNotifier extends ChangeNotifier {
  /// Updates [kSelectedAddress] to [newSelectedAddress], broadcasts the change
  /// to WalletConnect sessions, and notifies listeners.
  void changeSelectedAddress(String? newSelectedAddress) {
    kSelectedAddress = newSelectedAddress;
    unawaited(
      sl<IWeb3WalletService>().emitAddressChangeEvent(newSelectedAddress!),
    );
    notifyListeners();
  }
}
