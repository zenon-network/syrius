import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/modular_widgets/accelerator_widgets/accelerator_project_list.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/error_widget.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/layout_scaffold/card_scaffold.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class PhaseList extends StatelessWidget {
  final PillarInfo? pillarInfo;
  final Project project;
  final VoidCallback onRefreshButtonPressed;
  final VoidCallback onStepperNotificationSeeMorePressed;

  const PhaseList(
    this.pillarInfo,
    this.project,
    this.onRefreshButtonPressed, {
    required this.onStepperNotificationSeeMorePressed,
    Key? key,
  }) : super(key: key);

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
