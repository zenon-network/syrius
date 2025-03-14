part of 'fetch_bloc.dart';

sealed class FetchState<T extends Object> extends Equatable {
  const FetchState();

  @override
  List<Object> get props => <Object>[];

  Map<String, dynamic> toJson(Map<String, dynamic> Function(T) toJsonT) {
    return switch (this) {
      FetchFailure() => {
          'state': 'failure',
          'exception': (this as FetchFailure).exception.toJson(),
        },
      FetchInitial() => {
          'state': 'initial',
        },
      FetchPopulated<Object>() => {
          'state': 'populated',
          'data': toJsonT((this as FetchPopulated<T>).data),
        },
    };
  }

  FetchState<Object> fromJson(
      Map<String, dynamic> json,
      T Function(Map<String, dynamic>) fromJsonT,
      ) {
    switch (json['state']) {
      case 'failure':
        final Map<String, dynamic> exceptionJson = json['exception'];

        final SyriusException exception = SyriusException.fromJson(exceptionJson);

        return FetchFailure(exception: exception);
      case 'initial':
        return const FetchInitial();
      case 'populated':
        final Map<String, dynamic> dataJson = json['data'];

        return FetchPopulated<T>(data: fromJsonT(dataJson));
      default:
        throw UnsupportedError('State unsupported');
    }
  }
}

final class FetchFailure extends FetchState {
  const FetchFailure({required this.exception});

  final SyriusException exception;

  @override
  List<Object> get props => <Object>[exception];
}

final class FetchInitial extends FetchState {
  const FetchInitial();

  factory FetchInitial.fromJson(Map<String, dynamic> json) =>
      FetchInitial();
}

final class FetchPopulated<T extends Object> extends FetchState {
  const FetchPopulated({required this.data});

  final T data;

  @override
  List<Object> get props => <Object>[data];
}
