import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:equatable/equatable.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/tab_children_widgets/tab_children_widgets.dart';

part 'send_card_dimension_bloc.g.dart';

part 'send_card_dimension_event.dart';

part 'send_card_dimension_state.dart';

/// A bloc that helps manage the dimension of the `Send` card from the
/// `Transfer` tab.
///
/// Because the dimensions of the `Send` and the `Receive` cards are mutually
/// exclusive, then one bloc for either card is enough.
class SendCardDimensionBloc
    extends HydratedBloc<SendCardDimensionEvent, SendCardDimensionState> {
  /// Send
  SendCardDimensionBloc() : super(const SendCardDimensionState.initial()) {
    on<SendCardDimensionChanged>(
      _onSendCardDimensionChanged,
      transformer: droppable(),
    );
  }

  void _onSendCardDimensionChanged(
    SendCardDimensionChanged event,
    Emitter<SendCardDimensionState> emit,
  ) {
    emit(SendCardDimensionState(cardDimension: event.newDimension));
  }

  @override
  SendCardDimensionState? fromJson(Map<String, dynamic> json) =>
      SendCardDimensionState.fromJson(json);

  @override
  Map<String, dynamic>? toJson(SendCardDimensionState state) => state.toJson();
}
