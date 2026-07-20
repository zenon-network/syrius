import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// A bloc that fetches the paginated list of tokens from the network.
class TokenMapBloc extends InfiniteListBloc<Token> {
  /// Creates a new instance.
  TokenMapBloc({required super.zenon, super.pageSize = kPageSize})
    : super(
        fromJsonT: (Object? map) => Token.fromJson(
          map! as Map<String, dynamic>,
        ),
        toJsonT: (Token token) => token.toJson(),
      );

  @override
  Future<List<Token>> paginationFetch({
    required int pageIndex,
    required int pageSize,
    Address? address,
  }) async {
    final TokenList tokenList = await zenon.embedded.token.getAll(
      pageIndex: pageIndex,
      pageSize: pageSize,
    );

    return tokenList.list ?? <Token>[];
  }
}
