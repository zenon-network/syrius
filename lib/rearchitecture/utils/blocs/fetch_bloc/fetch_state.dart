part of 'fetch_bloc.dart';

/// The generic class for the states used in [FetchBloc].
sealed class FetchState<T extends Object> extends Equatable {
  /// Creates a new instance.
  const FetchState();

  @override
  List<Object> get props => <Object>[];

  /// Converts this state into a JSON map for persistence.
  Map<String, dynamic> toJson(Map<String, dynamic> Function(T) toJsonT) {
    return switch (this) {
      FetchFailure<T>(:final SyriusException exception) => <String, dynamic>{
        'state': 'failure',
        'exception': exception.toJson(),
      },
      FetchInitial<T>() => <String, dynamic>{
        'state': 'initial',
      },
      FetchPopulated<T>(:final T data) => <String, dynamic>{
        'state': 'populated',
        'data': toJsonT(data),
      },
    };
  }

  /// Creates a new [FetchState] from a JSON object.
  FetchState<T> fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    switch (json['state']) {
      case 'failure':
        final Map<String, dynamic> exceptionJson = json['exception'];

        final SyriusException exception = SyriusException.fromJson(
          exceptionJson,
        );

        return FetchFailure<T>(exception: exception);
      case 'initial':
        return FetchInitial<T>();
      case 'populated':
        final Map<String, dynamic> dataJson = json['data'];

        return FetchPopulated<T>(data: fromJsonT(dataJson));
      default:
        throw UnsupportedError('State unsupported');
    }
  }
}

/// State emitted when fetching data fails.
final class FetchFailure<T extends Object> extends FetchState<T> {
  /// Creates a new instance.
  const FetchFailure({required this.exception});

  /// The error that caused the fetch operation to fail.
  final SyriusException exception;

  @override
  List<Object> get props => <Object>[exception];
}

/// Initial state before any fetch action has been taken.
final class FetchInitial<T extends Object> extends FetchState<T> {
  /// Creates a new instance.
  const FetchInitial();

  /// Creates a new [FetchInitial] from a JSON object.
  factory FetchInitial.fromJson(Map<String, dynamic> _) => FetchInitial<T>();
}

/// State emitted when data has been successfully fetched.
final class FetchPopulated<T extends Object> extends FetchState<T> {
  /// Creates a new instance.
  const FetchPopulated({required this.data});

  /// The fetched data.
  final T data;

  @override
  List<Object> get props => <Object>[data];
}
