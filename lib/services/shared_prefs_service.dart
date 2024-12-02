import 'package:hive/hive.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';

class SharedPrefsService {
  static Box? _sharedPrefsBox;

  static SharedPrefsService? _instance;

  static Future<SharedPrefsService?> getInstance() async {
    _instance ??= SharedPrefsService();
    if (_sharedPrefsBox == null || !_sharedPrefsBox!.isOpen) {
      _sharedPrefsBox = await Hive.openBox(kSharedPrefsBox);
    }
    return _instance;
  }

  dynamic get(String key, {dynamic defaultValue}) {
    try {
      return _sharedPrefsBox!.get(
        key,
        defaultValue: defaultValue,
      );
    } on HiveError {
      return defaultValue;
    }
  }

  Future<void> close() async => _sharedPrefsBox!.close();

  Future<void> put(String key, dynamic value) async =>
      _sharedPrefsBox!.put(
        key,
        value,
      );

  Future<void> checkIfBoxIsOpen() async {
    if (_sharedPrefsBox == null || !_sharedPrefsBox!.isOpen) {
      _sharedPrefsBox = await Hive.openBox(kSharedPrefsBox);
    }
  }
}
