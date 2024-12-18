// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cubit_failure_exception.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CubitFailureException _$CubitFailureExceptionFromJson(
        Map<String, dynamic> json) =>
    CubitFailureException(
      message: json['message'] as String? ?? 'Something went wrong',
    );

Map<String, dynamic> _$CubitFailureExceptionToJson(
        CubitFailureException instance) =>
    <String, dynamic>{
      'message': instance.message,
    };
