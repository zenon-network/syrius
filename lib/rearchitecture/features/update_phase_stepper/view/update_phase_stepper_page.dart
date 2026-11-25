import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/update_phase_stepper/update_phase_stepper.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// Dependency-injection wrapper for [UpdatePhaseStepperView].
class UpdatePhaseStepperPage extends StatelessWidget {
  /// Creates an [UpdatePhaseStepperPage].
  const UpdatePhaseStepperPage({
    required this._phase,
    required this._project,
    this._onPhaseUpdated,
    super.key,
  });

  final Phase _phase;
  final Project _project;
  final VoidCallback? _onPhaseUpdated;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<UpdatePhaseBloc>(
      create: (_) => UpdatePhaseBloc(
        accountBlockUtils: AccountBlockUtils(),
        zenon: zenon!,
      ),
      child: UpdatePhaseStepperView(
        phase: _phase,
        project: _project,
        onPhaseUpdated: _onPhaseUpdated,
      ),
    );
  }
}
