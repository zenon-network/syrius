import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/constants/api.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/exceptions/exceptions.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/functions/functions.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'infinite_list_bloc.g.dart';

part 'infinite_list_event.dart';

part 'infinite_list_state.dart';

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
/// followed by an event of [InfiniteListRequested] that restarts the
/// fetching process for the new address
abstract class InfiniteListBloc<T>
    extends HydratedBloc<InfiniteListEvent, InfiniteListState<T>> {
  /// Creates a new instance.
  InfiniteListBloc({
    required this.fromJsonT,
    required this.toJsonT,
    required this.zenon,
  }) : super(
          InfiniteListState<T>.initial(),
        ) {
    on<InfiniteListRequested>(
      _onInfiniteListRequested,
      transformer: throttleDroppable(kThrottleDuration),
    );
    on<InfiniteListMoreRequested>(
      _onInfiniteListMoreRequested,
    );
    on<InfiniteListRefreshRequested>(
      _onInfiniteListRefreshRequested,
    );
  }

  /// The [Zenon] SDK instance used for ledger interactions.
  final Zenon zenon;

  final T Function(Object?) fromJsonT;
  final Object? Function(T) toJsonT;

  Future<List<T>> paginationFetch({
    required Address address,
    required int pageIndex,
    required int pageSize,
  });

  Future<void> _onInfiniteListRequested(
    InfiniteListRequested event,
    Emitter<InfiniteListState<T>> emit,
  ) async {
    final List<T> currentData = state.data;
    try {
      final List<T> newData = await paginationFetch(
        address: event.address,
        pageIndex: 0,
        pageSize: kPageSize,
      );

      final bool hasReachedMax = newData.length < kPageSize;

      final List<T> finalData = <T>[
        ...currentData,
      ];

      if (currentData.isEmpty || currentData.first != newData.first) {
        finalData
          ..clear()
          ..addAll(newData);
      }

      emit(
        state.copyWith(
          data: finalData,
          hasReachedMax: hasReachedMax,
          status: InfiniteListStatus.success,
        ),
      );
    } catch (error, stackTrace) {
      addError(error, stackTrace);
      emit(
        state.copyWith(
          status: InfiniteListStatus.failure,
          error: FailureException(),
        ),
      );
    }
  }

  Future<void> _onInfiniteListMoreRequested(
    InfiniteListMoreRequested event,
    Emitter<InfiniteListState<T>> emit,
  ) async {
    if (state.hasReachedMax) return;
    final List<T> currentData = state.data;
    final int previousNumOfItems = currentData.length;
    final int pageIndex = previousNumOfItems ~/ kPageSize;
    try {
      final List<T> data = await paginationFetch(
        address: event.address,
        pageIndex: pageIndex,
        pageSize: kPageSize,
      );

      final bool hasReachedMax = data.length < kPageSize;

      emit(
        state.copyWith(
          data: <T>[
            ...state.data,
            ...data,
          ],
          hasReachedMax: hasReachedMax,
          status: InfiniteListStatus.success,
        ),
      );
    } catch (error, stackTrace) {
      addError(error, stackTrace);
      emit(
        state.copyWith(
          status: InfiniteListStatus.failure,
          error: FailureException(),
        ),
      );
    }
  }

  FutureOr<void> _onInfiniteListRefreshRequested(
    InfiniteListRefreshRequested event,
    Emitter<InfiniteListState<T>> emit,
  ) {
    emit(InfiniteListState<T>.initial());
    add(InfiniteListRequested(address: event.address));
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
}
