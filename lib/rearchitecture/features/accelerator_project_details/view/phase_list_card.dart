import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/accelerator_project_details/widgets/accelerator_phase_list_view.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// Card listing all phases of an Accelerator project.
class PhaseListCard extends StatelessWidget {
  /// Creates a [PhaseListCard].
  const PhaseListCard({
    required this._pillarInfo,
    required this._project,
    required this._onRefreshButtonPressed,
    required this._onStepperNotificationSeeMorePressed,
    this._activePillarCount,
    this._onPhaseUpdated,
    super.key,
  });

  final PillarInfo? _pillarInfo;
  final Project _project;
  final VoidCallback _onRefreshButtonPressed;
  final VoidCallback _onStepperNotificationSeeMorePressed;
  final int? _activePillarCount;
  final VoidCallback? _onPhaseUpdated;

  @override
  Widget build(BuildContext context) {
    return NewCardScaffold(
      data: _buildCardData(context),
      onRefreshPressed: _onRefreshButtonPressed,
      body: _project.phases.isEmpty
          ? SyriusErrorWidget(context.l10n.projectHasNoPhases)
          : AcceleratorPhaseListView(
              pillarInfo: _pillarInfo,
              activePillarCount: _activePillarCount,
              phases: _project.phases.reversed.toList(),
              project: _project,
              onPhaseUpdated: _onPhaseUpdated,
              onStepperNotificationSeeMorePressed:
                  _onStepperNotificationSeeMorePressed,
            ),
    );
  }

  CardData _buildCardData(BuildContext context) => CardData(
    title: context.l10n.phaseList,
    description: context.l10n.eachProjectComprisedOfPhases,
  );
}
