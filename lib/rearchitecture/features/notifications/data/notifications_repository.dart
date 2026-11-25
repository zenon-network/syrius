import 'package:equatable/equatable.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';

/// A [WalletNotification] paired with its stable Hive storage [key].
class StoredWalletNotification extends Equatable {
  /// Creates a [StoredWalletNotification].
  const StoredWalletNotification({
    required this.key,
    required this.notification,
  });

  /// Hive box key identifying this stored notification record.
  final dynamic key;

  /// Persisted notification payload.
  final WalletNotification notification;

  @override
  List<Object?> get props => <Object?>[
    key,
    notification.id,
    notification.title,
    notification.details,
    notification.timestamp,
    notification.type,
  ];
}

/// Repository interface for reading, observing, storing, and deleting stored
/// wallet notifications.
abstract class NotificationsRepository {
  /// Loads up to [limit] stored notifications ordered newest-first.
  Future<List<StoredWalletNotification>> loadNotifications({
    int limit = kNotificationsResultLimit,
  });

  /// Persists [notification] in history, evicting the oldest entries when the
  /// store reaches [maxEntries]. When [maxEntries] is `<= 0`, clears stored
  /// entries without adding [notification].
  Future<void> addNotification(
    WalletNotification notification, {
    int maxEntries = kNotificationsEntriesLimit,
  });

  /// Emits whenever the underlying notifications store changes.
  Stream<void> watchChanges();

  /// Deletes the single notification identified by [key].
  Future<void> deleteNotification(dynamic key);

  /// Deletes all stored notifications from history.
  Future<void> clearAllNotifications();
}

/// Hive-backed [NotificationsRepository] using [kNotificationsBox].
class HiveNotificationsRepository implements NotificationsRepository {
  /// Creates a [HiveNotificationsRepository].
  const HiveNotificationsRepository({this._boxName = kNotificationsBox});

  final String _boxName;

  Future<Box<dynamic>> _openBox() {
    if (Hive.isBoxOpen(_boxName)) {
      return Future<Box<dynamic>>.value(Hive.box<dynamic>(_boxName));
    }
    return Hive.openBox<dynamic>(_boxName);
  }

  @override
  Future<List<StoredWalletNotification>> loadNotifications({
    int limit = kNotificationsResultLimit,
  }) async {
    final Box<dynamic> box = await _openBox();
    final List<({int index, StoredWalletNotification entry})> indexed =
        <({int index, StoredWalletNotification entry})>[];
    int insertionIndex = 0;

    for (final dynamic key in box.keys) {
      final dynamic value = box.get(key);
      if (value is WalletNotification) {
        indexed.add((
          index: insertionIndex,
          entry: StoredWalletNotification(key: key, notification: value),
        ));
      }
      insertionIndex++;
    }

    indexed.sort((
      ({int index, StoredWalletNotification entry}) a,
      ({int index, StoredWalletNotification entry}) b,
    ) {
      final int timestampA = a.entry.notification.timestamp ?? 0;
      final int timestampB = b.entry.notification.timestamp ?? 0;
      final int byTime = timestampB.compareTo(timestampA);
      if (byTime != 0) {
        return byTime;
      }
      return b.index.compareTo(a.index);
    });

    final Iterable<StoredWalletNotification> sorted = indexed.map(
      (({int index, StoredWalletNotification entry}) item) => item.entry,
    );
    if (limit <= 0) {
      return const <StoredWalletNotification>[];
    }
    return sorted.take(limit).toList();
  }

  @override
  Future<void> addNotification(
    WalletNotification notification, {
    int maxEntries = kNotificationsEntriesLimit,
  }) async {
    final Box<dynamic> box = await _openBox();
    if (maxEntries <= 0) {
      await box.clear();
      return;
    }
    while (box.length >= maxEntries) {
      await box.delete(box.keys.first);
    }
    await box.add(notification);
  }

  @override
  Stream<void> watchChanges() async* {
    final Box<dynamic> box = await _openBox();
    yield* box.watch().map((BoxEvent _) {});
  }

  @override
  Future<void> deleteNotification(dynamic key) async {
    final Box<dynamic> box = await _openBox();
    await box.delete(key);
  }

  @override
  Future<void> clearAllNotifications() async {
    final Box<dynamic> box = await _openBox();
    await box.clear();
  }
}
