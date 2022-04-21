import 'package:hive/hive.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';

part 'notification_type.g.dart';

@HiveType(typeId: kNotificationTypeEnumHiveTypeId)
enum NotificationType {
  @HiveField(0)
  paymentSent,

  @HiveField(1)
  error,

  @HiveField(2)
  stakingDeactivated,

  @HiveField(3)
  paymentReceived,

  @HiveField(4)
  autoLockIntervalChanged,

  @HiveField(5)
  copiedToClipboard,

  @HiveField(6)
  rewardReceived,

  @HiveField(7)
  autoEraseNumAttemptsChanged,

  @HiveField(8)
  generatingPlasma,

  @HiveField(9)
  burnToken,

  @HiveField(10)
  addedTokenFavourite,

  @HiveField(11)
  removedTokenFavourite,

  @HiveField(12)
  resetWallet,

  @HiveField(13)
  changedNode,

  @HiveField(14)
  delete,
}
