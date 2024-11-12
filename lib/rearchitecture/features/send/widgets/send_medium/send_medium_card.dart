import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/send/widgets/send_medium/send_medium.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/transfer/multiple_balance/bloc/multiple_balance_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/tab_children_widgets/tab_children_widgets.dart';

/// A widget to be used along with `Receive` card when both widgets have a
/// dimension of [CardDimension.medium].
class SendMediumCard extends StatelessWidget {
  /// Creates a new instance.
  const SendMediumCard({required this.onExpandClicked, super.key});
  /// Callback triggered inside the [SendMediumPopulated] widget.
  final VoidCallback onExpandClicked;

  @override
  Widget build(BuildContext context) {
    return NewCardScaffold(
      data: CardType.send.getData(context: context),
      body: BlocBuilder<MultipleBalanceBloc, MultipleBalanceState>(
        builder: (_, MultipleBalanceState state) => switch (state.status) {
          MultipleBalanceStatus.failure => SendMediumError(error: state.error!),
          MultipleBalanceStatus.initial => const SendMediumEmpty(),
          MultipleBalanceStatus.loading => const SendMediumLoading(),
          MultipleBalanceStatus.success => SendMediumPopulated(
            balances: state.data!,
            onExpandClicked: onExpandClicked,
          ),
        },
      ),
    );
  }
}
