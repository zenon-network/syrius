import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/complete_swap/bloc/complete_swap_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/p2p_swap/model/p2p_swap.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/buttons/instruction_button.dart';

/// Button that completes an HTLC swap.
class CompleteSwapButton extends StatelessWidget {
  /// Creates a [CompleteSwapButton].
  const CompleteSwapButton({
    required this._swap,
    super.key,
  });

  final HtlcSwap _swap;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CompleteSwapBloc, CompleteSwapState>(
      builder: (BuildContext context, CompleteSwapState state) {
        return InstructionButton(
          text: context.l10n.swap,
          isEnabled: true,
          isLoading: state is CompleteSwapLoading,
          loadingText: context.l10n.swapping,
          onPressed: () => context.read<CompleteSwapBloc>().add(
            CompleteSwapRequested(swap: _swap),
          ),
        );
      },
    );
  }
}
