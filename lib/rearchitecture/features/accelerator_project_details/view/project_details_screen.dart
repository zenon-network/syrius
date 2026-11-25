import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:layout/layout.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/accelerator_project_details/accelerator_project_details.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/create_phase/create_phase.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// Displays detailed funding stats, phase creation, and phases for a project.
class ProjectDetailsScreen extends StatelessWidget {
  /// Creates a [ProjectDetailsScreen].
  const ProjectDetailsScreen({
    required this._project,
    required this._pillarInfo,
    required this._onStepperNotificationSeeMorePressed,
    this._activePillarCount,
    this._refreshProjectBloc,
    super.key,
  });

  final VoidCallback _onStepperNotificationSeeMorePressed;
  final AcceleratorProject _project;
  final PillarInfo? _pillarInfo;
  final int? _activePillarCount;
  final RefreshProjectBloc? _refreshProjectBloc;

  @override
  Widget build(BuildContext context) {
    final RefreshProjectBloc? providedBloc = _refreshProjectBloc;
    final Widget view = _View(
      pillarInfo: _pillarInfo,
      activePillarCount: _activePillarCount,
      onStepperNotificationSeeMorePressed: _onStepperNotificationSeeMorePressed,
    );

    if (providedBloc != null) {
      return BlocProvider<RefreshProjectBloc>.value(
        value: providedBloc,
        child: view,
      );
    }

    return BlocProvider<RefreshProjectBloc>(
      create: (_) =>
          RefreshProjectBloc(zenon: zenon!)
            ..add(RefreshProjectRequested(projectId: _project.id)),
      child: view,
    );
  }
}

class _View extends StatelessWidget {
  const _View({
    required this._pillarInfo,
    required this._onStepperNotificationSeeMorePressed,
    this._activePillarCount,
  });

  final VoidCallback _onStepperNotificationSeeMorePressed;
  final PillarInfo? _pillarInfo;
  final int? _activePillarCount;

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: context.newThemeData,
      child: Scaffold(
        body: SafeArea(
          child: Container(
            margin: const EdgeInsets.only(left: 20, right: 20, bottom: 20),
            child: Column(
              children: <Widget>[
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: <Widget>[
                    IconButton(
                      splashRadius: 20,
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.clear),
                    ),
                  ],
                ),
                NotificationWidget(
                  onSeeMorePressed: _onStepperNotificationSeeMorePressed,
                ),
                Expanded(
                  child: BlocBuilder<RefreshProjectBloc, RefreshProjectState>(
                    builder: (BuildContext context, RefreshProjectState state) {
                      return switch (state) {
                        RefreshProjectInitial() ||
                        RefreshProjectLoading() => const SyriusLoadingWidget(),
                        RefreshProjectFailure(
                          :final SyriusException exception,
                        ) =>
                          SyriusErrorWidget(exception),
                        RefreshProjectPopulated(:final Project project) =>
                          _buildScreenLayout(context, project),
                      };
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  StandardFluidLayout _buildScreenLayout(
    BuildContext context,
    Project project,
  ) {
    final bool isProjectOwner = project.owner.toString() == kSelectedAddress;

    void refreshProject() {
      if (context.mounted) {
        context.read<RefreshProjectBloc>().add(
          RefreshProjectRequested(projectId: project.id),
        );
      }
    }

    return StandardFluidLayout(
      children: <FluidCell>[
        FluidCell(
          width: isProjectOwner
              ? context.layout.value(
                  xl: kStaggeredNumOfColumns ~/ 2,
                  lg: kStaggeredNumOfColumns ~/ 2,
                  md: kStaggeredNumOfColumns ~/ 2,
                  sm: kStaggeredNumOfColumns,
                  xs: kStaggeredNumOfColumns,
                )
              : kStaggeredNumOfColumns,
          child: ProjectStatsCard(project: project),
        ),
        if (isProjectOwner)
          FluidCell(
            width: context.layout.value(
              xl: kStaggeredNumOfColumns ~/ 2,
              lg: kStaggeredNumOfColumns ~/ 2,
              md: kStaggeredNumOfColumns ~/ 2,
              sm: kStaggeredNumOfColumns,
              xs: kStaggeredNumOfColumns,
            ),
            child: CreatePhaseCard(
              project: project,
              onPhaseCreated: refreshProject,
              onStepperNotificationSeeMorePressed:
                  _onStepperNotificationSeeMorePressed,
            ),
          ),
        FluidCell(
          width: kStaggeredNumOfColumns,
          height: kStaggeredNumOfColumns / 2,
          child: PhaseListCard(
            pillarInfo: _pillarInfo,
            activePillarCount: _activePillarCount,
            project: project,
            onRefreshButtonPressed: refreshProject,
            onPhaseUpdated: refreshProject,
            onStepperNotificationSeeMorePressed:
                _onStepperNotificationSeeMorePressed,
          ),
        ),
      ],
    );
  }
}
