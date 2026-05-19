import 'package:equatable/equatable.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/exceptions/exceptions.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'fetch_event.dart';

part 'fetch_state.dart';

abstract class FetchBloc<T extends Object>
    extends HydratedBloc<FetchEvent, FetchState<T>> {
  FetchBloc({
    required this.fromJsonT,
    required this.toJsonT,
    required this.zenon,
  }) : super(FetchInitial<T>()) {
    on<FetchRequestData>(_requestData);
  }

  final T Function(Map<String, dynamic>) fromJsonT;
  final Map<String, dynamic> Function(T) toJsonT;
  final Zenon zenon;

  Future<T> getData({required Address address});

  Future<void> _requestData(
    FetchRequestData event,
    Emitter<FetchState<Object>> emit,
  ) async {
    try {
      final T data = await getData(address: event.address);
      emit(FetchPopulated<T>(data: data));
    } on SyriusException catch (e, stackTrace) {
      emit(
        FetchFailure<T>(
          exception: e,
        ),
      );
      addError(e, stackTrace);
    } on Exception catch (e, stackTrace) {
      emit(
        FetchFailure<T>(
          exception: FailureException(),
        ),
      );
      addError(e, stackTrace);
    }
  }

  @override
  FetchState<T> fromJson(Map<String, dynamic> json) =>
      state.fromJson(json, fromJsonT);

  @override
  Map<String, dynamic>? toJson(FetchState<T> state) =>
      state.toJson(toJsonT);
}
