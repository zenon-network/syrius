import 'package:equatable/equatable.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'tokens_state.dart';

part 'tokens_cubit.g.dart';

/// A cubit who's purpose is to retrieve the available list of tokens
///
/// It uses the class [TokensState] to send updates to the UI
class TokensCubit extends HydratedCubit<TokensState> with RefreshBlocMixin {
  /// Creates a new instance.
  TokensCubit({required this.zenon}) : super(const TokensState.initial()) {
    listenToWsRestart(fetch);
  }

  /// The client used to interact with the Zenon network
  final Zenon zenon;

  /// A function that retrieves the list of tokens and emits state updates
  Future<void> fetch() async {
    try {
      final TokenList tokenList = await zenon.embedded.token.getAll();
      final List<Token> tokens = tokenList.list ?? <Token>[];
      emit(
        state.copyWith(
          status: TokensStatus.success,
          data: tokens,
        ),
      );
    } catch (error, stackTrace) {
      emit(
        state.copyWith(
          error: FailureException(),
        ),
      );
      addError(error, stackTrace);
    }
  }

  @override
  TokensState? fromJson(Map<String, dynamic> json) =>
      TokensState.fromJson(json);

  @override
  Map<String, dynamic>? toJson(TokensState state) => state.toJson();
}
