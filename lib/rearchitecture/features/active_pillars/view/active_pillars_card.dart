import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/active_pillars/active_pillars.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/reusable_widgets.dart';

/// Widget connected to the [ActivePillarsCubit] that receives the state
/// - [ActivePillarsState] - updates and rebuilds the UI according to the
/// state's status - [TimerStatus]
class ActivePillarsCard extends StatelessWidget {
  /// Creates a PillarsCard
  const ActivePillarsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ActivePillarsCubit>(
      create: (_) {
        final ActivePillarsCubit cubit = ActivePillarsCubit(zenon: zenon!);
        unawaited(cubit.fetchDataPeriodically());
        return cubit;
      },
      child: NewCardScaffold(
        data: _buildCardData(context: context),
        body: BlocBuilder<ActivePillarsCubit, ActivePillarsState>(
          builder: (BuildContext context, ActivePillarsState state) {
            return switch (state.status) {
              TimerStatus.initial => const _Empty(),
              TimerStatus.loading => const _Loading(),
              TimerStatus.failure => _Error(
                error: state.error!,
              ),
              TimerStatus.success => _Populated(
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
  const _Populated({required this.numberOfPillars});

  final int numberOfPillars;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        SvgPicture.asset(
          'assets/svg/ic_pillars_dashboard.svg',
          width: 65,
        ),
        Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            NumberAnimation(
              end: numberOfPillars,
              isInt: true,
              style: context.textTheme.headlineMedium,
            ),
            Text(
              context.l10n.activePillars,
              style: context.textTheme.bodyMedium,
            ),
          ],
        ),
      ],
    );
  }
}
