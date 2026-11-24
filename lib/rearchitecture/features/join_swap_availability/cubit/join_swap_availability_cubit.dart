import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/initial_htlc_validation/initial_htlc_validation.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'join_swap_availability_state.dart';

/// Tracks whether an initial HTLC still has enough time to be joined safely.
class JoinSwapAvailabilityCubit extends Cubit<JoinSwapAvailabilityState> {
  /// Creates a [JoinSwapAvailabilityCubit].
  JoinSwapAvailabilityCubit({
    required HtlcInfo initialHtlc,
    this._refreshInterval = const Duration(seconds: 5),
    DateTime Function()? dateTime,
  }) : _initialHtlc = initialHtlc,
       _dateTime = dateTime ?? _currentDateTime,
       super(
         _stateAt(
           initialHtlc,
           (dateTime ?? _currentDateTime)(),
         ),
       ) {
    if (state is JoinSwapAvailable) {
      _startRefreshing();
    }
  }

  final HtlcInfo _initialHtlc;
  final DateTime Function() _dateTime;
  final Duration _refreshInterval;

  Timer? _autoRefresher;

  static DateTime _currentDateTime() => DateTime.now();

  static JoinSwapAvailabilityState _stateAt(
    HtlcInfo initialHtlc,
    DateTime dateTime,
  ) {
    final int unixTimestamp = dateTime.unixTimestamp;
    if (!initialHtlc.canBeSafelyJoinedAt(unixTimestamp)) {
      return const JoinSwapUnavailable();
    }

    return JoinSwapAvailable(
      minutesLeftToJoin: initialHtlc.minutesLeftToJoinAt(unixTimestamp),
    );
  }

  /// Recalculates whether the initial HTLC can still be joined safely.
  void checkAvailability() {
    if (isClosed) {
      return;
    }

    final JoinSwapAvailabilityState nextState = _stateAt(
      _initialHtlc,
      _dateTime(),
    );
    if (nextState is JoinSwapUnavailable) {
      _autoRefresher?.cancel();
    }
    emit(nextState);
  }

  void _startRefreshing() {
    _autoRefresher = Timer.periodic(_refreshInterval, (_) {
      if (!isClosed) {
        checkAvailability();
      }
    });
  }

  @override
  Future<void> close() {
    _autoRefresher?.cancel();
    return super.close();
  }
}
