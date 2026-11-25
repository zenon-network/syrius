part of 'about_bloc.dart';

/// Base event for [AboutBloc].
sealed class AboutEvent extends Equatable {
  const AboutEvent();

  @override
  List<Object?> get props => const <Object?>[];
}

/// Requests loading or refreshing the wallet and node component details.
final class AboutRequested extends AboutEvent {
  /// Creates an [AboutRequested] event.
  const AboutRequested();
}
