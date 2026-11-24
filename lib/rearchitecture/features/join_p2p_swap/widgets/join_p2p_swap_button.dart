import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/extensions.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/buttons/instruction_button.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// Button that creates an incoming native HTLC swap.
class JoinSwapButton extends StatelessWidget {
  /// Creates a [JoinSwapButton].
  const JoinSwapButton({
    required this._fromAmount,
    required this._fromToken,
    required this._initialHtlc,
    required this._isEnabled,
    required this._toToken,
    super.key,
  });

  final String _fromAmount;
  final Token _fromToken;
  final HtlcInfo _initialHtlc;
  final bool _isEnabled;
  final Token _toToken;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<JoinP2pSwapBloc, JoinP2pSwapState>(
      builder: (BuildContext context, JoinP2pSwapState state) {
        return InstructionButton(
          text: context.l10n.joinSwap,
          instructionText: context.l10n.inputAmountToSend,
          loadingText: context.l10n.sendingTransaction,
          isEnabled: _isEnabled,
          isLoading: state is JoinP2pSwapLoading,
          onPressed: () => context.read<JoinP2pSwapBloc>().add(
            JoinP2pSwapRequested(
              initialHtlc: _initialHtlc,
              fromToken: _fromToken,
              toToken: _toToken,
              fromAmount: _fromAmount.extractDecimals(_fromToken.decimals),
              swapType: P2pSwapType.native,
              fromChain: P2pSwapChain.nom,
              toChain: P2pSwapChain.nom,
            ),
          ),
        );
      },
    );
  }
}
