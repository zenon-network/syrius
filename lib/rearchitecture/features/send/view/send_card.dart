import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';

/// A widget to be used along with `Receive` card.
class SendCard extends StatelessWidget {
  /// Creates a new instance.
  const SendCard({super.key});

  @override
  Widget build(BuildContext context) {
    return NewCardScaffold(
      data: CardType.send.getData(context: context),
      body: BlocBuilder<MultipleBalanceBloc, MultipleBalanceState>(
        builder: (_, MultipleBalanceState state) => switch (state.status) {
          MultipleBalanceStatus.failure => SendError(error: state.error!),
          MultipleBalanceStatus.initial => const SendEmpty(),
          MultipleBalanceStatus.loading => const SendLoading(),
          MultipleBalanceStatus.success => SendPopulated(
            balances: state.data!,
          ),
        },
      ),
    );
  }
}
