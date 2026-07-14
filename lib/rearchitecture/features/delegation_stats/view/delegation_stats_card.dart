import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nested/nested.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// A card that displays delegation stats and updates from request states.
class DelegationCard extends StatelessWidget {
  /// Creates a DelegationCard object.
  const DelegationCard({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: <SingleChildWidget>[
        BlocProvider<UndelegateBloc>(
          create: (_) => UndelegateBloc(
            accountBlockUtils: AccountBlockUtils(),
            zenon: zenon!,
          ),
        ),
      ],
      child: NewCardScaffold(
        data: _buildCardData(context: context),
        onRefreshPressed: () {
          context.read<DelegationStatsBloc>().add(
            FetchRequestData(address: Address.parse(kSelectedAddress!)),
          );
        },
        body: BlocBuilder<DelegationStatsBloc, FetchState<DelegationInfo>>(
          builder: (BuildContext context, FetchState<DelegationInfo> state) =>
              switch (state) {
                FetchFailure<DelegationInfo>() => DelegationStatsError(
                  error: state.exception,
                ),
                FetchInitial<DelegationInfo>() => const DelegationStatsEmpty(),
                FetchPopulated<DelegationInfo>() => DelegationStatsPopulated(
                  delegationInfo: state.data,
                ),
              },
        ),
      ),
    );
  }

  CardData _buildCardData({required BuildContext context}) => CardData(
    title: context.l10n.delegationStats,
    description: context.l10n.delegationStatsDescription(kZnnCoin.symbol),
  );
}
