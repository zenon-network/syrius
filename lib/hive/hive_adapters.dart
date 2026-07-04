import 'package:hive_ce/hive_ce.dart';
import 'package:zenon_syrius_wallet_flutter/model/database/notification_type.dart';
import 'package:zenon_syrius_wallet_flutter/model/database/wallet_notification.dart';

@GenerateAdapters([
  AdapterSpec<WalletNotification>(),
  AdapterSpec<NotificationType>(),
])
part 'hive_adapters.g.dart';
