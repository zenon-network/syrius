// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_general_data.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SettingsGeneralData _$SettingsGeneralDataFromJson(Map<String, dynamic> json) =>
    SettingsGeneralData(
      momentumHeight: (json['momentumHeight'] as num).toInt(),
      momentumTimestamp: (json['momentumTimestamp'] as num).toInt(),
      momentumHash: json['momentumHash'] as String,
      peerCount: (json['peerCount'] as num).toInt(),
    );

Map<String, dynamic> _$SettingsGeneralDataToJson(
  SettingsGeneralData instance,
) => <String, dynamic>{
  'momentumHeight': instance.momentumHeight,
  'momentumTimestamp': instance.momentumTimestamp,
  'momentumHash': instance.momentumHash,
  'peerCount': instance.peerCount,
};
