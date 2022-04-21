import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class GeneralStats {
  final Momentum frontierMomentum;
  final ProcessInfo processInfo;
  final NetworkInfo networkInfo;
  final OsInfo osInfo;

  GeneralStats(
      {required this.frontierMomentum,
      required this.processInfo,
      required this.networkInfo,
      required this.osInfo});
}

class LatestMomentum {
  final String hash;
  final int? height;
  final int? time;

  LatestMomentum({
    required this.hash,
    required this.height,
    required this.time,
  });

  factory LatestMomentum.fromJson(Map<String, dynamic> json) => LatestMomentum(
        hash: json['Hash'].toString(),
        height: json['Height'],
        time: json['Time'],
      );
}
