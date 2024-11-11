part of 'send_card_dimension_bloc.dart';

/// The base class for events
sealed class SendCardDimensionEvent extends Equatable {}

/// Event sent in order to change the card dimension
class SendCardDimensionChanged extends SendCardDimensionEvent {
  /// Creates a new instance.
  SendCardDimensionChanged(this.newDimension);
  /// Thew new dimension of the card.
  final DimensionCard newDimension;
  @override
  List<Object?> get props => <Object?>[newDimension];
}
