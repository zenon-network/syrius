import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/notifications/bloc/notifications_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/extensions/buildcontext_extension.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/theming/syrius_theme_tokens.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

/// Displays the currently active wallet notification banner with optional
/// navigation and dismissal controls.
class NotificationWidget extends StatelessWidget {
  /// Creates a [NotificationWidget].
  const NotificationWidget({
    this.onSeeMorePressed,
    this.onDismissPressed,
    this.onNewNotificationCallback,
    this.popBeforeSeeMoreIsPressed = true,
    @visibleForTesting this._bloc,
    super.key,
  });

  /// Invoked when the user presses "See more".
  final VoidCallback? onSeeMorePressed;

  /// Invoked when the user dismisses the active notification banner.
  final VoidCallback? onDismissPressed;

  /// Invoked whenever a new notification is published to the banner.
  final VoidCallback? onNewNotificationCallback;

  /// Whether to pop back to [MainAppContainer.route] before invoking
  /// [onSeeMorePressed].
  final bool popBeforeSeeMoreIsPressed;

  final NotificationsBloc? _bloc;

  @override
  Widget build(BuildContext context) {
    final NotificationsBloc? injectedBloc = _bloc;
    if (injectedBloc != null) {
      return BlocProvider<NotificationsBloc>.value(
        value: injectedBloc,
        child: _View(
          onSeeMorePressed: onSeeMorePressed,
          onDismissPressed: onDismissPressed,
          onNewNotificationCallback: onNewNotificationCallback,
          popBeforeSeeMoreIsPressed: popBeforeSeeMoreIsPressed,
        ),
      );
    }

    final NotificationsBloc? providedBloc = _findProvidedBloc(context);
    if (providedBloc != null) {
      return _View(
        onSeeMorePressed: onSeeMorePressed,
        onDismissPressed: onDismissPressed,
        onNewNotificationCallback: onNewNotificationCallback,
        popBeforeSeeMoreIsPressed: popBeforeSeeMoreIsPressed,
      );
    }

    if (!sl.isRegistered<NotificationsBloc>()) {
      return const SizedBox.shrink();
    }

    return BlocProvider<NotificationsBloc>.value(
      value: sl<NotificationsBloc>(),
      child: _View(
        onSeeMorePressed: onSeeMorePressed,
        onDismissPressed: onDismissPressed,
        onNewNotificationCallback: onNewNotificationCallback,
        popBeforeSeeMoreIsPressed: popBeforeSeeMoreIsPressed,
      ),
    );
  }

  NotificationsBloc? _findProvidedBloc(BuildContext context) {
    try {
      return BlocProvider.of<NotificationsBloc>(context);
    } on Object {
      return null;
    }
  }
}

class _View extends StatelessWidget {
  const _View({
    required this._onSeeMorePressed,
    required this._onDismissPressed,
    required this._onNewNotificationCallback,
    required this._popBeforeSeeMoreIsPressed,
  });

  final VoidCallback? _onSeeMorePressed;
  final VoidCallback? _onDismissPressed;
  final VoidCallback? _onNewNotificationCallback;
  final bool _popBeforeSeeMoreIsPressed;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<NotificationsBloc, NotificationsState>(
      listenWhen: (NotificationsState previous, NotificationsState current) =>
          (current.revision > previous.revision &&
              current.hasActiveNotification) ||
          (previous.hasActiveNotification && !current.hasActiveNotification),
      listener: (BuildContext context, NotificationsState state) {
        if (state.hasActiveNotification) {
          _onNewNotificationCallback?.call();
        } else {
          _onDismissPressed?.call();
        }
      },
      builder: (BuildContext context, NotificationsState state) {
        final WalletNotification? notification = state.activeNotification;
        if (notification == null) {
          return const SizedBox.shrink();
        }

        final SyriusThemeTokens tokens = context.syriusTheme;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: WidgetAnimator(
            child: Container(
              decoration: BoxDecoration(
                color: tokens.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: tokens.borderStrong),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.22),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(
                vertical: 11,
                horizontal: 16,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Expanded(
                    child: _buildNotificationDetails(context, notification),
                  ),
                  const SizedBox(width: 14),
                  _buildNotificationOptions(
                    context,
                    notification,
                    state.revision,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNotificationDetails(
    BuildContext context,
    WalletNotification notification,
  ) {
    return Row(
      children: <Widget>[
        notification.getIcon(),
        const SizedBox(width: 15),
        Flexible(
          child: Text(
            notification.title ?? '',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationOptions(
    BuildContext context,
    WalletNotification notification,
    int revision,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Visibility(
          visible: kCurrentPage != Tabs.lock && _onSeeMorePressed != null,
          child: RawMaterialButton(
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            constraints: const BoxConstraints.tightFor(),
            padding: const EdgeInsets.all(4),
            onPressed: () => _navigateToNotification(context, revision),
            child: Text(
              context.l10n.seeMore,
              style: Theme.of(
                context,
              ).textTheme.titleMedium!.copyWith(color: notification.getColor()),
            ),
          ),
        ),
        const SizedBox(width: 15),
        RawMaterialButton(
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          constraints: const BoxConstraints.tightFor(),
          padding: const EdgeInsets.all(4),
          onPressed: () => _dismissNotification(context, revision),
          child: Text(
            context.l10n.dismiss,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }

  void _navigateToNotification(BuildContext context, int revision) {
    if (kCurrentPage != Tabs.lock) {
      if (_popBeforeSeeMoreIsPressed) {
        Navigator.popUntil(
          context,
          ModalRoute.withName(MainAppContainer.route),
        );
      }
      _dismissNotification(context, revision);
      _onSeeMorePressed?.call();
    }
  }

  void _dismissNotification(BuildContext context, int revision) {
    context.read<NotificationsBloc>().add(
      NotificationDismissed(revision: revision),
    );
  }
}
