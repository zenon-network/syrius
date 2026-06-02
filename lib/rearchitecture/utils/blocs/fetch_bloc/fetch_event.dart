part of 'fetch_bloc.dart';

/// The generic class for the events used in [FetchBloc].
sealed class FetchEvent extends Equatable {
  /// Creates a new instance.
  const FetchEvent();

  @override
  List<Object> get props => <Object>[];
}

/// Event to be used when we want to fetch data for an [address].
final class FetchRequestData extends FetchEvent {
  /// Creates a new instance.
  const FetchRequestData({required this.address});

  /// The [address] for which data will be fetched.
  final Address address;

  @override
  List<Object> get props => <Object>[address];
}
