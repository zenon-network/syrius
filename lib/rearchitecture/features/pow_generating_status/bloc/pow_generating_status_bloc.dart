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

  void _onStatusChanged(
    PowGeneratingStatusChanged event,
    Emitter<PowGeneratingStatusState> emit,
  ) {
    emit(PowGeneratingStatusState(status: event.status));
  }
}
