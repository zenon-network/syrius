import 'package:equatable/equatable.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/exceptions/exceptions.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'fetch_event.dart';

part 'fetch_state.dart';

abstract class FetchBloc<T extends Object>
    extends HydratedBloc<FetchEvent, FetchState> {
  FetchBloc({
    required this.fromJsonT,
    required this.toJsonT,
  }) : super(const FetchInitial()) {
    on<FetchRequestData>(_requestData);
  }

  final T Function(Map<String, dynamic>) fromJsonT;
  final Map<String, dynamic> Function(Object) toJsonT;

  Future<T> getData({required Address address});

  Future<void> _requestData(
    FetchRequestData event,
    Emitter<FetchState<Object>> emit,
  ) async {
    try {
      final T data = await getData(address: event.address);
      emit(FetchPopulated<T>(data: data));
    } on Exception catch (e, stackTrace) {
      emit(
        FetchFailure(
          exception: FailureException(),
        ),
      );
      addError(e, stackTrace);
    }
  }

  @override
  FetchState<Object> fromJson(Map<String, dynamic> json) =>
      state.fromJson(json, fromJsonT);

  @override
  Map<String, dynamic>? toJson(FetchState<Object> state) =>
      state.toJson(toJsonT);
}
