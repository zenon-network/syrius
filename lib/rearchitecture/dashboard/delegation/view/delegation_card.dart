import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/dashboard/dashboard.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:zenon_syrius_wallet_flutter/utils/zts_utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/layout_scaffold/card_scaffold_without_listener.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

const String _kWidgetTitle = 'Delegation Stats';
final String _kWidgetDescription = 'This card displays the amount of '
    '${kZnnCoin.symbol} and the name of the Pillar that you delegated to';

class DelegationCard extends StatelessWidget {
  const DelegationCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final DelegationCubit cubit = DelegationCubit(
          Address.parse(kSelectedAddress!),
          zenon!,
          DelegationState(),
        );
        cubit.fetchDataPeriodically();
        return cubit;
      },
      child: CardScaffoldWithoutListener(
        description: _kWidgetDescription,
        title: _kWidgetTitle,
        child: BlocBuilder<DelegationCubit, DashboardState>(
          builder: (context, state) {
            return switch (state.status) {
              CubitStatus.initial => const DelegationEmpty(),
              CubitStatus.loading => const DelegationLoading(),
              CubitStatus.failure => DelegationError(
                  error: state.error!,
                ),
              CubitStatus.success => DelegationPopulated(
                  data: state.data!,
                ),
            };
          },
        ),
      ),
    );
  }
}
