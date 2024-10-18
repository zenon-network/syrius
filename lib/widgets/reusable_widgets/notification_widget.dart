import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

class NotificationWidget extends StatefulWidget {

  const NotificationWidget({
    this.onSeeMorePressed,
    this.onDismissPressed,
    this.onNewNotificationCallback,
    this.popBeforeSeeMoreIsPressed = true,
    super.key,
  });
  final VoidCallback? onSeeMorePressed;
  final VoidCallback? onDismissPressed;
  final VoidCallback? onNewNotificationCallback;
  final bool popBeforeSeeMoreIsPressed;

  @override
  State<NotificationWidget> createState() => _NotificationWidgetState();
}

class _NotificationWidgetState extends State<NotificationWidget> {
  late NotificationsBloc _notificationsBloc;

  @override
  void initState() {
    super.initState();
    _initNotificationsBloc();
  }

  @override
  Widget build(BuildContext context) {
    return _shouldShowNotification()
        ? Padding(
            padding: const EdgeInsets.only(
              bottom: 15,
            ),
            child: WidgetAnimator(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Theme.of(context).colorScheme.primary,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 15,
                    horizontal: 50,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _getNotificationDetails(kLastNotification!),
                      _getNotificationOptions(kLastNotification!),
                    ],
                  ),
                ),
              ),
            ),
          )
        : Container();
  }

  bool _shouldShowNotification() =>
      kLastNotification != null &&
      kLastNotification?.timestamp != kLastDismissedNotification?.timestamp;

  void _initNotificationsBloc() {
    _notificationsBloc = sl.get<NotificationsBloc>();
    _notificationsBloc.stream.listen(
      (value) {
        if (mounted) {
          setState(() {
            kLastNotification = value;
          });
          widget.onNewNotificationCallback?.call();
        }
      },
    );
  }

  Row _getNotificationDetails(WalletNotification notification) {
    return Row(
      children: [
        notification.getIcon(),
        const SizedBox(
          width: 15,
        ),
        Text(
          notification.title!,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }

  Row _getNotificationOptions(WalletNotification notification) {
    return Row(
      children: [
        Visibility(
          visible: kCurrentPage != Tabs.lock && widget.onSeeMorePressed != null,
          child: RawMaterialButton(
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            constraints: const BoxConstraints.tightFor(),
            padding: const EdgeInsets.all(
              4,
            ),
            onPressed: _navigateToNotification,
            child: Text(
              'See more',
              style: Theme.of(context).textTheme.titleMedium!.copyWith(
                    color: notification.getColor(),
                  ),
            ),
          ),
        ),
        const SizedBox(
          width: 15,
        ),
        RawMaterialButton(
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          constraints: const BoxConstraints.tightFor(),
          padding: const EdgeInsets.all(
            4,
          ),
          onPressed: _dismissNotification,
          child: Text(
            'Dismiss',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }

  void _navigateToNotification() {
    if (kCurrentPage != Tabs.lock) {
      if (widget.popBeforeSeeMoreIsPressed) {
        Navigator.popUntil(
          context,
          ModalRoute.withName(MainAppContainer.route),
        );
      }
      _dismissNotification();
      widget.onSeeMorePressed?.call();
    }
  }

  void _dismissNotification() {
    setState(() {
      kLastDismissedNotification = kLastNotification;
    });
    widget.onDismissPressed?.call();
  }
}
