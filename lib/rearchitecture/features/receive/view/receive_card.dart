import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/tokens/cubit/tokens_cubit.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';

/// A card that listens to state updates from the [TokensCubit] and rebuilds,
/// feeding a specific widget, depending on the [TokensState.status].
class ReceiveCard extends StatelessWidget {
  /// Creates a new instance.
  const ReceiveCard({super.key});

  @override
  Widget build(BuildContext context) {
    return NewCardScaffold(
      data: CardType.receive.getData(context: context),
      onRefreshPressed: () {
        context.read<TokensCubit>().fetch();
      },
      body: BlocBuilder<TokensCubit, TokensState>(
        builder: (_, TokensState state) {
          final TokensStatus status = state.status;
          return switch (status) {
            TokensStatus.failure => ReceiveError(error: state.error!),
            TokensStatus.initial => const ReceiveInitial(),
            TokensStatus.success => ReceivePopulated(assets: state.data!),
          };
        },
      ),
    );
  }
}
