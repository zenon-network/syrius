import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'pending_transactions_bloc.g.dart';

part 'pending_transactions_event.dart';

part 'pending_transactions_state.dart';

/// A cubit responsible for fetching and managing the list of pending
/// transactions for an address, specified through the
/// [PendingTransactionsEvent].
class PendingTransactionsBloc
    extends HydratedBloc<PendingTransactionsEvent, PendingTransactionsState> {
  /// Creates a new [PendingTransactionsBloc] instance.
  ///
  /// Requires a [Zenon] instance to interact with the ledger
  PendingTransactionsBloc({
    required this.zenon,
  }) : super(const PendingTransactionsState()) {
    on<PendingTransactionsRequested>(_onPendingTransactionsRequested);
    on<PendingTransactionsRefreshRequested>(
      _onPendingTransactionsRefreshRequested,
      transformer: throttleDroppable(kThrottleDuration),
    );
  }

  /// The instance of [Zenon] used to interact with the ledger.
  final Zenon zenon;

  Future<void> _onPendingTransactionsRequested(
    PendingTransactionsRequested event,
    Emitter<PendingTransactionsState> emit,
  ) async {
    if (state.hasReachedMax) return;
    final List<AccountBlock> currentData = state.data;
    final int previousNumOfItems = currentData.length;
    final int pageIndex = previousNumOfItems ~/ kPageSize;
    try {
      final AccountBlockList accountBlock =
          await zenon.ledger.getUnreceivedBlocksByAddress(
        event.address,
        pageIndex: pageIndex,
        pageSize: kPageSize,
      );

      final List<AccountBlock> newData = accountBlock.list!;

      final bool hasReachedMax = newData.length < kPageSize;

      final List<AccountBlock> finalData = <AccountBlock>[
        ...currentData,
        ...newData,
      ];

      emit(
        state.copyWith(
          data: finalData,
          hasReachedMax: hasReachedMax,
          status: PendingTransactionsStatus.success,
        ),
      );
    } catch (error, stackTrace) {
      addError(error, stackTrace);
      emit(
        state.copyWith(
          status: PendingTransactionsStatus.failure,
          error: FailureException(),
        ),
      );
    }
  }

  FutureOr<void> _onPendingTransactionsRefreshRequested(
    PendingTransactionsRefreshRequested event,
    Emitter<PendingTransactionsState> emit,
  ) {
    emit(const PendingTransactionsState());
    add(PendingTransactionsRequested(event.address));
  }

  @override
  PendingTransactionsState? fromJson(Map<String, dynamic> json) =>
      PendingTransactionsState.fromJson(json);

  @override
  Map<String, dynamic>? toJson(PendingTransactionsState state) =>
      state.toJson();
}
