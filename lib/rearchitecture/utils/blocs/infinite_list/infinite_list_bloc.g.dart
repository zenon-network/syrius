// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'infinite_list_bloc.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

InfiniteListState<T> _$InfiniteListStateFromJson<T>(
  Map<String, dynamic> json,
  T Function(Object? json) fromJsonT,
) =>
    InfiniteListState<T>(
      status: $enumDecode(_$InfiniteListStatusEnumMap, json['status']),
      data: (json['data'] as List<dynamic>).map(fromJsonT).toList(),
      error: json['error'] == null
          ? null
          : SyriusException.fromJson(json['error'] as Map<String, dynamic>),
      hasReachedMax: json['hasReachedMax'] as bool? ?? false,
    );

Map<String, dynamic> _$InfiniteListStateToJson<T>(
  InfiniteListState<T> instance,
  Object? Function(T value) toJsonT,
) =>
    <String, dynamic>{
      'status': _$InfiniteListStatusEnumMap[instance.status]!,
      'data': instance.data.map(toJsonT).toList(),
      'error': instance.error?.toJson(),
      'hasReachedMax': instance.hasReachedMax,
    };

const _$InfiniteListStatusEnumMap = {
  InfiniteListStatus.initial: 'initial',
  InfiniteListStatus.failure: 'failure',
  InfiniteListStatus.success: 'success',
};
