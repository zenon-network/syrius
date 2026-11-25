import 'package:hive_ce/hive_ce.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';

/// Persistence and wallet address operations for the Settings Addresses card.
abstract interface class SettingsAddressesRepository {
  /// Returns the currently loaded wallet addresses.
  List<String> getAddresses();

  /// Returns the currently selected default wallet address, if any.
  String? getSelectedAddress();

  /// Returns a snapshot of address-to-label mappings.
  Map<String, String> getAddressLabels();

  /// Saves [address] as the default wallet address.
  Future<void> saveDefaultAddress(String address);

  /// Generates [count] new addresses from the current wallet.
  Future<void> generateNewAddresses(int count);

  /// Persists [label] for [address].
  Future<void> updateAddressLabel({
    required String address,
    required String label,
  });
}

/// Hive-backed implementation of [SettingsAddressesRepository].
final class HiveSettingsAddressesRepository
    implements SettingsAddressesRepository {
  /// Creates a [HiveSettingsAddressesRepository].
  HiveSettingsAddressesRepository({
    this._sharedPrefsBox,
    this._addressLabelsBox,
    this._generateAddresses,
  });

  final Box<dynamic>? _sharedPrefsBox;
  final Box<dynamic>? _addressLabelsBox;
  final Future<void> Function(int count)? _generateAddresses;

  @override
  List<String> getAddresses() =>
      kDefaultAddressList.whereType<String>().toList(growable: false);

  @override
  String? getSelectedAddress() => kSelectedAddress;

  @override
  Map<String, String> getAddressLabels() =>
      Map<String, String>.of(kAddressLabelMap);

  @override
  Future<void> saveDefaultAddress(String address) async {
    final Box<dynamic> box =
        _sharedPrefsBox ?? Hive.box<dynamic>(kSharedPrefsBox);
    await box.put(kDefaultAddressKey, address);
  }

  @override
  Future<void> generateNewAddresses(int count) async {
    if (_generateAddresses != null) {
      await _generateAddresses(count);
      return;
    }
    await ZenonAddressUtils.generateNewAddress(numAddr: count);
  }

  @override
  Future<void> updateAddressLabel({
    required String address,
    required String label,
  }) async {
    final Box<dynamic> box =
        _addressLabelsBox ?? Hive.box<dynamic>(kAddressLabelsBox);
    await box.put(address, label);
    kAddressLabelMap[address] = label;
  }
}
