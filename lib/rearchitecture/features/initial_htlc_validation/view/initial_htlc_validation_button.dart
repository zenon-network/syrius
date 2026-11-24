import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/initial_htlc_validation/bloc/initial_htlc_validation_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/buttons/instruction_button.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// Button that fetches and validates an initial HTLC.
class InitialHtlcValidationButton extends StatelessWidget {
  /// Creates an [InitialHtlcValidationButton].
  const InitialHtlcValidationButton({
    required this._depositId,
    required this._isEnabled,
    super.key,
  });

  final String _depositId;
  final bool _isEnabled;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InitialHtlcValidationBloc, InitialHtlcValidationState>(
      builder: (BuildContext context, InitialHtlcValidationState state) {
        return InstructionButton(
          text: context.l10n.continueText,
          loadingText: context.l10n.searching,
          instructionText: context.l10n.inputDepositId,
          isEnabled: _isEnabled,
          isLoading: state is InitialHtlcValidationLoading,
          onPressed: () => context.read<InitialHtlcValidationBloc>().add(
            InitialHtlcValidationRequested(id: Hash.parse(_depositId)),
          ),
        );
      },
    );
  }
}
