import 'package:znn_sdk_dart/znn_sdk_dart.dart';

abstract class AccountBlockTemplateSendInterface {
  AccountBlockTemplate createSendBlock(
      Address toAddress,
      TokenStandard tokenStandard,
      BigInt amount, [
        List<int>? data,
      ]);
}

class AccountBlockTemplateSend implements AccountBlockTemplateSendInterface {
  @override
  AccountBlockTemplate createSendBlock(
      Address toAddress,
      TokenStandard tokenStandard,
      BigInt amount, [
        List<int>? data,
      ]) {
    return AccountBlockTemplate.send(toAddress, tokenStandard, amount, data);
  }
}
