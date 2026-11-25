import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/exceptions/exceptions.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'refresh_project_event.dart';
part 'refresh_project_state.dart';

/// Fetches the latest state of an Accelerator project by ID.
class RefreshProjectBloc
    extends Bloc<RefreshProjectEvent, RefreshProjectState> {
  /// Creates a [RefreshProjectBloc].
  RefreshProjectBloc({required this._zenon})
    : super(const RefreshProjectInitial()) {
    on<RefreshProjectRequested>(
      _onRefreshProjectRequested,
      transformer: restartable(),
    );
  }

  final Zenon _zenon;

  Future<void> _onRefreshProjectRequested(
    RefreshProjectRequested event,
    Emitter<RefreshProjectState> emit,
  ) async {
    emit(const RefreshProjectLoading());

    try {
      final Project project = await _zenon.embedded.accelerator.getProjectById(
        event.projectId.toString(),
      );
      if (emit.isDone) return;
      emit(RefreshProjectPopulated(project: project));
    } on SyriusException catch (e, stackTrace) {
      if (emit.isDone) return;
      addError(e, stackTrace);
      emit(RefreshProjectFailure(exception: e));
    } on Object catch (e, stackTrace) {
      if (emit.isDone) return;
      addError(e, stackTrace);
      emit(RefreshProjectFailure(exception: FailureException()));
    }
  }
}
