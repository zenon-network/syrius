import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// A [BalanceCard] widget that displays balance information for a user.
///
/// The widget uses a [BalanceCubit] to fetch and manage account balance data
/// and presents the state in different views based on the current status
/// (e.g., loading, success, failure).
///
/// Expects a [BalanceCubit] to be provided via a [BlocProvider].
class BalanceCard extends StatelessWidget {
  /// Constructs a [BalanceCard] widget.
  const BalanceCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<BalanceCubit>(
      create: (_) => BalanceCubit(
        address: Address.parse(kSelectedAddress!),
        zenon: zenon!,
      )..fetchDataPeriodically(),
      child: NewCardScaffold(
        data: CardType.balance.getData(context: context),
        body: BlocBuilder<BalanceCubit, BalanceState>(
          builder: (BuildContext context, BalanceState state) {
            return switch (state.status) {
              TimerStatus.initial => const BalanceEmpty(),
              TimerStatus.loading => const BalanceLoading(),
              TimerStatus.failure => BalanceError(
                  error: state.error!,
                ),
              TimerStatus.success => BalancePopulated(
                  address: kSelectedAddress!,
                  accountInfo: state.data!,
                ),
            };
          },
        ),
      ),
    );
  }
}
