import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class PhaseList extends StatelessWidget {

  const PhaseList(
    this.pillarInfo,
    this.project,
    this.onRefreshButtonPressed, {
    required this.onStepperNotificationSeeMorePressed,
    super.key,
  });
  final PillarInfo? pillarInfo;
  final Project project;
  final VoidCallback onRefreshButtonPressed;
  final VoidCallback onStepperNotificationSeeMorePressed;

  @override
  Widget build(BuildContext context) {
    return CardScaffold(
      title: 'Phase List',
      childBuilder: () => project.phases.isEmpty
          ? const SyriusErrorWidget('The project has no phases')
          : AcceleratorProjectList(
              pillarInfo,
              project.phases.reversed.toList(),
              projects: project,
              onStepperNotificationSeeMorePressed:
                  onStepperNotificationSeeMorePressed,
            ),
      onRefreshPressed: onRefreshButtonPressed,
      description:
          'Each project can be comprised of one or more phases. Each phase needs to be voted. Phases can be updated by the owner of the project to reflect current progress of the project.',
    );
  }
}
