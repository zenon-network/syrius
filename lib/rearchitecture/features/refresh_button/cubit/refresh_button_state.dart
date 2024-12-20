part of 'refresh_button_cubit.dart';

sealed class RefreshButtonState extends Equatable {
  const RefreshButtonState();

  @override
  List<Object> get props => [];
}

final class RefreshCardInitial extends RefreshButtonState {}

final class RefreshCardLoading extends RefreshButtonState {}
