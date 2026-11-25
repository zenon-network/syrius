import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'settings_general_data.g.dart';

/// General network and momentum metrics displayed in the Settings General card.
@JsonSerializable()
class SettingsGeneralData extends Equatable {
  /// Creates a [SettingsGeneralData] instance.
  const SettingsGeneralData({
    required this.momentumHeight,
    required this.momentumTimestamp,
    required this.momentumHash,
    required this.peerCount,
  });

  /// Creates a [SettingsGeneralData] instance from JSON.
  factory SettingsGeneralData.fromJson(Map<String, dynamic> json) =>
      _$SettingsGeneralDataFromJson(json);

  /// Latest frontier momentum height.
  final int momentumHeight;

  /// Latest frontier momentum Unix timestamp.
  final int momentumTimestamp;

  /// Latest frontier momentum hash string.
  final String momentumHash;

  /// Number of connected network peers.
  final int peerCount;

  /// Converts this [SettingsGeneralData] instance to JSON.
  Map<String, dynamic> toJson() => _$SettingsGeneralDataToJson(this);

  @override
  List<Object?> get props => <Object?>[
    momentumHeight,
    momentumTimestamp,
    momentumHash,
    peerCount,
  ];
}
