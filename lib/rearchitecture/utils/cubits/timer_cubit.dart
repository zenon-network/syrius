import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:logging/logging.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/balance/balance.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'timer_state.dart';

/// An abstract class that manages periodic data fetching for a
///
/// The cubit emits different states based on data loading,
/// success, or failure, and it periodically refreshes the data automatically.
///
/// The generic type [T] represents the type of data managed by this cubit.
///
/// The generic type [S] represents the type of the states emitted by the cubit.
/// [S] extends [TimerState]
abstract class TimerCubit<T, S extends TimerState<T>> extends HydratedCubit<S> {
  /// Constructs a [TimerCubit] with the provided [zenon] client and initial
  /// state.
  ///
  /// The auto-refresh functionality is initialized upon the cubit's creation.
  TimerCubit({
    required this.zenon,
    required S initialState,
    this.refreshInterval = kTimerCubitRefreshInterval,
  }) : super(initialState);

  /// A timer that handles the auto-refreshing of data.
  Timer? _autoRefresher;

  /// The Zenon client used to fetch data from the Zenon ledger.
  final Zenon zenon;

  /// The interval at which to fetch the data again.
  final Duration refreshInterval;

  /// Fetches data of type [T] that is managed by the cubit.
  ///
  /// This method needs to be implemented by subclasses, and it should define
  /// the specific data-fetching logic (e.g., fetching account information).
  ///
  /// It shouldn't be used to emit states
  Future<T> fetch();

  /// Returns a [Timer] that triggers the auto-refresh functionality after
  /// the predefined [kTimerCubitRefreshInterval].
  ///
  /// This method cancels any existing timers and initiates a new periodic
  /// fetch cycle by calling [fetchDataPeriodically].
  Timer _getAutoRefreshTimer() => Timer(
        refreshInterval,
        () {
          _autoRefresher!.cancel();
          fetchDataPeriodically();
        },
      );

  /// Periodically fetches data and updates the state with either success or
  /// failure.
  ///
  /// This method fetches new data by calling [fetch], emits a loading state
  /// while fetching, and updates the state with success or failure based on
  /// the outcome.
  /// If the WebSocket client is closed, it throws a [noConnectionException].
  Future<void> fetchDataPeriodically() async {
    try {
      if (state.status != TimerStatus.success) {
        emit(state.copyWith(status: TimerStatus.loading) as S);
      }
      if (!zenon.wsClient.isClosed()) {
        final T data = await fetch();
        emit(state.copyWith(data: data, status: TimerStatus.success) as S);
      } else {
        throw noConnectionException;
      }
    } on SyriusException catch (e) {
      emit(state.copyWith(status: TimerStatus.failure, error: e) as S);
    } catch (e, stackTrace) {
      emit(
        state.copyWith(
          status: TimerStatus.failure,
          error: FailureException(),
        ) as S,
      );
      // Reports only the unexpected errors
      addError(e, stackTrace);
    } finally {
      /// Ensure that the auto-refresher is restarted if it's not active.
      if (!isTimerActive) {
        _startAutoRefresh();
      }
    }
  }

  /// Starts the auto-refresh cycle by initializing the [_autoRefresher] timer.
  void _startAutoRefresh() {
    _autoRefresher = _getAutoRefreshTimer();
  }

  /// Checks if a timer was set and if it's active
  bool get isTimerActive => _autoRefresher?.isActive ?? false;

  /// Cancels the auto-refresh timer and closes the cubit.
  ///
  /// This method is called when the cubit is closed, ensuring that no
  /// background tasks remain active after the cubit is disposed.
  @override
  Future<void> close() {
    _autoRefresher?.cancel();
    return super.close();
  }

  @override
  void onError(Object error, StackTrace stackTrace) {
    Level logLevel = Level.WARNING;
    if (error is SyriusException) {
      logLevel = Level.INFO;
    }
    // state.runtimeType has the roll to identify in which cubit subclass
    // the error happened
    Logger('TimerCubit - ${state.runtimeType}').log(
      logLevel,
      'onError triggered',
      error,
      stackTrace,
    );
    super.onError(error, stackTrace);
  }
}
