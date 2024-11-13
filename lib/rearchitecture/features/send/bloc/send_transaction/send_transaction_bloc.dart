import 'package:equatable/equatable.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/dependency_injection_helpers/account_block_template_send.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/dependency_injection_helpers/account_block_utils_helper.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/dependency_injection_helpers/zenon_address_utils_helper.dart';
import 'package:zenon_syrius_wallet_flutter/utils/account_block_utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'send_transaction_bloc.g.dart';

part 'send_transaction_event.dart';

part 'send_transaction_state.dart';

/// A bloc that handles sending payments.
class SendTransactionBloc extends HydratedBloc<SendTransactionEvent, SendTransactionState> {
  /// Creates a new instance of [SendTransactionBloc].
  ///
  /// Initializes the Bloc with the initial state and sets up event handlers for
  /// [SendTransactionInitiate] and [SendTransferInitiateFromBlock] events.
  SendTransactionBloc({
    AccountBlockUtilsHelper? accountBlockUtilsHelper,
    ZenonAddressUtilsHelper? zenonAddressUtilsHelper,
    AccountBlockTemplateSend? accountBlockTemplateSend,
  })  : accountBlockTemplateSend =
            accountBlockTemplateSend ?? AccountBlockTemplateSend(),
        accountBlockUtilsHelper =
            accountBlockUtilsHelper ?? AccountBlockUtilsHelper(),
        zenonAddressUtilsHelper =
            zenonAddressUtilsHelper ?? ZenonAddressUtilsHelper(),
        super(const SendTransactionState()) {
    on<SendTransactionInitiate>(_onSendTransfer);
    on<SendTransferInitiateFromBlock>(_onSendTransferWithBlock);
  }

  /// Helper class with the purpose of facilitating dependency injections.
  final AccountBlockUtilsHelper accountBlockUtilsHelper;

  /// Helper class with the purpose of facilitating dependency injections.
  final ZenonAddressUtilsHelper zenonAddressUtilsHelper;

  /// Helper class with the purpose of facilitating dependency injections.
  final AccountBlockTemplateSend accountBlockTemplateSend;

  /// Handles the [SendTransactionInitiate] event to send a transfer.
  ///
  /// Constructs an [AccountBlockTemplate] for the transfer and uses
  /// [AccountBlockUtils] to create and send the account block.
  Future<void> _onSendTransfer(
    SendTransactionInitiate event,
    Emitter<SendTransactionState> emit,
  ) async {
    try {
      emit(state.copyWith(status: SendPaymentStatus.loading));

      final AccountBlockTemplate accountBlock =
          accountBlockTemplateSend.createSendBlock(
        Address.parse(event.toAddress),
        event.token.tokenStandard,
        event.amount,
        event.data,
      );

      final AccountBlockTemplate response =
          await accountBlockUtilsHelper.createAccountBlock(
        accountBlock,
        'send transaction',
        address: Address.parse(event.fromAddress),
        waitForRequiredPlasma: true,
      );

      await zenonAddressUtilsHelper.refreshBalance();
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

  /// Handles the [SendTransferInitiateFromBlock] event to send a transfer using
  /// an existing block.
  Future<void> _onSendTransferWithBlock(
    SendTransferInitiateFromBlock event,
    Emitter<SendTransactionState> emit,
  ) async {
    try {
      emit(state.copyWith(status: SendPaymentStatus.loading));
      final AccountBlockTemplate response =
          await accountBlockUtilsHelper.createAccountBlock(
        event.block,
        'send transaction',
        address: Address.parse(event.fromAddress),
        waitForRequiredPlasma: true,
      );

      zenonAddressUtilsHelper.refreshBalance();
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
  SendTransactionState? fromJson(Map<String, dynamic> json) =>
      SendTransactionState.fromJson(json);

  /// Serializes the current `SendPaymentState` into a JSON map for persistence.
  @override
  Map<String, dynamic>? toJson(SendTransactionState state) => state.toJson();
}
