import 'package:flutter/material.dart';
import 'package:layout/layout.dart';
import 'package:stacked/stacked.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class ProjectDetailsScreen extends StatefulWidget {
  final VoidCallback onStepperNotificationSeeMorePressed;
  final AcceleratorProject project;
  final PillarInfo? pillarInfo;

  const ProjectDetailsScreen({
    required this.project,
    required this.pillarInfo,
    required this.onStepperNotificationSeeMorePressed,
    Key? key,
  }) : super(key: key);

  @override
  State<ProjectDetailsScreen> createState() => _ProjectDetailsScreenState();
}

class _ProjectDetailsScreenState extends State<ProjectDetailsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          margin: const EdgeInsets.only(
            left: 20.0,
            right: 20.0,
            bottom: 20.0,
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    splashRadius: 20.0,
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    icon: const Icon(
                      Icons.clear,
                    ),
                  ),
                ],
              ),
              Expanded(
                child: _getStreamBuilder(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  StandardFluidLayout _getScreenLayout(
    BuildContext context,
    Project project,
    RefreshProjectBloc refreshProjectViewModel,
  ) {
    return StandardFluidLayout(
      children: [
        FluidCell(
          width: project.owner.toString() == kSelectedAddress!
              ? context.layout.value(
                  xl: kStaggeredNumOfColumns ~/ 2,
                  lg: kStaggeredNumOfColumns ~/ 2,
                  md: kStaggeredNumOfColumns ~/ 2,
                  sm: kStaggeredNumOfColumns,
                  xs: kStaggeredNumOfColumns,
                )
              : kStaggeredNumOfColumns,
          child: ProjectsStats(project),
        ),
        if (project.owner.toString() == kSelectedAddress!)
          FluidCell(
            width: context.layout.value(
              xl: kStaggeredNumOfColumns ~/ 2,
              lg: kStaggeredNumOfColumns ~/ 2,
              md: kStaggeredNumOfColumns ~/ 2,
              sm: kStaggeredNumOfColumns,
              xs: kStaggeredNumOfColumns,
            ),
            child: CreatePhase(
              project: project,
              onStepperNotificationSeeMorePressed:
                  widget.onStepperNotificationSeeMorePressed,
            ),
          ),
        FluidCell(
          width: kStaggeredNumOfColumns,
          child: PhaseList(
            widget.pillarInfo,
            project,
            () {
              refreshProjectViewModel.refreshProject(project.id);
            },
            onStepperNotificationSeeMorePressed:
                widget.onStepperNotificationSeeMorePressed,
          ),
          height: kStaggeredNumOfColumns / 2,
        ),
      ],
    );
  }

  Widget _getStreamBuilder() {
    return ViewModelBuilder<RefreshProjectBloc>.reactive(
      onViewModelReady: (model) {
        model.refreshProject(widget.project.id);
      },
      builder: (_, model, __) => StreamBuilder<Project?>(
        stream: model.stream,
        builder: (_, snapshot) {
          if (snapshot.hasError) {
            return SyriusErrorWidget(snapshot.error!);
          }
          if (snapshot.connectionState == ConnectionState.active) {
            if (snapshot.hasData) {
              return _getScreenLayout(context, snapshot.data!, model);
            }
            return const SyriusLoadingWidget();
          }
          return const SyriusLoadingWidget();
        },
      ),
      viewModelBuilder: () => RefreshProjectBloc(),
    );
  }
}
