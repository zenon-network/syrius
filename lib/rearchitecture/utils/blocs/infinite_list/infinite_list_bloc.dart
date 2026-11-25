import 'dart:async';

import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/constants/api.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/exceptions/exceptions.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/functions/functions.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'infinite_list_bloc.g.dart';

part 'infinite_list_event.dart';

part 'infinite_list_state.dart';

// TODO(maznnwell): adapt doc so that it doesn't refer to transactions only
/// A bloc that manages the state of the latest transactions for a specific
/// address.
///
/// Each time the app starts, an [InfiniteListRequested] event should be
/// sent. This checks if there are any new data, if so, the current list is
/// updated. In this scenario we replaced the current data with the new data.
///
/// Too fetch additional data, the [InfiniteListMoreRequested] event can
/// be used. It's sent when the user scrolled to the bottom of the list. In
/// this scenario, the new data is appended to the old data.
///
/// Eventually, if we want to refresh the data completely, we can used the
/// [InfiniteListRefreshRequested] event. This is sent when a new default
/// address was selected and we want to load the latest transactions for that
/// address. In this case, an initial state is emitted, with an empty list,
/// followed by fetching page 0 for the new address.
abstract class InfiniteListBloc<T>
    extends HydratedBloc<InfiniteListEvent, InfiniteListState<T>>
    with RefreshBlocMixin {
  /// Creates a new instance.
  InfiniteListBloc({
    required this.fromJsonT,
    required this.toJsonT,
    required this.zenon,
    required this.pageSize,
  }) : super(
         InfiniteListState<T>.initial(),
       ) {
    listenToWsRestart(
      () {
        add(
          InfiniteListRefreshRequested(
            address: Address.parse(kSelectedAddress!),
          ),
        );
      },
    );
    on<InfiniteListRequested>(
      _onInfiniteListRequested,
      transformer: throttleDroppable(kThrottleDuration),
    );
    on<InfiniteListMoreRequested>(
      _onInfiniteListMoreRequested,
    );
    on<InfiniteListRefreshRequested>(
      _onInfiniteListRefreshRequested,
      transformer: restartable(),
    );
  }

  /// The [Zenon] SDK instance used for ledger interactions.
  final Zenon zenon;

  /// THe number of results to be returned per page.
  final int pageSize;

  /// Method that helps deserializing the generic [T] type
  final T Function(Object?) fromJsonT;

  /// Method that helps serializing the generic [T] type
  final Object? Function(T) toJsonT;

  final ValueNotifier<bool> _isLoading = ValueNotifier<bool>(false);
  bool _isLoadingDisposed = false;
  int _inFlightRefreshRequests = 0;

  /// Notifies listeners while an initial or refresh page-0 fetch is in flight.
  ValueListenable<bool> get isLoadingListenable => _isLoading;

  /// Retrieves the data in a pagination manner, with the first page being 0
  Future<List<T>> paginationFetch({
    required Address? address,
    required int pageIndex,
    required int pageSize,
  });

  Future<void> _onInfiniteListRequested(
    InfiniteListRequested event,
    Emitter<InfiniteListState<T>> emit,
  ) => _fetchFirstPage(address: event.address, emit: emit);

  Future<void> _fetchFirstPage({
    required Address? address,
    required Emitter<InfiniteListState<T>> emit,
  }) async {
    _inFlightRefreshRequests++;
    if (!isClosed && !_isLoading.value) {
      _isLoading.value = true;
    }
    try {
      final List<T> newData = await paginationFetch(
        address: address,
        pageIndex: 0,
        pageSize: pageSize,
      );
      if (emit.isDone) {
        return;
      }

      final bool hasReachedMax = newData.length < pageSize;

      emit(
        state.copyWith(
          data: newData,
          hasReachedMax: hasReachedMax,
          status: InfiniteListStatus.success,
        ),
      );
    } on Object catch (error, stackTrace) {
      if (emit.isDone) {
        return;
      }
      addError(error, stackTrace);
      emit(
        state.copyWith(
          status: InfiniteListStatus.failure,
          error: FailureException(),
        ),
      );
    } finally {
      _inFlightRefreshRequests--;
      if (!isClosed && _inFlightRefreshRequests == 0) {
        _isLoading.value = false;
      }
    }
  }

  Future<void> _onInfiniteListMoreRequested(
    InfiniteListMoreRequested event,
    Emitter<InfiniteListState<T>> emit,
  ) async {
    if (state.hasReachedMax) return;
    final List<T> currentData = state.data ?? <T>[];
    final int previousNumOfItems = currentData.length;
    final int pageIndex = previousNumOfItems ~/ pageSize;
    try {
      final List<T> data = await paginationFetch(
        address: event.address,
        pageIndex: pageIndex,
        pageSize: pageSize,
      );
      if (emit.isDone) {
        return;
      }

      final bool hasReachedMax = data.length < pageSize;

      emit(
        state.copyWith(
          data: <T>[
            ...currentData,
            ...data,
          ],
          hasReachedMax: hasReachedMax,
          status: InfiniteListStatus.success,
        ),
      );
    } on Object catch (error, stackTrace) {
      if (emit.isDone) {
        return;
      }
      addError(error, stackTrace);
      emit(
        state.copyWith(
          status: InfiniteListStatus.failure,
          error: FailureException(),
        ),
      );
    }
  }

  Future<void> _onInfiniteListRefreshRequested(
    InfiniteListRefreshRequested event,
    Emitter<InfiniteListState<T>> emit,
  ) async {
    emit(InfiniteListState<T>.initial());
    await _fetchFirstPage(address: event.address, emit: emit);
  }

  /// Deserializes the JSON map into a [InfiniteListState].
  @override
  InfiniteListState<T>? fromJson(Map<String, dynamic> json) =>
      InfiniteListState<T>.fromJson(json, fromJsonT);

  /// Serializes the current state into a JSON map.
  @override
  Map<String, dynamic>? toJson(InfiniteListState<T> state) => state.toJson(
    toJsonT,
  );

  @override
  Future<void> close() async {
    cancelStreamSubscription();
    await super.close();
    if (!_isLoadingDisposed) {
      _isLoadingDisposed = true;
      _isLoading.dispose();
    }
  }
}
