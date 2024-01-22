import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/utils/wallet_file.dart';
import 'package:zenon_syrius_wallet_flutter/utils/wallet_utils.dart';

class DecryptWalletFileBloc extends BaseBloc<WalletFile?> {
  Future<void> decryptWalletFile(String type, String path, String password) async {
    try {
      addEvent(null);
      final walletFile = await WalletUtils.decryptWalletFile(type, path, password);
      addEvent(walletFile);
    } catch (e, stackTrace) {
      addError(e, stackTrace);
    }
  }
}
