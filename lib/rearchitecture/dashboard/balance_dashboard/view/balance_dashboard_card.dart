import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/dashboard/dashboard.dart';



/// A `BalanceDashboardCard` widget that displays the account balance information
/// for a specific account.
///
/// This widget utilizes the `BalanceDashboardCubit` to manage the state of the
/// balance data and presents different views based on the current status
/// (e.g., loading, success, failure).
class BalanceDashboardCard extends StatelessWidget {
  /// Constructs a `BalanceDashboardCard` widget.
  const BalanceDashboardCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        // Creates a `BalanceDashboardCubit` instance, passing in the `zenon` client
        // and an initial `BalanceDashboardState`. The cubit immediately begins fetching
        // the balance data by calling `fetch()`.
        final cubit = BalanceDashboardCubit(
          zenon!,
          const BalanceDashboardState(),
        );
        cubit.fetchDataPeriodically();
        return cubit;
      },
      child: Scaffold(
        body: BlocBuilder<BalanceDashboardCubit, DashboardState>(
          builder: (context, state) {
            // Uses a `switch` statement to display different widgets based on
            // the current cubit state. The state is managed by the `BalanceDashboardCubit`
            // and derived from `DashboardState`, with different widgets rendered for each status.
            return switch (state.status) {
            // Displays an empty balance view when the cubit is in its initial state.
              CubitStatus.initial => const BalanceDashboardEmpty(),

            // Shows a loading indicator while the cubit is fetching balance data.
              CubitStatus.loading => const BalanceDashboardLoading(),

            // Displays an error message if fetching balance data fails.
              CubitStatus.failure => BalanceDashboardError(
                error: state.error!,
              ),

            // Shows the populated balance data when it is successfully fetched.
              CubitStatus.success => BalanceDashboardPopulated(
                data: state.data,
              ),
            };
          },
        ),
      ),
    );
  }
}
