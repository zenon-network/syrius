import 'package:equatable/equatable.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:zenon_syrius_wallet_flutter/utils/account_block_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/address_utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'send_payment_bloc.g.dart';

part 'send_payment_event.dart';

part 'send_payment_state.dart';

/// A bloc that handles sending payments.
class SendPaymentBloc extends HydratedBloc<SendPaymentEvent, SendPaymentState> {
  /// Creates a new instance of [SendPaymentBloc].
  ///
  /// Initializes the Bloc with the initial state and sets up event handlers for
  /// [SendTransfer] and [SendTransferWithBlock] events.
  SendPaymentBloc() : super(const SendPaymentState()) {
    on<SendTransfer>(_onSendTransfer);
    on<SendTransferWithBlock>(_onSendTransferWithBlock);
  }

  /// Handles the [SendTransfer] event to send a transfer.
  ///
  /// Constructs an [AccountBlockTemplate] for the transfer and uses
  /// [AccountBlockUtils] to create and send the account block.
  Future<void> _onSendTransfer(
    SendTransfer event,
    Emitter<SendPaymentState> emit,
  ) async {
    try {
      emit(state.copyWith(status: SendPaymentStatus.loading));

      final AccountBlockTemplate accountBlock = AccountBlockTemplate.send(
        Address.parse(event.toAddress),
        event.token.tokenStandard,
        event.amount,
        event.data,
      );

      final AccountBlockTemplate response =
          await AccountBlockUtils.createAccountBlock(
        accountBlock,
        'send transaction',
        address: Address.parse(event.fromAddress),
        waitForRequiredPlasma: true,
      );

      ZenonAddressUtils.refreshBalance();
      emit(
        state.copyWith(
          status: SendPaymentStatus.success,
          data: response,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: SendPaymentStatus.failure,
          error: error,
        ),
      );
    }
  }

  /// Handles the [SendTransferWithBlock] event to send a transfer using
  /// an existing block.
  Future<void> _onSendTransferWithBlock(
    SendTransferWithBlock event,
    Emitter<SendPaymentState> emit,
  ) async {
    try {
      emit(state.copyWith(status: SendPaymentStatus.loading));
      final AccountBlockTemplate response =
          await AccountBlockUtils.createAccountBlock(
        event.block,
        'send transaction',
        address: Address.parse(event.fromAddress),
        waitForRequiredPlasma: true,
      );

      ZenonAddressUtils.refreshBalance();
      emit(
        state.copyWith(
          status: SendPaymentStatus.success,
          data: response,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: SendPaymentStatus.failure,
          error: error,
        ),
      );
    }
  }

  /// Deserializes the `SendPaymentState` from a JSON map.
  @override
  SendPaymentState? fromJson(Map<String, dynamic> json) =>
      SendPaymentState.fromJson(json);

  /// Serializes the current `SendPaymentState` into a JSON map for persistence.
  @override
  Map<String, dynamic>? toJson(SendPaymentState state) => state.toJson();
}
