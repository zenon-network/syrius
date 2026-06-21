import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class PlasmaInfoWrapper {

  factory PlasmaInfoWrapper.fromJson(Map<String, dynamic> json) {
    return PlasmaInfoWrapper(
      address: json['address'],
      plasmaInfo: PlasmaInfo.fromJson(json['plasmaInfo']),
    );
  }

  PlasmaInfoWrapper({
    required this.address,
    required this.plasmaInfo,
  });

  final String address;
  final PlasmaInfo plasmaInfo;

  Map<String, dynamic> toJson() => {
    'address': address,
    'plasmaInfo': plasmaInfo.toJson(),
  };
}
