import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/utils/keystore_utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class DecryptKeyStoreBloc extends BaseBloc<KeyStore?> {
  Future<void> decryptKeyStoreFile(String path, String password) async {
    try {
      addEvent(null);
      KeyStore keyStore =
          await KeyStoreUtils.decryptKeyStoreFile(path, password);
      addEvent(keyStore);
    } catch (e, stackTrace) {
      addError(e, stackTrace);
    }
  }
}
