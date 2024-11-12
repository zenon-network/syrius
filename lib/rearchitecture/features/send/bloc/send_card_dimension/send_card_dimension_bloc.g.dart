// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'send_card_dimension_bloc.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SendCardDimensionState _$SendCardDimensionStateFromJson(
        Map<String, dynamic> json) =>
    SendCardDimensionState(
      cardDimension: $enumDecode(_$CardDimensionEnumMap, json['cardDimension']),
    );

Map<String, dynamic> _$SendCardDimensionStateToJson(
        SendCardDimensionState instance) =>
    <String, dynamic>{
      'cardDimension': _$CardDimensionEnumMap[instance.cardDimension]!,
    };

const _$CardDimensionEnumMap = {
  CardDimension.small: 'small',
  CardDimension.medium: 'medium',
  CardDimension.large: 'large',
};
