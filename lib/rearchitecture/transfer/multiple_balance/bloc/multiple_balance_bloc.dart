import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/refresh_bloc_mixin.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/exceptions/exceptions.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

part 'multiple_balance_bloc.g.dart';

part 'multiple_balance_event.dart';

part 'multiple_balance_state.dart';

/// A bloc responsible for managing transfer balances for a list of addresses.
class MultipleBalanceBloc
    extends HydratedBloc<MultipleBalanceEvent, MultipleBalanceState>
    with RefreshBlocMixin {
  /// Creates a new instance of [MultipleBalanceBloc].
  MultipleBalanceBloc({required this.zenon})
      : super(const MultipleBalanceState()) {
    on<MultipleBalanceFetch>(_onFetchBalances);
    listenToWsRestart(
      () => add(
        MultipleBalanceFetch(
          addresses: kDefaultAddressList.map((String? e) => e!).toList(),
        ),
      ),
    );
  }

  /// The Zenon SDK instance for ledger interactions.
  final Zenon zenon;

  /// Handles the [MultipleBalanceFetch] event to fetch balances for all
  /// addresses.
  Future<void> _onFetchBalances(
    MultipleBalanceFetch event,
    Emitter<MultipleBalanceState> emit,
  ) async {
    emit(state.copyWith(status: MultipleBalanceStatus.loading));

    try {
      final Map<String, AccountInfo> addressBalanceMap =
          <String, AccountInfo>{};
      final List<AccountInfo> accountInfoList = await Future.wait(
        event.addresses.map(
          _getBalancePerAddress,
        ),
      );

      for (final AccountInfo accountInfo in accountInfoList) {
        addressBalanceMap[accountInfo.address!] = accountInfo;
      }

      emit(
        state.copyWith(
          status: MultipleBalanceStatus.success,
          data: addressBalanceMap,
        ),
      );
    } catch (error, stackTrace) {
      addError(error, stackTrace);
      emit(
        state.copyWith(
          status: MultipleBalanceStatus.failure,
          error: CubitFailureException(),
        ),
      );
    }
  }

  /// Retrieves the account information for a specific [address].
  Future<AccountInfo> _getBalancePerAddress(String address) async {
    return zenon.ledger.getAccountInfoByAddress(
      Address.parse(address),
    );
  }

  /// Deserializes the state from a JSON map.
  @override
  MultipleBalanceState? fromJson(Map<String, dynamic> json) =>
      MultipleBalanceState.fromJson(json);

  /// Serializes the current state into a JSON map for persistence.
  @override
  Map<String, dynamic>? toJson(MultipleBalanceState state) => state.toJson();
}
