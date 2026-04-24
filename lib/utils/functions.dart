import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class Signature {
  String signature;
  String publicKey;

  Signature(this.signature, this.publicKey);
}

Future<Signature> walletSign(
  List<int> message, {
  String? address,
}) async {
  final wallet = await kWalletFile!.open();
  try {
    final signerAddress = address ?? kSelectedAddress;
    final signerIndex = kDefaultAddressList.indexOf(signerAddress);

    if (signerAddress == null || signerIndex < 0) {
      throw StateError('Unable to resolve signing address: $signerAddress');
    }

    final walletAccount = await wallet.getAccount(signerIndex);
    List<int> publicKey = await walletAccount.getPublicKey();
    List<int> signature = await walletAccount.sign(
      Uint8List.fromList(
        message,
      ),
    );
    return Signature(
      BytesUtils.bytesToHex(signature),
      BytesUtils.bytesToHex(publicKey),
    );
  } finally {
    kWalletFile!.close();
  }
}

Future<dynamic> loadJsonFromAssets(String filePath) async {
  String jsonString = await rootBundle.loadString(filePath);
  return jsonDecode(jsonString);
}
