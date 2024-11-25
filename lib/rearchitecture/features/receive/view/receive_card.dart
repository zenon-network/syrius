import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/tokens/cubit/tokens_cubit.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';

class ReceiveCard extends StatelessWidget {
  const ReceiveCard({super.key});

  @override
  Widget build(BuildContext context) {
    return NewCardScaffold(
      data: CardType.receive.getData(context: context),
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
