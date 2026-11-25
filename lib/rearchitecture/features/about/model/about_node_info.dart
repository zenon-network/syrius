import 'package:equatable/equatable.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// Immutable node diagnostic metadata displayed in the About card.
class AboutNodeInfo extends Equatable {
  /// Creates an [AboutNodeInfo].
  const AboutNodeInfo({
    this.frontierMomentum,
    this.processInfo,
    this.osInfo,
  });

  /// Latest frontier momentum reported by the node, or `null` if unavailable.
  final Momentum? frontierMomentum;

  /// Node process version and commit metadata, or `null` if unavailable.
  final ProcessInfo? processInfo;

  /// Node operating system and processor metadata, or `null` if unavailable.
  final OsInfo? osInfo;

  /// Whether all node diagnostic RPCs failed.
  bool get isUnavailable =>
      frontierMomentum == null && processInfo == null && osInfo == null;

  @override
  List<Object?> get props => <Object?>[
    frontierMomentum,
    processInfo,
    osInfo,
  ];
}
