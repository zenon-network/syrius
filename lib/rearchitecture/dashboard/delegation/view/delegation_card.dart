import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/dashboard/dashboard.dart';
import 'package:zenon_syrius_wallet_flutter/utils/card/card.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

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
        type: CardType.delegationStats,
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
