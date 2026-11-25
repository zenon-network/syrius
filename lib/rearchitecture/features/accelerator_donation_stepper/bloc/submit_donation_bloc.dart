import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/exceptions/exceptions.dart';
import 'package:zenon_syrius_wallet_flutter/utils/account_block_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/address_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/zts_utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'submit_donation_event.dart';
part 'submit_donation_state.dart';

/// Submits ZNN and/or QSR donations to the Accelerator embedded contract.
class SubmitDonationBloc
    extends Bloc<SubmitDonationEvent, SubmitDonationState> {
  /// Creates a [SubmitDonationBloc].
  SubmitDonationBloc({
    required this._accountBlockUtils,
    required this._zenon,
    required this._zenonAddressUtils,
  }) : super(const SubmitDonationInitial()) {
    on<SubmitDonationRequested>(_onSubmitDonationRequested);
  }

  final AccountBlockUtils _accountBlockUtils;
  final Zenon _zenon;
  final ZenonAddressUtils _zenonAddressUtils;

  Future<void> _onSubmitDonationRequested(
    SubmitDonationRequested event,
    Emitter<SubmitDonationState> emit,
  ) async {
    if (event.znnAmount <= BigInt.zero && event.qsrAmount <= BigInt.zero) {
      emit(
        SubmitDonationFailure(
          exception: SyriusException(
            'Donation amount must be greater than zero',
          ),
        ),
      );
      return;
    }

    emit(const SubmitDonationLoading());

    final List<AccountBlockTemplate> sentBlocks = <AccountBlockTemplate>[];
    try {
      if (event.znnAmount > BigInt.zero) {
        final AccountBlockTemplate znnParams = _zenon.embedded.accelerator
            .donate(event.znnAmount, kZnnCoin.tokenStandard);
        final AccountBlockTemplate znnBlock = await _accountBlockUtils
            .createAccountBlock(
              znnParams,
              'donate for accelerator',
              address: event.address,
            );
        sentBlocks.add(znnBlock);
      }

      if (event.qsrAmount > BigInt.zero) {
        final AccountBlockTemplate qsrParams = _zenon.embedded.accelerator
            .donate(event.qsrAmount, kQsrCoin.tokenStandard);
        final AccountBlockTemplate qsrBlock = await _accountBlockUtils
            .createAccountBlock(
              qsrParams,
              'donate for accelerator',
              address: event.address,
            );
        sentBlocks.add(qsrBlock);
      }

      _zenonAddressUtils.refreshBalance();
      emit(SubmitDonationDone(blocks: sentBlocks));
    } on SyriusException catch (e, stackTrace) {
      if (sentBlocks.isNotEmpty) {
        _zenonAddressUtils.refreshBalance();
      }
      addError(e, stackTrace);
      emit(SubmitDonationFailure(exception: e));
    } on Object catch (e, stackTrace) {
      if (sentBlocks.isNotEmpty) {
        _zenonAddressUtils.refreshBalance();
      }
      addError(e, stackTrace);
      emit(SubmitDonationFailure(exception: FailureException()));
    }
  }
}
