import 'package:hive_ce/hive_ce.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';

/// Hive-backed service for persisting wallet preferences.
class SharedPrefsService {
  static Box<dynamic>? _sharedPrefsBox;

  static SharedPrefsService? _instance;

  /// Returns the singleton [SharedPrefsService] instance, opening the box if
  /// needed.
  static Future<SharedPrefsService?> getInstance() async {
    _instance ??= SharedPrefsService();
    if (_sharedPrefsBox == null || !_sharedPrefsBox!.isOpen) {
      _sharedPrefsBox = await Hive.openBox<dynamic>(kSharedPrefsBox);
    }
    return _instance;
  }

  /// Reads the value for [key], returning [defaultValue] if missing or if Hive
  /// raises a [HiveError].
  dynamic get(String key, {dynamic defaultValue}) {
    try {
      return _sharedPrefsBox!.get(
        key,
        defaultValue: defaultValue,
      );
      // Hive throws HiveError (an Error subclass) for storage/box failures.
      // ignore: avoid_catching_errors
    } on HiveError {
      return defaultValue;
    }
  }

  /// Closes the underlying shared preferences Hive box.
  Future<void> close() => _sharedPrefsBox!.close();

  /// Stores [value] under [key] in the shared preferences Hive box.
  Future<void> put(String key, dynamic value) => _sharedPrefsBox!.put(
        key,
        value,
      );

  /// Reopens the shared preferences Hive box if it is not currently open.
  Future<void> checkIfBoxIsOpen() async {
    if (_sharedPrefsBox == null || !_sharedPrefsBox!.isOpen) {
      _sharedPrefsBox = await Hive.openBox<dynamic>(kSharedPrefsBox);
    }
  }
}
