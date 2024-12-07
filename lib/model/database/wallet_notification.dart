import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:hive/hive.dart';
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';

part 'wallet_notification.g.dart';

@HiveType(typeId: kWalletNotificationHiveTypeId)
class WalletNotification extends HiveObject {

  WalletNotification({
    required this.title,
    required this.timestamp,
    required this.details,
    required this.type,
    this.id,
  });
  @HiveField(0)
  final String? title;

  @HiveField(1)
  final int? timestamp;

  @HiveField(2)
  final String? details;

  @HiveField(3)
  final NotificationType? type;

  @HiveField(4)
  final int? id;

  Color getColor() {
    switch (type) {
      case NotificationType.error:
        return AppColors.errorColor;
      case NotificationType.stakingDeactivated:
        return AppColors.alertNotification;
      default:
        return AppColors.znnColor;
    }
  }

  Widget getIcon() {
    switch (type) {
      case NotificationType.stakingDeactivated:
        return _getCircledIcon(MaterialCommunityIcons.alert_circle_outline,
            iconColor: Colors.grey,);
      case NotificationType.error:
        return const Icon(
          MaterialCommunityIcons.alert_circle_outline,
          size: 20,
          color: AppColors.errorColor,
        );
      case NotificationType.paymentSent:
        return _getCircledIcon(MaterialCommunityIcons.arrow_top_right);
      case NotificationType.paymentReceived:
        return _getCircledIcon(MaterialCommunityIcons.arrow_bottom_right);
      case NotificationType.rewardReceived:
        return _getCircledIcon(MaterialCommunityIcons.arrow_bottom_left);
      case NotificationType.autoLockIntervalChanged:
        return _getCircledIcon(Icons.lock_clock);
      case NotificationType.copiedToClipboard:
        return _getCircledIcon(Icons.content_copy);
      case NotificationType.autoEraseNumAttemptsChanged:
        return _getCircledIcon(Icons.delete);
      case NotificationType.generatingPlasma:
        return _getCircledIcon(Icons.access_time, iconColor: Colors.orange);
      case NotificationType.burnToken:
        return _getCircledIcon(Icons.whatshot);
      case NotificationType.addedTokenFavourite:
        return _getCircledIcon(Icons.star_rounded);
      case NotificationType.removedTokenFavourite:
        return _getCircledIcon(Icons.star_border_rounded);
      case NotificationType.changedNode:
        return _getCircledIcon(Icons.link);
      case NotificationType.delete:
        return _getCircledIcon(Icons.delete_forever);
      case NotificationType.confirm:
        return _getCircledIcon(Icons.remove_red_eye,
            iconColor: AppColors.alertNotification,);
      default:
        return _getCircledIcon(MaterialCommunityIcons.arrow_top_right);
    }
  }

  Widget _getCircledIcon(
    IconData iconData, {
    Color iconColor = AppColors.znnColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        border: Border.all(
          color: iconColor,
        ),
        borderRadius: BorderRadius.circular(
          50,
        ),
      ),
      child: Icon(
        iconData,
        color: iconColor,
        size: 10,
      ),
    );
  }
}
