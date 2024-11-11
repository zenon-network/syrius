// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'send_card_dimension_bloc.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SendCardDimensionState _$SendCardDimensionStateFromJson(
        Map<String, dynamic> json) =>
    SendCardDimensionState(
      cardDimension: $enumDecode(_$DimensionCardEnumMap, json['cardDimension']),
    );

Map<String, dynamic> _$SendCardDimensionStateToJson(
        SendCardDimensionState instance) =>
    <String, dynamic>{
      'cardDimension': _$DimensionCardEnumMap[instance.cardDimension]!,
    };

const _$DimensionCardEnumMap = {
  DimensionCard.small: 'small',
  DimensionCard.medium: 'medium',
  DimensionCard.large: 'large',
};
