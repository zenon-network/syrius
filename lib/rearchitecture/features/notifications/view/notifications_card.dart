import 'dart:async';

import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/notifications/bloc/notifications_list_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/notifications/data/notifications_repository.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

/// Displays persisted wallet notifications with single-item and clear-all
/// deletion controls.
class NotificationsCard extends StatelessWidget {
  /// Creates a [NotificationsCard].
  const NotificationsCard({@visibleForTesting this._bloc, super.key});

  final NotificationsListBloc? _bloc;

  @override
  Widget build(BuildContext context) {
    final NotificationsListBloc? injectedBloc = _bloc;
    if (injectedBloc != null) {
      return BlocProvider<NotificationsListBloc>.value(
        value: injectedBloc,
        child: const _View(),
      );
    }

    return BlocProvider<NotificationsListBloc>(
      create: (_) =>
          NotificationsListBloc(repository: const HiveNotificationsRepository())
            ..add(const NotificationsListStarted()),
      child: const _View(),
    );
  }
}

class _View extends StatelessWidget {
  const _View();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<NotificationsListBloc, NotificationsListState>(
      listenWhen:
          (NotificationsListState previous, NotificationsListState current) {
            if (current is! NotificationsListPopulated ||
                current.actionError == null) {
              return false;
            }
            return previous is! NotificationsListPopulated ||
                previous.errorNonce != current.errorNonce;
          },
      listener: (BuildContext context, NotificationsListState state) {
        if (state is! NotificationsListPopulated || state.actionError == null) {
          return;
        }
        final String title = switch (state.actionError!) {
          NotificationsListActionError.delete =>
            context.l10n.errorDeletingNotification,
          NotificationsListActionError.clearAll =>
            context.l10n.errorClearingNotifications,
        };
        unawaited(
          NotificationUtils.showForegroundError(
            context,
            state.actionException ?? FailureException(message: title),
            title,
          ),
        );
      },
      builder: (BuildContext context, NotificationsListState state) {
        final bool hasNotifications =
            state is NotificationsListPopulated &&
            state.notifications.isNotEmpty;

        return NewCardScaffold(
          data: CardData(
            title: context.l10n.notifications,
            description: context.l10n.displaysWalletNotificationsDetails,
          ),
          actions: <Widget>[
            _buildClearAllButton(context, enabled: hasNotifications),
          ],
          onRefreshPressed: () {
            context.read<NotificationsListBloc>().add(
              const NotificationsListRefreshRequested(),
            );
          },
          body: switch (state) {
            NotificationsListInitial() ||
            NotificationsListLoading() => const SyriusLoadingWidget(),
            NotificationsListFailure(:final SyriusException exception) =>
              SyriusErrorWidget(exception),
            NotificationsListPopulated(
              :final List<StoredWalletNotification> notifications,
            ) =>
              _Populated(notifications: notifications),
          },
        );
      },
    );
  }

  Widget _buildClearAllButton(BuildContext context, {required bool enabled}) {
    return IconButton(
      tooltip: context.l10n.clearAllNotifications,
      icon: const Icon(Icons.delete_sweep_outlined),
      color: enabled ? AppColors.errorColor : null,
      onPressed: enabled ? () => _confirmClearAll(context) : null,
    );
  }

  Future<void> _confirmClearAll(BuildContext context) async {
    final NotificationsListBloc bloc = context.read<NotificationsListBloc>();
    final bool? confirmed = await showDialogWithNoAndYesOptions(
      context: context,
      isBarrierDismissible: true,
      title: context.l10n.clearAllNotifications,
      description: context.l10n.deleteAllNotificationsCannotBeUndone,
    );
    if ((confirmed ?? false) && !bloc.isClosed) {
      bloc.add(const NotificationsClearAllRequested());
    }
  }
}

class _Populated extends StatelessWidget {
  const _Populated({required this._notifications});

  final List<StoredWalletNotification> _notifications;

  @override
  Widget build(BuildContext context) {
    if (_notifications.isEmpty) {
      return SyriusErrorWidget(context.l10n.noNotifications);
    }

    return InfiniteScrollTable<StoredWalletNotification>(
      items: _notifications,
      hasReachedMax: true,
      itemKeyGenerator: (StoredWalletNotification entry) =>
          ValueKey<Object?>(entry.key),
      columns: const <InfiniteScrollTableColumnType>[
        .description,
        .date,
        .time,
        .blank,
      ],
      generateRowCells: (StoredWalletNotification entry) =>
          _buildRowCells(context, entry),
      onScrollReachedBottom: () {},
    );
  }

  List<Widget> _buildRowCells(
    BuildContext context,
    StoredWalletNotification entry,
  ) {
    final WalletNotification notification = entry.notification;
    final int? timestamp = notification.timestamp;

    return <Widget>[
      InfiniteScrollTableCell(
        flex: 5,
        child: _buildNotificationPanel(context, notification),
      ),
      InfiniteScrollTableCell.withText(
        content: timestamp != null ? FormatUtils.formatDate(timestamp) : '-',
      ),
      InfiniteScrollTableCell.withText(
        content: timestamp != null
            ? FormatUtils.formatDate(
                timestamp,
                dateFormat: kNotificationsTimeFormat,
              )
            : '-',
      ),
      InfiniteScrollTableCell(
        child: Align(child: _buildDeleteButton(context, entry)),
      ),
    ];
  }

  Widget _buildNotificationPanel(
    BuildContext context,
    WalletNotification notification,
  ) {
    final String title = notification.title ?? '';
    final String details = notification.details ?? '';

    return ExpandablePanel(
      collapsed: const SizedBox.shrink(),
      theme: ExpandableThemeData(
        iconColor: Theme.of(context).textTheme.titleMedium?.color,
        headerAlignment: ExpandablePanelHeaderAlignment.center,
        iconPlacement: ExpandablePanelIconPlacement.right,
      ),
      header: Row(
        children: <Widget>[
          notification.getIcon(),
          kHorizontalGap8,
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.titleMedium),
          ),
        ],
      ),
      expanded: Padding(
        padding: const EdgeInsets.only(left: 14, top: 5, bottom: 5),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                details,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            if (details.isNotEmpty) CopyToClipboardButton(details),
          ],
        ),
      ),
    );
  }

  Widget _buildDeleteButton(
    BuildContext context,
    StoredWalletNotification entry,
  ) {
    return IconButton(
      tooltip: context.l10n.deleteNotification,
      style: IconButton.styleFrom(
        foregroundColor: AppColors.errorColor,
        padding: EdgeInsets.zero,
      ),
      icon: const Icon(Icons.delete_outline),
      onPressed: () {
        context.read<NotificationsListBloc>().add(
          NotificationDeleteRequested(key: entry.key),
        );
      },
    );
  }
}
