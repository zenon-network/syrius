import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/reclaim_deposit/bloc/reclaim_deposit_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/buttons/instruction_button.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// Button that reclaims an expired deposit.
class ReclaimDepositButton extends StatelessWidget {
  /// Creates a [ReclaimDepositButton].
  const ReclaimDepositButton({
    required this._depositId,
    required this._isEnabled,
    required this._loadingText,
    required this._successMessage,
    required this._text,
    this._instructionText,
    super.key,
  });

  final String _depositId;
  final bool _isEnabled;
  final String _loadingText;
  final String _successMessage;
  final String _text;
  final String? _instructionText;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ReclaimDepositBloc, ReclaimDepositState>(
      listener: _onStateChanged,
      builder: (_, ReclaimDepositState state) => InstructionButton(
        text: _text,
        isEnabled: _isEnabled,
        isLoading: state is ReclaimDepositLoading,
        loadingText: _loadingText,
        instructionText: _instructionText,
        onPressed: () => context.read<ReclaimDepositBloc>().add(
          ReclaimDepositRequested(depositId: Hash.parse(_depositId)),
        ),
      ),
    );
  }

  void _onStateChanged(BuildContext context, ReclaimDepositState state) {
    if (state case ReclaimDepositDone(:final AccountBlockTemplate block)) {
      unawaited(
        NotificationUtils.showForegroundNotification(
          context,
          WalletNotification(
            title: _successMessage,
            timestamp: DateTime.now().millisecondsSinceEpoch,
            details: context.l10n.hashValue(block.hash.toString()),
            type: NotificationType.paymentSent,
          ),
        ),
      );
    } else if (state case ReclaimDepositFailure(
      :final SyriusException exception,
    )) {
      unawaited(
        NotificationUtils.showForegroundError(
          context,
          exception,
          context.l10n.errorReclaimingDeposit,
        ),
      );
    }
  }
}
