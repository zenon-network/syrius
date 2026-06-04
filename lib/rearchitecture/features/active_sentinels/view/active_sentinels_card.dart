import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

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
              TimerStatus.initial => const _Empty(),
              TimerStatus.loading => const _Loading(),
              TimerStatus.failure => _Error(
                error: state.error!,
              ),
              TimerStatus.success => _Populated(
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

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    return SyriusErrorWidget(context.l10n.waitingForDataFetching);
  }
}

class _Error extends StatelessWidget {
  const _Error({required this.error});

  final SyriusException error;

  @override
  Widget build(BuildContext context) {
    return SyriusErrorWidget(error);
  }
}

class _Loading extends StatelessWidget {
  const _Loading();

  @override
  Widget build(BuildContext context) {
    return const SyriusLoadingWidget();
  }
}

class _Populated extends StatelessWidget {
  const _Populated({required this.sentinelInfoList});

  final SentinelInfoList sentinelInfoList;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(12),
          child: SvgPicture.asset(
            'assets/svg/ic_sentinels_dashboard.svg',
            width: 42,
          ),
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            NumberAnimation(
              end: sentinelInfoList.count,
              isInt: true,
              style: context.textTheme.headlineMedium,
            ),
            Text(
              context.l10n.activeSentinels,
              style: context.textTheme.bodyMedium,
            ),
          ],
        ),
      ],
    );
  }
}
