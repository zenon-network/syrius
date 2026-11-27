import 'dart:io';

import 'package:collection/collection.dart';

/// Utilities for inspecting local host network interfaces.
class NetworkUtils {
  /// Returns the host's local IP address for [internetAddressType], preferring
  /// `tun0`, then `wlan0`, then any other interface.
  static Future<String> getLocalIpAddress(
    InternetAddressType internetAddressType,
  ) async {
    final List<NetworkInterface> interfaces = await NetworkInterface.list(
      type: internetAddressType,
      includeLinkLocal: true,
    );

    final NetworkInterface? vpnInterface = interfaces.firstWhereOrNull(
      (NetworkInterface element) => element.name == 'tun0',
    );
    if (vpnInterface != null && vpnInterface.addresses.isNotEmpty) {
      return vpnInterface.addresses.first.address;
    }

    final NetworkInterface? wlanInterface = interfaces.firstWhereOrNull(
      (NetworkInterface element) => element.name == 'wlan0',
    );
    if (wlanInterface != null && wlanInterface.addresses.isNotEmpty) {
      return wlanInterface.addresses.first.address;
    }

    try {
      final NetworkInterface interface = interfaces.firstWhere(
        (NetworkInterface element) =>
            !(element.name == 'tun0' || element.name == 'wlan0'),
      );
      return interface.addresses.first.address;
    } on Object catch (e) {
      return e.toString();
    }
  }
}
