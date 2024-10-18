import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:zenon_syrius_wallet_flutter/screens/screens.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class CreatePhase extends StatelessWidget {

  const CreatePhase({
    required this.onStepperNotificationSeeMorePressed,
    required this.project,
    super.key,
  });
  final VoidCallback onStepperNotificationSeeMorePressed;
  final Project project;

  @override
  Widget build(BuildContext context) {
    return CardScaffold(
      title: 'Create Phase',
      childBuilder: () => _getWidgetBody(context),
      description: 'Create a phase for your project. '
          'The project can be divided into several phases. '
          'You will unlock the funds if you get enough votes from the Pillars.',
    );
  }

  Widget _getWidgetBody(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        const Icon(
          MaterialCommunityIcons.creation,
          size: 100,
          color: AppColors.znnColor,
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 200,
              child: Text(
                'Start the project by creating a phase to unlock funds',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            kVerticalSpacing,
            SyriusElevatedButton(
              onPressed: _canCreatePhase()
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => StepperScreen(
                            stepper: PhaseCreationStepper(project),
                            onStepperNotificationSeeMorePressed:
                                onStepperNotificationSeeMorePressed,
                          ),
                        ),
                      );
                    }
                  : null,
              text: 'Create phase',
              initialFillColor: AppColors.znnColor,
              icon: SyriusElevatedButton.getFilledButtonPlusIcon(),
            ),
          ],
        ),
      ],
    );
  }

  bool _canCreatePhase() =>
      project.status == AcceleratorProjectStatus.active &&
      (project.phases.isEmpty ||
          project.phases.last.status == AcceleratorProjectStatus.paid);
}
