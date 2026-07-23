import 'package:equatable/equatable.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'all_tokens_event.dart';

part 'all_tokens_state.dart';

/// A bloc who's purpose is to retrieve the available list of all_tokens
///
/// It uses the class [AllTokensState] to send updates to the UI
class AllTokensBloc extends HydratedBloc<AllTokensEvent, AllTokensState>
    with RefreshBlocMixin {
  /// Creates a new instance.
  AllTokensBloc({required this.zenon}) : super(const AllTokensInitial()) {
    on<AllTokensRequested>(_onTokensRequested);
    listenToWsRestart(() => add(const AllTokensRequested()));
  }

  /// The client used to interact with the Zenon network
  final Zenon zenon;

  Future<void> _onTokensRequested(
    AllTokensRequested _,
    Emitter<AllTokensState> emit,
  ) async {
    try {
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

      emit(
        AllTokensPopulated(
          data: tokens,
        ),
      );
    } on SyriusException catch (error, stackTrace) {
      emit(AllTokensFailure(exception: error));
      addError(error, stackTrace);
    } on Exception catch (error, stackTrace) {
      emit(AllTokensFailure(exception: FailureException()));
      addError(error, stackTrace);
    }
  }

  @override
  AllTokensState? fromJson(Map<String, dynamic> json) =>
      AllTokensState.fromJson(json);

  @override
  Map<String, dynamic>? toJson(AllTokensState state) => state.toJson();

  @override
  Future<void> close() async {
    cancelStreamSubscription();
    await super.close();
  }
}
