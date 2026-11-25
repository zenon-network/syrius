import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/create_phase_stepper/create_phase_stepper.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// Dependency-injection wrapper for [CreatePhaseStepperView].
class CreatePhaseStepperPage extends StatelessWidget {
  /// Creates a [CreatePhaseStepperPage].
  const CreatePhaseStepperPage({
    required this._project,
    this._onPhaseCreated,
    super.key,
  });

  final Project _project;
  final VoidCallback? _onPhaseCreated;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CreatePhaseBloc>(
      create: (_) => CreatePhaseBloc(
        accountBlockUtils: AccountBlockUtils(),
        zenon: zenon!,
      ),
      child: CreatePhaseStepperView(
        project: _project,
        onPhaseCreated: _onPhaseCreated,
      ),
    );
  }
}
