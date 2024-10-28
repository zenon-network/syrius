import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';

/// Widget connected to the [PillarsCubit] that receives the state
/// - [PillarsState] - updates and rebuilds the UI according to the
/// state's status - [TimerStatus]
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
              TimerStatus.initial => const PillarsEmpty(),
              TimerStatus.loading => const PillarsLoading(),
              TimerStatus.failure => PillarsError(
                  error: state.error!,
                ),
              TimerStatus.success => PillarsPopulated(
                  numberOfPillars: state.data!,
                ),
            };
          },
        ),
      ),
    );
  }
}
