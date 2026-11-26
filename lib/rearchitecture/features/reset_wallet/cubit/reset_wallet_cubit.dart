import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/notifications/notifications.dart';
import 'package:zenon_syrius_wallet_flutter/utils/node_utils.dart';

part 'reset_wallet_state.dart';

/// Prepares wallet state before handing off full data deletion (cache, Drift
/// HTLC swap database, legacy swap boxes, and wallet file) to `SplashScreen`.
class ResetWalletCubit extends Cubit<ResetWalletState> {
  /// Creates a [ResetWalletCubit].
  ResetWalletCubit({
    Future<void> Function()? closeEmbeddedNode,
    void Function()? dismissLastNotification,
    this._closeTimeout = const Duration(seconds: 5),
  }) : _closeEmbeddedNode = closeEmbeddedNode ?? _defaultCloseEmbeddedNode,
       _dismissLastNotification =
           dismissLastNotification ?? _defaultDismissLastNotification,
       super(const ResetWalletInitial());

  final Future<void> Function() _closeEmbeddedNode;
  final void Function() _dismissLastNotification;
  final Duration _closeTimeout;

  static Future<void> _defaultCloseEmbeddedNode() async {
    await NodeUtils.closeEmbeddedNode();
  }

  static void _defaultDismissLastNotification() {
    if (sl.isRegistered<NotificationsBloc>()) {
      unawaited(sl<NotificationsBloc>().dismissNotification());
    }
  }

  /// Stops the embedded node, dismisses the active notification banner, and
  /// signals navigation to `SplashScreen(resetWalletFlow: true)`.
  Future<void> confirmReset() async {
    if (state is ResetWalletInProgress) {
      return;
    }
    emit(const ResetWalletInProgress());
    try {
      await _closeEmbeddedNode().timeout(_closeTimeout);
    } on Object catch (error, stackTrace) {
      addError(error, stackTrace);
    } finally {
      _dismissLastNotification();
      emit(const ResetWalletReadyToNavigate());
    }
  }
}
