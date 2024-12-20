import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:logging/logging.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'send_transaction_bloc.g.dart';

part 'send_transaction_event.dart';

part 'send_transaction_state.dart';

/// A bloc that handles sending payments.
class SendTransactionBloc
    extends HydratedBloc<SendTransactionEvent, SendTransactionState> {
  /// Creates a new instance of [SendTransactionBloc].
  ///
  /// Initializes the Bloc with the initial state and sets up event handlers for
  /// [SendTransactionInitiate] and [SendTransactionInitiateFromBlock] events.
  SendTransactionBloc({
    AccountBlockUtils? accountBlockUtilsHelper,
    ZenonAddressUtils? zenonAddressUtils,
  })  :
        accountBlockUtilsHelper =
            accountBlockUtilsHelper ?? AccountBlockUtils(),
        zenonAddressUtilsHelper = zenonAddressUtils ?? ZenonAddressUtils(),
        super(const SendTransactionState()) {
    on<SendTransactionInitiate>(_onSendTransfer);
    on<SendTransactionInitiateFromBlock>(_onSendTransferWithBlock);
  }

  /// Helper class with the purpose of facilitating dependency injections.
  final AccountBlockUtils accountBlockUtilsHelper;

  /// Helper class with the purpose of facilitating dependency injections.
  final ZenonAddressUtils zenonAddressUtilsHelper;

  Future<void> _onSendTransfer(
    SendTransactionInitiate event,
    Emitter<SendTransactionState> emit,
  ) async {
    try {
      emit(state.copyWith(status: SendTransactionStatus.loading));

      final AccountBlockTemplate accountBlock = AccountBlockTemplate.send(
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

      zenonAddressUtilsHelper.refreshBalance();
      emit(
        state.copyWith(
          status: SendTransactionStatus.success,
          data: response,
        ),
      );
    } catch (error, stackTrace) {
      emit(
        state.copyWith(
          status: SendTransactionStatus.failure,
          error: FailureException(),
        ),
      );
      addError(error, stackTrace);
    }
  }

  Future<void> _onSendTransferWithBlock(
    SendTransactionInitiateFromBlock event,
    Emitter<SendTransactionState> emit,
  ) async {
    try {
      emit(state.copyWith(status: SendTransactionStatus.loading));
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
          status: SendTransactionStatus.success,
          data: response,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: SendTransactionStatus.failure,
          error: FailureException(),
        ),
      );
    }
  }

  @override
  SendTransactionState? fromJson(Map<String, dynamic> json) =>
      SendTransactionState.fromJson(json);

  @override
  Map<String, dynamic>? toJson(SendTransactionState state) => state.toJson();

  @override
  void onError(Object error, StackTrace stackTrace) {
    Logger('SendTransactionBloc').warning(
      'onError triggered',
      error,
      stackTrace,
    );
    super.onError(error, stackTrace);
  }
}
