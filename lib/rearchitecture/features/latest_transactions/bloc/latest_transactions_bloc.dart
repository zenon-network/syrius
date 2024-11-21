import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:stream_transform/stream_transform.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/exceptions/exceptions.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'latest_transactions_bloc.g.dart';

part 'latest_transactions_event.dart';

part 'latest_transactions_state.dart';

const int _pageSize = 10;
const Duration _throttleDuration = Duration(milliseconds: 100);

EventTransformer<E> _throttleDroppable<E>(Duration duration) {
  return (Stream<E> events, EventMapper<E> mapper) {
    return droppable<E>().call(events.throttle(duration), mapper);
  };
}

/// A bloc that manages the state of the latest transactions for a specific
/// address.
class LatestTransactionsBloc
    extends HydratedBloc<LatestTransactionsEvent, LatestTransactionsState> {
  /// Creates an instance of [LatestTransactionsBloc].
  ///
  /// The constructor requires a [Zenon] SDK instance.
  LatestTransactionsBloc({required this.zenon})
      : super(
          const LatestTransactionsState(),
        ) {
    on<LatestTransactionsRequested>(
      _onLatestTransactionsRequested,
      transformer: _throttleDroppable(
        _throttleDuration,
      ),
    );
    on<LatestTransactionsRefreshRequested>(
      _onLatestTransactionsRefreshRequested,
    );
  }

  /// The [Zenon] SDK instance used for ledger interactions.
  final Zenon zenon;

  Future<void> _onLatestTransactionsRequested(
    LatestTransactionsRequested event,
    Emitter<LatestTransactionsState> emit,
  ) async {
    if (state.hasReachedMax) return;
    final int previousNumOfItems = state.data.length;
    final int pageIndex = previousNumOfItems ~/ _pageSize;
    try {
      final AccountBlockList accountBlock =
          await zenon.ledger.getAccountBlocksByPage(
        event.address,
        pageIndex: pageIndex,
        pageSize: _pageSize,
      );

      final List<AccountBlock> data = accountBlock.list!;

      final bool hasReachedMax = data.length < _pageSize;

      emit(
        state.copyWith(
          data: <AccountBlock>[
            ...state.data,
            ...data,
          ],
          hasReachedMax: hasReachedMax,
          status: LatestTransactionsStatus.success,
        ),
      );
    } catch (error, stackTrace) {
      addError(error, stackTrace);
      emit(
        state.copyWith(
          status: LatestTransactionsStatus.failure,
          error: FailureException(),
        ),
      );
    }
  }

  FutureOr<void> _onLatestTransactionsRefreshRequested(
    LatestTransactionsRefreshRequested event,
    Emitter<LatestTransactionsState> emit,
  ) {
    emit(const LatestTransactionsState());
    add(LatestTransactionsRequested(address: event.address));
  }

  /// Deserializes the JSON map into a [LatestTransactionsState].
  @override
  LatestTransactionsState? fromJson(Map<String, dynamic> json) =>
      LatestTransactionsState.fromJson(json);

  /// Serializes the current state into a JSON map.
  @override
  Map<String, dynamic>? toJson(LatestTransactionsState state) => state.toJson();
}
