import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/create_phase_stepper/create_phase_stepper.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/screens/screens.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// Card that launches phase creation for an active Accelerator project.
class CreatePhaseCard extends StatelessWidget {
  /// Creates a [CreatePhaseCard].
  const CreatePhaseCard({
    required this._onStepperNotificationSeeMorePressed,
    required this._project,
    this._onPhaseCreated,
    super.key,
  });

  final VoidCallback _onStepperNotificationSeeMorePressed;
  final Project _project;
  final VoidCallback? _onPhaseCreated;

  @override
  Widget build(BuildContext context) {
    return NewCardScaffold(
      data: _buildCardData(context),
      body: _View(
        onStepperNotificationSeeMorePressed:
            _onStepperNotificationSeeMorePressed,
        project: _project,
        onPhaseCreated: _onPhaseCreated,
      ),
    );
  }

  CardData _buildCardData(BuildContext context) => CardData(
    title: context.l10n.createPhase,
    description: context.l10n.createPhaseForYourProject,
  );
}

class _View extends StatelessWidget {
  const _View({
    required this._onStepperNotificationSeeMorePressed,
    required this._project,
    this._onPhaseCreated,
  });

  final VoidCallback _onStepperNotificationSeeMorePressed;
  final Project _project;
  final VoidCallback? _onPhaseCreated;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: <Widget>[
        const Icon(
          MaterialCommunityIcons.creation,
          size: 100,
          color: AppColors.znnColor,
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SizedBox(
              width: 200,
              child: Text(
                context.l10n.startProjectByCreatingPhase,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            kVerticalSpacing,
            ElevatedButton.icon(
              onPressed: _canCreatePhase()
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (BuildContext context) => StepperScreen(
                            stepper: CreatePhaseStepperPage(
                              project: _project,
                              onPhaseCreated: _onPhaseCreated,
                            ),
                            onStepperNotificationSeeMorePressed:
                                _onStepperNotificationSeeMorePressed,
                          ),
                        ),
                      );
                    }
                  : null,
              label: Text(context.l10n.createPhase),
              icon: const Icon(Icons.add),
            ),
          ],
        ),
      ],
    );
  }

  bool _canCreatePhase() =>
      _project.status == AcceleratorProjectStatus.active &&
      (_project.phases.isEmpty ||
          _project.phases.last.status == AcceleratorProjectStatus.paid);
}
