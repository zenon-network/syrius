import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// Wraps a Plasma fusion entry with app-specific presentation state.
class FusionEntryWrapper {

  /// Creates a new [FusionEntryWrapper].
  FusionEntryWrapper({
    required this.fusionEntry,
    required this.isRevocable,
  });
  /// Creates a [FusionEntryWrapper] from JSON.
  factory FusionEntryWrapper.fromJson(Map<String, dynamic> json) {
    return FusionEntryWrapper(
      fusionEntry: FusionEntry.fromJson(json['fusionEntry']),
      isRevocable: json['isRevocable'],
    );
  }

  /// The SDK fusion entry.
  final FusionEntry fusionEntry;

  /// Whether the fusion entry can currently be cancelled.
  final bool isRevocable;

  /// Converts this wrapper to JSON.
  Map<String, dynamic> toJson() => <String, dynamic>{
    'fusionEntry': fusionEntry.toJson(),
    'isRevocable': isRevocable,
  };
}
