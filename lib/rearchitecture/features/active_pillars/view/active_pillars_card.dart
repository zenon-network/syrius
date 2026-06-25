import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/active_pillars/active_pillars.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';

/// Widget connected to the [ActivePillarsCubit] that receives the state
/// - [ActivePillarsState] - updates and rebuilds the UI according to the
/// state's status - [TimerStatus]
class ActivePillarsCard extends StatelessWidget {
  /// Creates a PillarsCard
  const ActivePillarsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ActivePillarsCubit>(
      create: (_) => ActivePillarsCubit(
        zenon: zenon!,
      )..fetchDataPeriodically(),
      child: NewCardScaffold(
        data: _buildCardData(context: context),
        body: BlocBuilder<ActivePillarsCubit, ActivePillarsState>(
          builder: (BuildContext context, ActivePillarsState state) {
            return switch (state.status) {
              TimerStatus.initial => const ActivePillarsEmpty(),
              TimerStatus.loading => const ActivePillarsLoading(),
              TimerStatus.failure => ActivePillarsError(
                  error: state.error!,
                ),
              TimerStatus.success => ActivePillarsPopulated(
                  numberOfPillars: state.data!,
                ),
            };
          },
        ),
      ),
    );
  }

  CardData _buildCardData({required BuildContext context}) => CardData(
    title: context.l10n.activePillars,
    description: context.l10n.pillarsDescription,
  );
}
