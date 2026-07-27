import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

/// Deploy step for registering a sentinel.
class DeploySentinelStep extends StatefulWidget {
  /// Creates a [DeploySentinelStep].
  const DeploySentinelStep({
    required this.onDeployDone,
    super.key,
  });

  /// Called when deployment completes.
  final VoidCallback onDeployDone;

  @override
  State<DeploySentinelStep> createState() => _DeploySentinelStepState();
}

class _DeploySentinelStepState extends State<DeploySentinelStep> {
  final GlobalKey<LoadingButtonState> _registerButtonKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return BlocListener<DeploySentinelBloc, DeploySentinelState>(
      listener: (_, DeploySentinelState state) => _onDeployStateChanged(state),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          KeyedSubtree(
            key: const Key('sentinel_register_button'),
            child: LoadingButton(
              text: context.l10n.register,
              onPressed: _onDeployPressed,
              key: _registerButtonKey,
            ),
          ),
          kVerticalGap25,
        ],
      ),
    );
  }

  void _onDeployStateChanged(DeploySentinelState state) {
    if (state is DeploySentinelDone) {
      _registerButtonKey.currentState?.animateReverse();
      widget.onDeployDone();
    } else if (state is DeploySentinelFailure) {
      _registerButtonKey.currentState?.animateReverse();
      unawaited(
        NotificationUtils.sendNotificationError(
          state.exception,
          context.l10n.errorDeployingSentinel,
        ),
      );
    } else if (state is DeploySentinelLoading) {
      _registerButtonKey.currentState?.animateForward();
    }
  }

  void _onDeployPressed() {
    context.read<DeploySentinelBloc>().add(const DeploySentinelRequested());
  }
}
