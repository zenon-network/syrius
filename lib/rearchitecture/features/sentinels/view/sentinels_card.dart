import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/cubits/timer_cubit.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/widgets/card_scaffold_without_listener.dart';

/// Widget connected to the [SentinelsCubit] that receives the state
/// - [SentinelsState] - updates and rebuilds the UI according to the
/// state's status - [TimerStatus]
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
              TimerStatus.initial => const SentinelsEmpty(),
              TimerStatus.loading => const SentinelsLoading(),
              TimerStatus.failure => SentinelsError(
                  error: state.error!,
                ),
              TimerStatus.success => SentinelsPopulated(
                  sentinelInfoList: state.data!,
                ),
            };
          },
        ),
      ),
    );
  }
}
