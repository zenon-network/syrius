import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/refresh_bloc_mixin.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'transfer_balance_bloc.g.dart';

part 'transfer_balance_event.dart';

part 'transfer_balance_state.dart';

class TransferBalanceBloc
    extends HydratedBloc<TransferBalanceEvent, TransferBalanceState>
    with RefreshBlocMixin {
  TransferBalanceBloc({required this.zenon, required this.addressList})
      : super(
          const TransferBalanceState(),
        ) {
    on<FetchBalances>(_onFetchBalances);
    listenToWsRestart(() => add(FetchBalances()));
  }

  final Zenon zenon;
  final List<String?> addressList;

  Future<void> _onFetchBalances(
    FetchBalances event,
    Emitter<TransferBalanceState> emit,
  ) async {
    emit(state.copyWith(status: TransferBalanceStatus.loading));

    try {
      final Map<String, AccountInfo> addressBalanceMap = <String, AccountInfo>{};
      final List<AccountInfo> accountInfoList = await Future.wait(
        addressList.map(
          (String? address) => _getBalancePerAddress(address!),
        ),
      );

      for (final AccountInfo accountInfo in accountInfoList) {
        addressBalanceMap[accountInfo.address!] = accountInfo;
      }

      emit(
        state.copyWith(
          status: TransferBalanceStatus.success,
          data: addressBalanceMap,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: TransferBalanceStatus.failure,
          error: error,
        ),
      );
    }
  }

  Future<AccountInfo> _getBalancePerAddress(String address) async {
    return zenon.ledger.getAccountInfoByAddress(
      Address.parse(address),
    );
  }

  @override
  TransferBalanceState? fromJson(Map<String, dynamic> json) =>
      TransferBalanceState.fromJson(
        json,
      );

  @override
  Map<String, dynamic>? toJson(TransferBalanceState state) =>
      state.toJson();
}
