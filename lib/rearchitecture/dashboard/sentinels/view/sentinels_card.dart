import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/dashboard/dashboard.dart';
import 'package:zenon_syrius_wallet_flutter/utils/card/card.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/layout_scaffold/card_scaffold_without_listener.dart';

/// Widget connected to the [SentinelsCubit] that receives the state
/// - [SentinelsState] - updates and rebuilds the UI according to the
/// state's status - [DashboardStatus]
class SentinelsCard extends StatelessWidget {
  /// Creates a SentinelsCard object.
  const SentinelsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final cubit = SentinelsCubit(
          zenon!,
          const SentinelsState(),
        )..fetchDataPeriodically();
        return cubit;
      },
      child: CardScaffoldWithoutListener(
        data: CardType.sentinels.getData(context: context),
        body: BlocBuilder<SentinelsCubit, SentinelsState>(
          builder: (context, state) {
            return switch (state.status) {
              DashboardStatus.initial => const SentinelsEmpty(),
              DashboardStatus.loading => const SentinelsLoading(),
              DashboardStatus.failure => SentinelsError(
                  error: state.error!,
                ),
              DashboardStatus.success => SentinelsPopulated(
                  sentinelInfoList: state.data!,
                ),
            };
          },
        ),
      ),
    );
  }
}
