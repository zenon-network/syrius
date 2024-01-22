import 'package:flutter/services.dart';
import 'package:zenon_syrius_wallet_flutter/utils/wallet_utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class Signature {
  String signature;
  String publicKey;

  Signature(this.signature, this.publicKey);
}

Future<Signature> walletSign(List<int> message) async {
  WalletAccount walletAccount = await WalletUtils.defaultAccount();
  List<int> publicKey = await walletAccount.getPublicKey();
  List<int> signature = await walletAccount.sign(
    Uint8List.fromList(
      message,
    ),
  );

  return Signature(
      BytesUtils.bytesToHex(signature), BytesUtils.bytesToHex(publicKey));
}
