import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/utils/wallet_file.dart';
import 'package:zenon_syrius_wallet_flutter/utils/wallet_utils.dart';

class DecryptWalletFileBloc extends BaseBloc<WalletFile?> {
  Future<void> decryptWalletFile(String path, String password) async {
    try {
      addEvent(null);
      final WalletFile walletFile = await WalletUtils.decryptWalletFile(path, password);
      addEvent(walletFile);
    } catch (e, stackTrace) {
      addError(e, stackTrace);
    }
  }
}
