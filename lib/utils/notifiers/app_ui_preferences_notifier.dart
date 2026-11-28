import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';

/// Shared preferences key for hiding balances globally (discreet mode).
const String kHideBalancesKey = 'ui_hide_balances';

/// Shared preferences key for expanded/labeled navigation rail mode.
const String kSidebarExpandedKey = 'ui_sidebar_expanded';

/// Shared preferences key for showing estimated fiat values.
const String kShowFiatValuesKey = 'ui_show_fiat_values';

/// Shared preferences key for the selected block explorer base URL.
const String kSelectedExplorerKey = 'ui_selected_explorer';

/// Shared preferences key for enabling local Web apps bridge setting.
const String kWebAppsBridgeKey = 'ui_web_apps_bridge';

/// Shared preferences key for Pillar display mode (`auto`, `on`, `off`).
const String kPillarModeKey = 'ui_pillar_mode';

/// Shared preferences key for Sentinel display mode (`auto`, `on`, `off`).
const String kSentinelModeKey = 'ui_sentinel_mode';

/// Shared preferences key for Sporks display mode (`auto`, `on`, `off`).
const String kSporksModeKey = 'ui_sporks_mode';

/// Shared preferences key for saved named contacts (`Map<String, String>`).
const String kContactsMapKey = 'ui_contacts_map';

/// Display mode preference for optional wallet power features.
enum FeatureDisplayMode {
  /// Automatically show when the selected address owns one.
  auto,

  /// Always show.
  on,

  /// Always hide.
  off,
}

/// Manages UI-wide presentation preferences introduced in the Syrius reskin:
/// balance privacy masking, navigation rail expansion, explorer choice,
/// feature display modes, and named address book contacts.
class AppUiPreferencesNotifier extends ChangeNotifier {
  /// Creates an [AppUiPreferencesNotifier] initialized from persisted prefs.
  AppUiPreferencesNotifier() {
    loadFromPrefs();
  }

  bool _hideBalances = false;
  bool _sidebarExpanded = false;
  bool _showFiatValues = false;
  bool _webAppsEnabled = false;
  String _selectedExplorer = kExplorer;
  FeatureDisplayMode _pillarMode = FeatureDisplayMode.auto;
  FeatureDisplayMode _sentinelMode = FeatureDisplayMode.auto;
  FeatureDisplayMode _sporksMode = FeatureDisplayMode.off;
  Map<String, String> _contacts = <String, String>{};

  /// Whether balances and amounts across the wallet should be masked.
  bool get hideBalances => _hideBalances;

  /// Whether the left navigation rail shows text labels alongside icons.
  bool get sidebarExpanded => _sidebarExpanded;

  /// Whether estimated fiat values are displayed when available.
  bool get showFiatValues => _showFiatValues;

  /// Whether local Web apps connection requests are enabled.
  bool get webAppsEnabled => _webAppsEnabled;

  /// Base URL of the selected Zenon block explorer.
  String get selectedExplorer => _selectedExplorer;

  /// Pillar UI visibility mode.
  FeatureDisplayMode get pillarMode => _pillarMode;

  /// Sentinel UI visibility mode.
  FeatureDisplayMode get sentinelMode => _sentinelMode;

  /// Sporks UI visibility mode.
  FeatureDisplayMode get sporksMode => _sporksMode;

  /// Saved contact address -> label map.
  Map<String, String> get contacts =>
      Map<String, String>.unmodifiable(_contacts);

  /// Reloads preferences from [sharedPrefsService] when available.
  void loadFromPrefs() {
    final dynamic prefs = sharedPrefsService;
    if (prefs == null) {
      return;
    }
    try {
      _hideBalances =
          sharedPrefsService!.get(kHideBalancesKey, defaultValue: false)
              as bool? ??
          false;
      _sidebarExpanded =
          sharedPrefsService!.get(kSidebarExpandedKey, defaultValue: false)
              as bool? ??
          false;
      _showFiatValues =
          sharedPrefsService!.get(kShowFiatValuesKey, defaultValue: false)
              as bool? ??
          false;
      _webAppsEnabled =
          sharedPrefsService!.get(kWebAppsBridgeKey, defaultValue: false)
              as bool? ??
          false;
      _selectedExplorer =
          sharedPrefsService!.get(kSelectedExplorerKey, defaultValue: kExplorer)
              as String? ??
          kExplorer;
      _pillarMode = _parseMode(
        sharedPrefsService!.get(kPillarModeKey) as String?,
        fallback: FeatureDisplayMode.auto,
      );
      _sentinelMode = _parseMode(
        sharedPrefsService!.get(kSentinelModeKey) as String?,
        fallback: FeatureDisplayMode.auto,
      );
      _sporksMode = _parseMode(
        sharedPrefsService!.get(kSporksModeKey) as String?,
        fallback: FeatureDisplayMode.off,
      );
      final dynamic rawContacts = sharedPrefsService!.get(kContactsMapKey);
      if (rawContacts is Map) {
        _contacts = rawContacts.map(
          (dynamic k, dynamic v) =>
              MapEntry<String, String>(k.toString(), v.toString()),
        );
      }
    } on Object catch (_) {
      // Fall back safely to defaults in tests or before Hive init.
    }
  }

  /// Sets balance masking.
  set hideBalances(bool value) {
    if (_hideBalances == value) {
      return;
    }
    _hideBalances = value;
    _persist(kHideBalancesKey, value);
    notifyListeners();
  }

  /// Toggles global balance masking.
  void toggleHideBalances() {
    hideBalances = !_hideBalances;
  }

  /// Sets whether the left navigation rail is expanded.
  set sidebarExpanded(bool value) {
    if (_sidebarExpanded == value) {
      return;
    }
    _sidebarExpanded = value;
    _persist(kSidebarExpandedKey, value);
    notifyListeners();
  }

  /// Toggles navigation rail expansion.
  void toggleSidebarExpanded() {
    sidebarExpanded = !_sidebarExpanded;
  }

  /// Sets whether fiat values are enabled.
  set showFiatValues(bool value) {
    if (_showFiatValues == value) {
      return;
    }
    _showFiatValues = value;
    _persist(kShowFiatValuesKey, value);
    notifyListeners();
  }

  /// Sets whether local Web apps bridge is enabled.
  set webAppsEnabled(bool value) {
    if (_webAppsEnabled == value) {
      return;
    }
    _webAppsEnabled = value;
    _persist(kWebAppsBridgeKey, value);
    notifyListeners();
  }

  /// Updates the active block explorer base URL.
  void setSelectedExplorer(String url) {
    if (_selectedExplorer == url) {
      return;
    }
    _selectedExplorer = url;
    _persist(kSelectedExplorerKey, url);
    notifyListeners();
  }

  /// Updates the Pillar display mode.
  void setPillarMode(FeatureDisplayMode mode) {
    if (_pillarMode == mode) {
      return;
    }
    _pillarMode = mode;
    _persist(kPillarModeKey, mode.name);
    notifyListeners();
  }

  /// Updates the Sentinel display mode.
  void setSentinelMode(FeatureDisplayMode mode) {
    if (_sentinelMode == mode) {
      return;
    }
    _sentinelMode = mode;
    _persist(kSentinelModeKey, mode.name);
    notifyListeners();
  }

  /// Updates the Sporks display mode.
  void setSporksMode(FeatureDisplayMode mode) {
    if (_sporksMode == mode) {
      return;
    }
    _sporksMode = mode;
    _persist(kSporksModeKey, mode.name);
    notifyListeners();
  }

  /// Adds or updates a named contact address.
  void saveContact(String address, String name) {
    final String trimmedAddress = address.trim();
    final String trimmedName = name.trim();
    if (trimmedAddress.isEmpty || trimmedName.isEmpty) {
      return;
    }
    _contacts = Map<String, String>.from(_contacts)
      ..[trimmedAddress] = trimmedName;
    _persist(kContactsMapKey, _contacts);
    notifyListeners();
  }

  /// Atomically replaces [originalAddress] with [newAddress] and [name].
  ///
  /// Returns `false` without mutating contacts if [newAddress] is invalid or
  /// already belongs to a different saved contact.
  bool replaceContact({
    required String originalAddress,
    required String newAddress,
    required String name,
  }) {
    final String trimmedOriginal = originalAddress.trim();
    final String trimmedNew = newAddress.trim();
    final String trimmedName = name.trim();
    if (trimmedNew.isEmpty || trimmedName.isEmpty) {
      return false;
    }
    if (trimmedNew != trimmedOriginal && _contacts.containsKey(trimmedNew)) {
      return false;
    }
    final Map<String, String> updated = Map<String, String>.from(_contacts);
    if (trimmedOriginal.isNotEmpty && trimmedOriginal != trimmedNew) {
      updated.remove(trimmedOriginal);
    }
    updated[trimmedNew] = trimmedName;
    _contacts = updated;
    _persist(kContactsMapKey, _contacts);
    notifyListeners();
    return true;
  }

  /// Removes a saved contact address.
  void removeContact(String address) {
    if (!_contacts.containsKey(address)) {
      return;
    }
    _contacts = Map<String, String>.from(_contacts)..remove(address);
    _persist(kContactsMapKey, _contacts);
    notifyListeners();
  }

  /// Returns a contact label if [address] is in the user's contacts.
  String? contactLabelFor(String address) => _contacts[address];

  void _persist(String key, dynamic value) {
    if (sharedPrefsService == null) {
      return;
    }
    try {
      unawaited(sharedPrefsService!.put(key, value));
    } on Object catch (_) {
      // Ignore storage persistence errors when Hive isn't open (unit tests).
    }
  }

  static FeatureDisplayMode _parseMode(
    String? raw, {
    required FeatureDisplayMode fallback,
  }) {
    for (final FeatureDisplayMode mode in FeatureDisplayMode.values) {
      if (mode.name == raw) {
        return mode;
      }
    }
    return fallback;
  }
}
