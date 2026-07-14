import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// A card that receives [RealtimeStatisticsState] updates from the
/// [RealtimeStatisticsCubit] and changes the UI according to the request
/// status - [TimerStatus].
class RealtimeStatisticsCard extends StatelessWidget {
  /// Creates a RealtimeStatisticsCard object.
  const RealtimeStatisticsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<RealtimeStatisticsCubit>(
      create: (_) {
        final RealtimeStatisticsCubit cubit = RealtimeStatisticsCubit(
          address: Address.parse(kSelectedAddress!),
          zenon: zenon!,
        );
        unawaited(cubit.fetchDataPeriodically());
        return cubit;
      },
      child: NewCardScaffold(
        data: _buildCardData(context: context),
        body: BlocBuilder<RealtimeStatisticsCubit, RealtimeStatisticsState>(
          builder: (BuildContext context, RealtimeStatisticsState state) {
            return switch (state.status) {
              TimerStatus.initial => const RealtimeStatisticsEmpty(),
              TimerStatus.loading => const RealtimeStatisticsLoading(),
              TimerStatus.failure => RealtimeStatisticsError(
                error: state.error!,
              ),
              TimerStatus.success => RealtimeStatisticsPopulated(
                accountBlocks: state.data!,
              ),
            };
          },
        ),
      ),
    );
  }

  CardData _buildCardData({required BuildContext context}) => CardData(
    title: context.l10n.realtimeStats,
    description: context.l10n.realtimeStatsDescription(
      kQsrCoin.symbol,
      kZnnCoin.symbol,
    ),
  );
}
