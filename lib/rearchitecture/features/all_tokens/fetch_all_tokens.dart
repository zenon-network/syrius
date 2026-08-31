import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// Returns all available tokens, exceeding the [rpcMaxPageSize]
Future<List<Token>> fetchAllTokens({
  required Zenon zenon,
}) async {
    final List<Token> tokens = <Token>[];
    int pageIndex = 0;

    while (true) {
      final TokenList tokenList = await zenon.embedded.token.getAll(
        pageIndex: pageIndex,
        // Keep the loop termination condition aligned with the RPC request.
        // ignore: avoid_redundant_argument_values
        pageSize: rpcMaxPageSize,
      );
      final List<Token> page = tokenList.list ?? <Token>[];
      tokens.addAll(page);

      if (page.length < rpcMaxPageSize) {
        break;
      }

      pageIndex++;
    }

    return tokens;
}
