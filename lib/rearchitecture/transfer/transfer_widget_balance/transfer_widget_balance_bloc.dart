import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/refresh_bloc_mixin.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'transfer_widget_balance_bloc.g.dart';
part 'transfer_widget_balance_event.dart';
part 'transfer_widget_balance_state.dart';

class TransferWidgetBalanceBloc extends
Bloc<TransferWidgetsBalanceEvent, TransferWidgetBalanceState> with
    RefreshBlocMixin {
  TransferWidgetBalanceBloc({required this.zenon, required this.list}) :
        super(const TransferWidgetBalanceState(
      status: TransferWidgetBalanceStatus.initial,)
    ,) {
    on<FetchBalances>(_onFetchBalances);
    listenToWsRestart(() => add(FetchBalances()));
  }

  final Zenon zenon;
  final List<String?> list;

  Future<void> _onFetchBalances(
      FetchBalances event,
      Emitter<TransferWidgetBalanceState> emit,
      ) async {
    emit(state.copyWith(status: TransferWidgetBalanceStatus.loading));

    try {
      final Map<String, AccountInfo> addressBalanceMap = {};
      final accountInfoList = await Future.wait(list.map(
            (address) => _getBalancePerAddress(address!),
      ),
      );

      for (final accountInfo in accountInfoList) {
        addressBalanceMap[accountInfo.address!] = accountInfo;
      }

      emit(state.copyWith(
        status: TransferWidgetBalanceStatus.success,
        data: addressBalanceMap,
      ),);
    } catch (error) {
      emit(state.copyWith(
        status: TransferWidgetBalanceStatus.failure,
        error: error,
      ),);
    }
  }

  Future<AccountInfo> _getBalancePerAddress(String address) async {
    return zenon.ledger.getAccountInfoByAddress(
      Address.parse(address),
    );
  }

  @override
  TransferWidgetBalanceState? fromJson(Map<String, dynamic> json) =>
      TransferWidgetBalanceState.fromJson(
        json,
      );

  @override
  Map<String, dynamic>? toJson(TransferWidgetBalanceState state) => state.toJson();
}
