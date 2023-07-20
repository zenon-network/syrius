import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/utils/format_utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/icons/clear_icon.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

class NotificationsTabChild extends StatefulWidget {
  const NotificationsTabChild({Key? key}) : super(key: key);

  @override
  State<NotificationsTabChild> createState() => _NotificationsTabChildState();
}

class _NotificationsTabChildState extends State<NotificationsTabChild> {
  List<WalletNotification>? _notifications;

  @override
  Widget build(BuildContext context) {
    _loadNotifications();

    return WidgetAnimator(
      curve: Curves.linear,
      child: _getNotificationsContainer(),
    );
  }

  CardScaffold _getNotificationsContainer() {
    return CardScaffold(
      title: 'Notifications',
      description: 'This card displays detailed information regarding the '
          'wallet notifications',
      childBuilder: () => CustomTable<WalletNotification>(
          items: _notifications,
          headerColumns: const [
            CustomHeaderColumn(columnName: 'Description', flex: 5),
            CustomHeaderColumn(columnName: 'Date', flex: 2),
            CustomHeaderColumn(columnName: 'Time', flex: 2),
            CustomHeaderColumn(
              columnName: '',
            ),
          ],
          generateRowCells: _rowCellsGenerator),
    );
  }

  ExpandablePanel _getNotificationExpandablePanel(
      WalletNotification notification) {
    return ExpandablePanel(
      collapsed: Container(),
      theme: ExpandableThemeData(
        iconColor: Theme.of(context).textTheme.titleMedium!.color,
        headerAlignment: ExpandablePanelHeaderAlignment.center,
        iconPlacement: ExpandablePanelIconPlacement.right,
      ),
      header: Row(
        children: [
          notification.getIcon(),
          const SizedBox(
            width: 10.0,
          ),
          Expanded(
            child: Text(
              notification.title!,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ],
      ),
      expanded: Padding(
        padding: const EdgeInsets.only(left: 14.0, top: 5.0, bottom: 5.0),
        child: Row(
          children: [
            Expanded(
              child: Text(
                notification.details!,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            CopyToClipboardIcon(notification.details),
          ],
        ),
      ),
    );
  }

  RawMaterialButton _getClearIcon(WalletNotification? notification) {
    return ClearIcon(
      onPressed: () => _deleteNotification(notification!.timestamp),
      context: context,
    );
  }

  List<WalletNotification> _getNotificationsFromDb() {
    try {
      Box notificationsBox = Hive.box(kNotificationsBox);
      List<dynamic> keys = notificationsBox.keys.toList();
      if (keys.length >= kNotificationsResultLimit) {
        return List<WalletNotification>.from(
          notificationsBox.valuesBetween(
            startKey: keys[keys.length - kNotificationsResultLimit],
            endKey: keys[keys.length - 1],
          ),
        );
      }
      return notificationsBox.keys
          .map<WalletNotification>(
            (e) => notificationsBox.get(e),
          )
          .toList();
    } catch (e) {
      return [];
    }
  }

  Future<void> _deleteNotification(int? notificationTimestamp) async {
    Box notificationsBox = Hive.box(kNotificationsBox);

    var notificationKey = notificationsBox.keys.firstWhere(
      (key) => notificationsBox.get(key).timestamp == notificationTimestamp,
    );

    await notificationsBox.delete(notificationKey);

    setState(() {});
  }

  void _loadNotifications() {
    _notifications = _getNotificationsFromDb();
    _notifications!.sort((a, b) => b.timestamp!.compareTo(a.timestamp!));
  }

  List<Widget> _rowCellsGenerator<WalletNotification>(
    notification,
    isSelected, {
    SentinelsListBloc? model,
  }) {
    return [
      CustomTableCell(
        _getNotificationExpandablePanel(notification),
        flex: 5,
      ),
      CustomTableCell.withText(
        context,
        FormatUtils.formatDate(notification.timestamp),
        flex: 2,
      ),
      CustomTableCell.withText(
        context,
        FormatUtils.formatDate(notification.timestamp,
            dateFormat: kNotificationsTimeFormat),
        flex: 2,
      ),
      CustomTableCell(_getClearIcon(notification)),
    ];
  }
}
