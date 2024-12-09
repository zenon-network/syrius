// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'no_blocks_available_exception.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

NoBlocksAvailableException _$NoBlocksAvailableExceptionFromJson(
        Map<String, dynamic> json) =>
    NoBlocksAvailableException(
      message: json['message'] as String? ?? 'No account blocks available',
    );

Map<String, dynamic> _$NoBlocksAvailableExceptionToJson(
        NoBlocksAvailableException instance) =>
    <String, dynamic>{
      'message': instance.message,
    };
