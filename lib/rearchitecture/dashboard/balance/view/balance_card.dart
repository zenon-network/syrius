import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/dashboard/dashboard.dart';
import 'package:zenon_syrius_wallet_flutter/utils/card/card.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/layout_scaffold/card_scaffold_without_listener.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// A `BalanceCard` widget that displays balance information for a user.
///
/// The widget uses a `BalanceCubit` to fetch and manage account balance data
/// and presents the state in different views based on the current status
/// (e.g., loading, success, failure).
class BalanceCard extends StatelessWidget {
  /// Constructs a `BalanceCard` widget.
  ///
  /// The widget is a stateless widget and expects a `BalanceCubit` to be
  /// provided via a `BlocProvider`.
  const BalanceCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        // Creates a `BalanceCubit` instance, passing in the `zenon` client
        // and an initial `BalanceState`. The cubit immediately begins fetching
        // balance data by calling `fetch()`.
        final cubit = BalanceCubit(
          Address.parse(kSelectedAddress!),
          zenon!,
          const BalanceState(),
        );
        cubit.fetchDataPeriodically();
        return cubit;
      },
      child: CardScaffoldWithoutListener(
        data: CardType.balance.getData(context: context),
        body: BlocBuilder<BalanceCubit, BalanceState>(
          builder: (context, state) {
            // Uses a `switch` statement to display different widgets based on
            // the current cubit state. The state is managed by the `BalanceCubit` and
            // is derived from `DashboardState`, with different widgets rendered for each status.
            return switch (state.status) {
              // Displays an empty balance view when the cubit is in its initial state.
              CubitStatus.initial => const BalanceEmpty(),

              // Shows a loading indicator while the cubit is fetching balance data.
              CubitStatus.loading => const BalanceLoading(),

              // Displays an error message if fetching balance data fails.
              CubitStatus.failure => BalanceError(
                  error: state.error!,
                ),

              // Shows the populated balance data when it is successfully fetched.
              CubitStatus.success => BalancePopulated(
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
