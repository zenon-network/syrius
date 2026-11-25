import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/notifications/data/notifications_repository.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';

part 'notifications_list_event.dart';
part 'notifications_list_state.dart';

/// Manages loading, observing, deleting, and clearing stored notifications.
class NotificationsListBloc
    extends Bloc<NotificationsListEvent, NotificationsListState> {
  /// Creates a [NotificationsListBloc] backed by a [NotificationsRepository].
  NotificationsListBloc({required this._repository})
    : super(const NotificationsListInitial()) {
    on<NotificationsListEvent>(_onEvent, transformer: sequential());
  }

  final NotificationsRepository _repository;
  StreamSubscription<void>? _watchSubscription;
  Timer? _boxChangeCoalesceTimer;
  bool _isWatching = false;
  bool _isClosing = false;
  bool _hasPendingBoxChange = false;
  int _errorNonce = 0;

  Future<void> _onEvent(
    NotificationsListEvent event,
    Emitter<NotificationsListState> emit,
  ) {
    return switch (event) {
      NotificationsListStarted() => _onStarted(emit),
      NotificationsListRefreshRequested() => _onRefresh(emit),
      _NotificationsListBoxChanged() => _onBoxChanged(emit),
      NotificationDeleteRequested(:final dynamic key) => _onDelete(key, emit),
      NotificationsClearAllRequested() => _onClearAll(emit),
    };
  }

  Future<void> _onStarted(Emitter<NotificationsListState> emit) async {
    await _ensureWatching(restart: true);
    if (isClosed || _isClosing) {
      return;
    }
    await _onReload(emit, showLoading: true);
  }

  Future<void> _onRefresh(Emitter<NotificationsListState> emit) async {
    await _ensureWatching(restart: false);
    if (isClosed || _isClosing) {
      return;
    }
    await _onReload(emit, showLoading: true);
  }

  Future<void> _onBoxChanged(Emitter<NotificationsListState> emit) async {
    _hasPendingBoxChange = false;
    await _onReload(emit, showLoading: false);
  }

  Future<void> _ensureWatching({required bool restart}) async {
    if (!restart && _isWatching) {
      return;
    }
    final StreamSubscription<void>? previousSubscription = _watchSubscription;
    _watchSubscription = null;
    _isWatching = false;
    await previousSubscription?.cancel();
    if (isClosed || _isClosing) {
      return;
    }
    bool active = true;
    late final StreamSubscription<void> subscription;
    subscription = _repository.watchChanges().listen(
      (_) {
        if (isClosed || _isClosing || _boxChangeCoalesceTimer != null) {
          return;
        }
        _boxChangeCoalesceTimer = Timer(Duration.zero, () {
          _boxChangeCoalesceTimer = null;
          if (!isClosed && !_isClosing && !_hasPendingBoxChange) {
            _hasPendingBoxChange = true;
            add(const _NotificationsListBoxChanged());
          }
        });
      },
      onError: (Object error, StackTrace stackTrace) {
        active = false;
        if (identical(_watchSubscription, subscription)) {
          _watchSubscription = null;
          _isWatching = false;
        }
        addError(error, stackTrace);
      },
      onDone: () {
        active = false;
        if (identical(_watchSubscription, subscription)) {
          _watchSubscription = null;
          _isWatching = false;
        }
      },
      cancelOnError: true,
    );
    if (active && !isClosed && !_isClosing) {
      _watchSubscription = subscription;
      _isWatching = true;
    } else {
      await subscription.cancel();
    }
  }

  Future<void> _onReload(
    Emitter<NotificationsListState> emit, {
    required bool showLoading,
  }) async {
    if (showLoading) {
      emit(const NotificationsListLoading());
    }
    try {
      final List<StoredWalletNotification> notifications = await _repository
          .loadNotifications();
      emit(NotificationsListPopulated(notifications: notifications));
    } on SyriusException catch (e, stackTrace) {
      addError(e, stackTrace);
      emit(NotificationsListFailure(exception: e));
    } on Object catch (e, stackTrace) {
      addError(e, stackTrace);
      emit(NotificationsListFailure(exception: FailureException()));
    }
  }

  Future<void> _onDelete(
    dynamic key,
    Emitter<NotificationsListState> emit,
  ) async {
    final List<StoredWalletNotification> previous = _currentNotifications;
    try {
      await _repository.deleteNotification(key);
    } on Object catch (e, stackTrace) {
      addError(e, stackTrace);
      emit(
        NotificationsListPopulated(
          notifications: previous,
          actionError: NotificationsListActionError.delete,
          actionException: e is SyriusException ? e : null,
          errorNonce: ++_errorNonce,
        ),
      );
      return;
    }
    await _onReload(emit, showLoading: false);
  }

  Future<void> _onClearAll(Emitter<NotificationsListState> emit) async {
    final List<StoredWalletNotification> previous = _currentNotifications;
    try {
      await _repository.clearAllNotifications();
    } on Object catch (e, stackTrace) {
      addError(e, stackTrace);
      emit(
        NotificationsListPopulated(
          notifications: previous,
          actionError: NotificationsListActionError.clearAll,
          actionException: e is SyriusException ? e : null,
          errorNonce: ++_errorNonce,
        ),
      );
      return;
    }
    await _onReload(emit, showLoading: false);
  }

  List<StoredWalletNotification> get _currentNotifications {
    final NotificationsListState current = state;
    if (current is NotificationsListPopulated) {
      return current.notifications;
    }
    return const <StoredWalletNotification>[];
  }

  @override
  Future<void> close() async {
    _isClosing = true;
    _isWatching = false;
    _boxChangeCoalesceTimer?.cancel();
    _boxChangeCoalesceTimer = null;
    final StreamSubscription<void>? subscription = _watchSubscription;
    _watchSubscription = null;
    await subscription?.cancel();
    await super.close();
  }
}
