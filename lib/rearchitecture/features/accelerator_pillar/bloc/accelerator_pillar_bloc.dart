import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/accelerator_pillar/accelerator_pillar.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/exceptions/exceptions.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'accelerator_pillar_event.dart';
part 'accelerator_pillar_state.dart';

/// Resolves whether a selected wallet address owns or produces a Pillar for
/// Accelerator voting and UI filtering.
class AcceleratorPillarBloc
    extends Bloc<AcceleratorPillarEvent, AcceleratorPillarState> {
  /// Creates an [AcceleratorPillarBloc].
  AcceleratorPillarBloc({
    required this._zenon,
    this._pageSize = kPillarRegistryPageSize,
  }) : super(const AcceleratorPillarInitial()) {
    on<AcceleratorPillarRequested>(
      _onAcceleratorPillarRequested,
      transformer: restartable(),
    );
  }

  final Zenon _zenon;
  final int _pageSize;

  Future<void> _onAcceleratorPillarRequested(
    AcceleratorPillarRequested event,
    Emitter<AcceleratorPillarState> emit,
  ) async {
    emit(AcceleratorPillarLoading(address: event.address));

    try {
      final ResolvedPillarResult resolved = await resolvePillarForAddress(
        zenon: _zenon,
        address: event.address,
        pageSize: _pageSize,
      );
      if (emit.isDone) return;

      int? activePillarCount = resolved.activePillarCount ?? kNumOfPillars;
      if (activePillarCount == null) {
        activePillarCount = await _tryFetchPillarCount();
        if (emit.isDone) return;
      }
      if (activePillarCount != null && activePillarCount > 0) {
        kNumOfPillars = activePillarCount;
      }

      emit(
        AcceleratorPillarPopulated(
          address: event.address,
          pillarInfo: resolved.pillarInfo,
          activePillarCount: activePillarCount,
        ),
      );
    } on SyriusException catch (e, stackTrace) {
      if (emit.isDone) return;
      addError(e, stackTrace);
      emit(AcceleratorPillarFailure(exception: e));
    } on Object catch (e, stackTrace) {
      if (emit.isDone) return;
      addError(e, stackTrace);
      emit(AcceleratorPillarFailure(exception: FailureException()));
    }
  }

  Future<int?> _tryFetchPillarCount() async {
    try {
      final PillarInfoList page = await _zenon.embedded.pillar.getAll(
        pageSize: 1,
      );
      return page.count;
    } on Object {
      return null;
    }
  }
}
