import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/dashboard/dashboard.dart';
import 'package:zenon_syrius_wallet_flutter/utils/card/card.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/layout_scaffold/card_scaffold_without_listener.dart';

/// Widget connected to the [PillarsCubit] that receives the state
/// - [PillarsState] - updates and rebuilds the UI according to the
/// state's status - [CubitStatus]
class PillarsCard extends StatelessWidget {
  /// Creates a PillarsCard
  const PillarsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final cubit = PillarsCubit(
          zenon!,
          const PillarsState(),
        )..fetchDataPeriodically();
        return cubit;
      },
      child: CardScaffoldWithoutListener(
        data: CardType.pillars.getData(context: context),
        body: BlocBuilder<PillarsCubit, PillarsState>(
          builder: (context, state) {
            return switch (state.status) {
              CubitStatus.initial => const PillarsEmpty(),
              CubitStatus.loading => const PillarsLoading(),
              CubitStatus.failure => PillarsError(
                  error: state.error!,
                ),
              CubitStatus.success => PillarsPopulated(
                  numberOfPillars: state.data!,
                ),
            };
          },
        ),
      ),
    );
  }
}
