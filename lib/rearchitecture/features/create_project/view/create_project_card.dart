import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/create_project_stepper/create_project_stepper.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/screens/screens.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';

/// Card that launches the Accelerator project creation stepper.
class CreateProjectCard extends StatelessWidget {
  /// Creates a [CreateProjectCard].
  const CreateProjectCard({
    required this._onStepperNotificationSeeMorePressed,
    this._onProjectCreated,
    super.key,
  });

  final VoidCallback _onStepperNotificationSeeMorePressed;
  final VoidCallback? _onProjectCreated;

  @override
  Widget build(BuildContext context) {
    return NewCardScaffold(
      data: _buildCardData(context),
      body: _View(
        onStepperNotificationSeeMorePressed:
            _onStepperNotificationSeeMorePressed,
        onProjectCreated: _onProjectCreated,
      ),
    );
  }

  CardData _buildCardData(BuildContext context) => CardData(
    title: context.l10n.createProject,
    description: context.l10n.innovateInspireBuild,
  );
}

class _View extends StatelessWidget {
  const _View({
    required this._onStepperNotificationSeeMorePressed,
    this._onProjectCreated,
  });

  final VoidCallback _onStepperNotificationSeeMorePressed;
  final VoidCallback? _onProjectCreated;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: <Widget>[
        const Icon(
          MaterialCommunityIcons.alien,
          size: 75,
          color: AppColors.znnColor,
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SizedBox(
              width: 200,
              child: Text(
                context.l10n.joinTheAliensBuildingNom,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            kVerticalSpacing,
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (BuildContext context) => StepperScreen(
                      stepper: CreateProjectStepperPage(
                        onProjectCreated: _onProjectCreated,
                      ),
                      onStepperNotificationSeeMorePressed:
                          _onStepperNotificationSeeMorePressed,
                    ),
                  ),
                );
              },
              label: Text(context.l10n.createProject),
              icon: const Icon(Icons.add),
            ),
          ],
        ),
      ],
    );
  }
}
