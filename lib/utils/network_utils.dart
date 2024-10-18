import 'dart:io';

class NetworkUtils {
  static Future<String> getLocalIpAddress(
      InternetAddressType internetAddressType,) async {
    final interfaces = await NetworkInterface.list(
        type: internetAddressType,
        includeLinkLocal: true,);

    try {
      final vpnInterface =
          interfaces.firstWhere((element) => element.name == 'tun0');
      return vpnInterface.addresses.first.address;
    } on StateError {
      try {
        final interface =
            interfaces.firstWhere((element) => element.name == 'wlan0');
        return interface.addresses.first.address;
      } catch (e) {
        try {
          final interface = interfaces.firstWhere((element) =>
              !(element.name == 'tun0' || element.name == 'wlan0'),);
          return interface.addresses.first.address;
        } catch (e) {
          return e.toString();
        }
      }
    }
  }
}
