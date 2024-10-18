import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class Signature {

  Signature(this.signature, this.publicKey);
  String signature;
  String publicKey;
}

Future<Signature> walletSign(List<int> message) async {
  final wallet = await kWalletFile!.open();
  try {
    final walletAccount = await wallet
        .getAccount(kDefaultAddressList.indexOf(kSelectedAddress));
    final publicKey = await walletAccount.getPublicKey();
    final signature = await walletAccount.sign(
      Uint8List.fromList(
        message,
      ),
    );
    return Signature(
        BytesUtils.bytesToHex(signature), BytesUtils.bytesToHex(publicKey),);
  } finally {
    kWalletFile!.close();
  }
}

Future<dynamic> loadJsonFromAssets(String filePath) async {
  final jsonString = await rootBundle.loadString(filePath);
  return jsonDecode(jsonString);
}