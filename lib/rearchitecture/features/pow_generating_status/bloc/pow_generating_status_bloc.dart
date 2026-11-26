import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'pow_generating_status_event.dart';
part 'pow_generating_status_state.dart';

/// BLoC tracking whether proof-of-work plasma is currently being generated.
class PowGeneratingStatusBloc
    extends Bloc<PowGeneratingStatusEvent, PowGeneratingStatusState> {
  /// Creates a [PowGeneratingStatusBloc].
  PowGeneratingStatusBloc() : super(const PowGeneratingStatusState()) {
    on<PowGeneratingStatusChanged>(_onStatusChanged);
  }

  int _activeCount = 0;

  void _onStatusChanged(
    PowGeneratingStatusChanged event,
    Emitter<PowGeneratingStatusState> emit,
  ) {
    switch (event.status) {
      case PowStatus.generating:
        _activeCount += 1;
      case PowStatus.done:
        if (_activeCount > 0) {
          _activeCount -= 1;
        }
    }
    final PowStatus nextStatus = _activeCount > 0
        ? PowStatus.generating
        : PowStatus.done;
    if (nextStatus != state.status) {
      emit(PowGeneratingStatusState(status: nextStatus));
    }
  }
}
