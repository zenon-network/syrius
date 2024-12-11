import 'dart:io';

class NetworkUtils {
  static Future<String> getLocalIpAddress(
      InternetAddressType internetAddressType,) async {
    final List<NetworkInterface> interfaces = await NetworkInterface.list(
        type: internetAddressType,
        includeLinkLocal: true,);

    try {
      final NetworkInterface vpnInterface =
          interfaces.firstWhere((NetworkInterface element) => element.name == 'tun0');
      return vpnInterface.addresses.first.address;
    } on StateError {
      try {
        final NetworkInterface interface =
            interfaces.firstWhere((NetworkInterface element) => element.name == 'wlan0');
        return interface.addresses.first.address;
      } catch (e) {
        try {
          final NetworkInterface interface = interfaces.firstWhere((NetworkInterface element) =>
              !(element.name == 'tun0' || element.name == 'wlan0'),);
          return interface.addresses.first.address;
        } catch (e) {
          return e.toString();
        }
      }
    }
  }
}
