import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/create_project_stepper/create_project_stepper.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';

/// Dependency-injection wrapper for [CreateProjectStepperView].
class CreateProjectStepperPage extends StatelessWidget {
  /// Creates a [CreateProjectStepperPage].
  const CreateProjectStepperPage({this._onProjectCreated, super.key});

  final VoidCallback? _onProjectCreated;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CreateProjectBloc>(
      create: (_) => CreateProjectBloc(
        accountBlockUtils: AccountBlockUtils(),
        zenon: zenon!,
        zenonAddressUtils: ZenonAddressUtils(),
      ),
      child: CreateProjectStepperView(onProjectCreated: _onProjectCreated),
    );
  }
}
