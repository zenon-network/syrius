part of 'fetch_bloc.dart';

sealed class FetchEvent extends Equatable {
  const FetchEvent();

  @override
  List<Object> get props => [];
}

final class FetchRequestData extends FetchEvent {
  const FetchRequestData({required this.address});

  final Address address;

  @override
  List<Object> get props => [address];
}
