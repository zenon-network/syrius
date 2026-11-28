import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/notifications/bloc/notifications_list_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/notifications/data/notifications_repository.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/exceptions/exceptions.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/extensions/buildcontext_extension.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/theming/syrius_theme_tokens.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/widgets/redesign/syrius_buttons.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/widgets/redesign/syrius_controls.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

/// Right slide-over Notification Drawer matching Screen 04.
class SyriusNotificationDrawer extends StatelessWidget {
  /// Creates a [SyriusNotificationDrawer].
  const SyriusNotificationDrawer({required this.onClose, super.key});

  /// Callback closing the drawer.
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<NotificationsListBloc>(
      create: (_) =>
          NotificationsListBloc(repository: const HiveNotificationsRepository())
            ..add(const NotificationsListStarted()),
      child: _DrawerBody(onClose: onClose),
    );
  }
}

class _DrawerBody extends StatelessWidget {
  const _DrawerBody({required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final SyriusThemeTokens tokens = context.syriusTheme;
    return Container(
      width: 368,
      decoration: BoxDecoration(
        color: tokens.surface,
        border: Border(left: BorderSide(color: tokens.border)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 30,
            offset: const Offset(-8, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 12, 14),
            child: Row(
              children: <Widget>[
                Text(
                  context.l10n.notifications,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: tokens.textPrimary,
                  ),
                ),
                const Spacer(),
                BlocBuilder<NotificationsListBloc, NotificationsListState>(
                  builder:
                      (BuildContext context, NotificationsListState state) {
                        final bool hasItems =
                            state is NotificationsListPopulated &&
                            state.notifications.isNotEmpty;
                        return SyriusGhostButton(
                          label: context.l10n.clear,
                          onPressed: hasItems
                              ? () => _confirmClearAll(context)
                              : null,
                        );
                      },
                ),
                IconButton(
                  iconSize: 17,
                  splashRadius: 16,
                  color: tokens.textMuted,
                  onPressed: onClose,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: tokens.border),
          Expanded(
            child: BlocBuilder<NotificationsListBloc, NotificationsListState>(
              builder: (BuildContext context, NotificationsListState state) {
                return switch (state) {
                  NotificationsListInitial() ||
                  NotificationsListLoading() => const SyriusLoadingWidget(),
                  NotificationsListFailure(:final SyriusException exception) =>
                    SyriusErrorWidget(exception),
                  NotificationsListPopulated(
                    :final List<StoredWalletNotification> notifications,
                  ) =>
                    _buildList(context, tokens, notifications),
                };
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(
    BuildContext context,
    SyriusThemeTokens tokens,
    List<StoredWalletNotification> items,
  ) {
    if (items.isEmpty) {
      return SyriusEmptyState(message: context.l10n.noNotifications);
    }

    final DateTime now = DateTime.now();
    final DateTime todayStart = DateTime(now.year, now.month, now.day);
    final DateTime yesterdayStart = todayStart.subtract(
      const Duration(days: 1),
    );

    final List<StoredWalletNotification> today = <StoredWalletNotification>[];
    final List<StoredWalletNotification> yesterday =
        <StoredWalletNotification>[];
    final List<StoredWalletNotification> earlier = <StoredWalletNotification>[];

    for (final StoredWalletNotification entry in items) {
      final int? ts = entry.notification.timestamp;
      if (ts == null) {
        earlier.add(entry);
        continue;
      }
      final DateTime dt = DateTime.fromMillisecondsSinceEpoch(ts);
      if (!dt.isBefore(todayStart)) {
        today.add(entry);
      } else if (!dt.isBefore(yesterdayStart)) {
        yesterday.add(entry);
      } else {
        earlier.add(entry);
      }
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      children: <Widget>[
        if (today.isNotEmpty) ...<Widget>[
          _SectionLabel(label: context.l10n.today),
          ...today.map(
            (StoredWalletNotification e) => _NotificationRow(entry: e),
          ),
          const SizedBox(height: 16),
        ],
        if (yesterday.isNotEmpty) ...<Widget>[
          _SectionLabel(label: context.l10n.yesterday),
          ...yesterday.map(
            (StoredWalletNotification e) => _NotificationRow(entry: e),
          ),
          const SizedBox(height: 16),
        ],
        if (earlier.isNotEmpty) ...<Widget>[
          const _SectionLabel(label: 'Earlier'),
          ...earlier.map(
            (StoredWalletNotification e) => _NotificationRow(entry: e),
          ),
        ],
      ],
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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label.toUpperCase(),
        style: context.syriusTheme.microLabelStyle(),
      ),
    );
  }
}

class _NotificationRow extends StatelessWidget {
  const _NotificationRow({required this.entry});

  final StoredWalletNotification entry;

  @override
  Widget build(BuildContext context) {
    final SyriusThemeTokens tokens = context.syriusTheme;
    final WalletNotification n = entry.notification;
    final bool isError = n.type == NotificationType.error;
    final Color iconColor = isError ? tokens.error : tokens.znnGreen;
    final IconData iconData = isError
        ? Icons.warning_amber_rounded
        : Icons.check_rounded;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(iconData, size: 16, color: iconColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  n.title ?? '',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: tokens.textPrimary,
                  ),
                ),
                if ((n.details ?? '').isNotEmpty) ...<Widget>[
                  const SizedBox(height: 2),
                  Text(
                    n.details!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, color: tokens.textSecondary),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            _relativeTime(n.timestamp),
            style: tokens.monoStyle(fontSize: 11, color: tokens.textMuted),
          ),
        ],
      ),
    );
  }

  String _relativeTime(int? timestampMs) {
    if (timestampMs == null) {
      return '';
    }
    final Duration diff = DateTime.now().difference(
      DateTime.fromMillisecondsSinceEpoch(timestampMs),
    );
    if (diff.inMinutes < 1) {
      return 'now';
    }
    if (diff.inHours < 1) {
      return '${diff.inMinutes} min';
    }
    if (diff.inDays < 1) {
      return '${diff.inHours} h';
    }
    return '${diff.inDays} d';
  }
}
