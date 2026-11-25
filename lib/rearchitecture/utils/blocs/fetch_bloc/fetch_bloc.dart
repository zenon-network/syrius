import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/exceptions/exceptions.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'fetch_event.dart';

part 'fetch_state.dart';

/// A bloc that fetches and persists a single data object for an address.
///
/// Subclasses provide [getData] to load the feature-specific data. A
/// [FetchRequestData] event triggers the request and emits either
/// [FetchPopulated] with the loaded data or [FetchFailure] with a
/// [SyriusException].
abstract class FetchBloc<T extends Object>
    extends HydratedBloc<FetchEvent, FetchState<T>> {
  /// Creates a new instance.
  FetchBloc({
    required this.fromJsonT,
    required this.toJsonT,
    required this.zenon,
  }) : super(FetchInitial<T>()) {
    on<FetchRequestData>(_requestData);
  }

  /// Method that helps deserializing the generic [T] type.
  final T Function(Map<String, dynamic>) fromJsonT;

  /// Method that helps serializing the generic [T] type.
  final Map<String, dynamic> Function(T) toJsonT;

  /// The [Zenon] SDK instance used for ledger interactions.
  final Zenon zenon;

  final ValueNotifier<bool> _isLoading = ValueNotifier<bool>(false);
  int _inFlightRequests = 0;

  /// Notifies listeners while a [FetchRequestData] request is in flight.
  ValueListenable<bool> get isLoadingListenable => _isLoading;

  /// Retrieves the data for [address].
  Future<T> getData({required Address address});

  Future<void> _requestData(
    FetchRequestData event,
    Emitter<FetchState<Object>> emit,
  ) async {
    _inFlightRequests++;
    if (!isClosed && !_isLoading.value) {
      _isLoading.value = true;
    }
    try {
      final T data = await getData(address: event.address);
      if (!emit.isDone) {
        emit(FetchPopulated<T>(data: data));
      }
    } on SyriusException catch (e, stackTrace) {
      if (!emit.isDone) {
        emit(FetchFailure<T>(exception: e));
      }
      addError(e, stackTrace);
    } on Exception catch (e, stackTrace) {
      if (!emit.isDone) {
        emit(FetchFailure<T>(exception: FailureException()));
      }
      addError(e, stackTrace);
    } finally {
      _inFlightRequests--;
      if (!isClosed && _inFlightRequests == 0) {
        _isLoading.value = false;
      }
    }
  }

  /// Deserializes the JSON map into a [FetchState].
  @override
  FetchState<T> fromJson(Map<String, dynamic> json) =>
      state.fromJson(json, fromJsonT);

  /// Serializes the current state into a JSON map.
  @override
  Map<String, dynamic>? toJson(FetchState<T> state) => state.toJson(toJsonT);

  @override
  Future<void> close() async {
    await super.close();
    _isLoading.dispose();
  }
}
