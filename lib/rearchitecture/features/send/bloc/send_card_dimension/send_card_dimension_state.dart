part of 'send_card_dimension_bloc.dart';

/// A class that helps manage the dimension of the `Send` card
@JsonSerializable()
class SendCardDimensionState extends Equatable {
  /// Creates a new instance with a specified [cardDimension]
  const SendCardDimensionState({required this.cardDimension});

  /// Creates a new instance with a default value of [CardDimension.medium] for
  /// [cardDimension]
  const SendCardDimensionState.initial(): this(
    cardDimension: CardDimension.medium,
  );

  /// {@macro state_from_json}
  factory SendCardDimensionState.fromJson(Map<String, dynamic> json) =>
      _$SendCardDimensionStateFromJson(json);

  /// The current dimension
  final CardDimension cardDimension;

  @override
  List<Object?> get props => <Object?>[cardDimension];

  /// {@macro state_to_json}
  Map<String, dynamic> toJson() => _$SendCardDimensionStateToJson(this);
}
