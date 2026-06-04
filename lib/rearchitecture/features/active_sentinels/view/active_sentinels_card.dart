import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';

/// Widget connected to the [ActiveSentinelsCubit] that receives the state
/// - [ActiveSentinelsState] - updates and rebuilds the UI according to the
/// state's status - [TimerStatus].
class ActiveSentinelsCard extends StatelessWidget {
  /// Creates an [ActiveSentinelsCard].
  const ActiveSentinelsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ActiveSentinelsCubit>(
      create: (_) {
        final ActiveSentinelsCubit cubit = ActiveSentinelsCubit(zenon: zenon!);
        unawaited(cubit.fetchDataPeriodically());
        return cubit;
      },
      child: NewCardScaffold(
        data: _buildCardData(context: context),
        body: BlocBuilder<ActiveSentinelsCubit, ActiveSentinelsState>(
          builder: (BuildContext context, ActiveSentinelsState state) {
            return switch (state.status) {
              TimerStatus.initial => const ActiveSentinelsEmpty(),
              TimerStatus.loading => const ActiveSentinelsLoading(),
              TimerStatus.failure => ActiveSentinelsError(
                error: state.error!,
              ),
              TimerStatus.success => ActiveSentinelsPopulated(
                sentinelInfoList: state.data!,
              ),
            };
          },
        ),
      ),
    );
  }

  CardData _buildCardData({required BuildContext context}) => CardData(
    title: context.l10n.activeSentinels,
    description: context.l10n.sentinelsDescription,
  );
}
