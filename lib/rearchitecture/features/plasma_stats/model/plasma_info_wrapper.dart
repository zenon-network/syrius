import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// Plasma information associated with a wallet address.
class PlasmaInfoWrapper {
  /// Creates a Plasma info wrapper.
  PlasmaInfoWrapper({
    required this.address,
    required this.plasmaInfo,
  });

  /// Creates a Plasma info wrapper from a JSON map.
  factory PlasmaInfoWrapper.fromJson(Map<String, dynamic> json) {
    return PlasmaInfoWrapper(
      address: json['address'],
      plasmaInfo: PlasmaInfo.fromJson(json['plasmaInfo']),
    );
  }

  /// Address that owns the Plasma info.
  final String address;

  /// Plasma details for [address].
  final PlasmaInfo plasmaInfo;

  /// Converts this wrapper to a JSON map.
  Map<String, dynamic> toJson() => <String, dynamic>{
    'address': address,
    'plasmaInfo': plasmaInfo.toJson(),
  };
}
