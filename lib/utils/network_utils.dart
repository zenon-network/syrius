import 'dart:io';

class NetworkUtils {
  static Future<String> getLocalIpAddress(
      InternetAddressType internetAddressType) async {
    final interfaces = await NetworkInterface.list(
        type: internetAddressType,
        includeLoopback: false,
        includeLinkLocal: true);

    try {
      NetworkInterface vpnInterface =
          interfaces.firstWhere((element) => element.name == "tun0");
      return vpnInterface.addresses.first.address;
    } on StateError {
      try {
        NetworkInterface interface =
            interfaces.firstWhere((element) => element.name == "wlan0");
        return interface.addresses.first.address;
      } catch (e) {
        try {
          NetworkInterface interface = interfaces.firstWhere((element) =>
              !(element.name == "tun0" || element.name == "wlan0"));
          return interface.addresses.first.address;
        } catch (e) {
          return e.toString();
        }
      }
    }
  }
}
