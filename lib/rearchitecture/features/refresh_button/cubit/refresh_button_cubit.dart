import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

part 'refresh_button_state.dart';

class RefreshButtonCubit extends Cubit<RefreshButtonState> {
  RefreshButtonCubit({
    required Future<void> Function() refreshCallback,
  })  : _refreshCallback = refreshCallback,
        super(RefreshCardInitial());

  final Future<void> Function() _refreshCallback;

  Future<void> executeRefreshOperation() async {
    emit(RefreshCardLoading());
    try {
      await _refreshCallback();
    } catch (_) {
    } finally {
      emit(RefreshCardInitial());
    }
  }
}
