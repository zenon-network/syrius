import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:stacked/stacked.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/screens/screens.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class AcceleratorProjectListItem extends StatefulWidget {
  final AcceleratorProject acceleratorProject;
  final PillarInfo? pillarInfo;
  final Project? project;
  final VoidCallback onStepperNotificationSeeMorePressed;

  const AcceleratorProjectListItem({
    Key? key,
    required this.acceleratorProject,
    this.pillarInfo,
    this.project,
    required this.onStepperNotificationSeeMorePressed,
  }) : super(key: key);

  @override
  State<AcceleratorProjectListItem> createState() =>
      _AcceleratorProjectListItemState();
}

class _AcceleratorProjectListItemState
    extends State<AcceleratorProjectListItem> {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      hoverColor: Colors.transparent,
      splashColor: Colors.transparent,
      onTap: widget.acceleratorProject is Project
          ? () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProjectDetailsScreen(
                    pillarInfo: widget.pillarInfo,
                    project: widget.acceleratorProject,
                    onStepperNotificationSeeMorePressed:
                        widget.onStepperNotificationSeeMorePressed,
                  ),
                ),
              );
            }
          : null,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 20.0,
          vertical: 10.0,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(
            10.0,
          ),
          color: Theme.of(context).colorScheme.primaryContainer,
        ),
        child: Column(
          children: [
            _getProjectTitle(context),
            const SizedBox(
              height: 10.0,
            ),
            AcceleratorProjectDetails(
              owner: widget.acceleratorProject is Project
                  ? (widget.acceleratorProject as Project).owner
                  : null,
              hash: widget.acceleratorProject.id,
              creationTimestamp: widget.acceleratorProject.creationTimestamp,
              acceleratorProjectStatus: widget.acceleratorProject.status,
            ),
            const SizedBox(
              height: 10.0,
            ),
            _getProjectDescription(context),
            const SizedBox(
              height: 10.0,
            ),
            _getProjectStatuses(context),
            const SizedBox(
              height: 10.0,
            ),
            _getProjectVoteBreakdownViewModel(context),
          ],
        ),
      ),
    );
  }

  Row _getVotingRow(
    BuildContext context,
    VoteBreakdown voteBreakdown,
    List<PillarVote?>? pillarVoteList,
    ProjectVoteBreakdownBloc projectVoteBreakdownViewModel,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Visibility(
          visible: voteBreakdown.total > 0,
          child: _getVotingResults(context, voteBreakdown),
        ),
        _getVotingResultsIcon(
          context,
          pillarVoteList,
          projectVoteBreakdownViewModel,
        ),
      ],
    );
  }

  Widget _getProjectTitle(BuildContext context) {
    return Row(
      children: [
        Text(
          widget.acceleratorProject.name,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ],
    );
  }

  Widget _getProjectDescription(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            widget.acceleratorProject.description,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ],
    );
  }

  Widget _getProjectStatuses(BuildContext context) {
    List<Widget> tags = [
      _getProjectStatusTag(),
    ];

    if (widget.acceleratorProject.znnFundsNeeded > BigInt.zero) {
      tags.add(
        _getProjectZnnFundsNeededTag(context),
      );
    }

    if (widget.acceleratorProject.qsrFundsNeeded > BigInt.zero) {
      tags.add(
        _getProjectQsrFundsNeededTag(context),
      );
    }

    if (widget.acceleratorProject is Project &&
        (widget.acceleratorProject as Project).phases.isNotEmpty &&
        (widget.acceleratorProject as Project).phases.last.status ==
            AcceleratorProjectStatus.voting) {
      tags.add(
        TagWidget(
          text: 'Phase needs voting',
          hexColorCode:
              AppColors.znnColor.withOpacity(0.7).value.toRadixString(16),
        ),
      );
    }

    return Row(
      children: tags.zip(
        List.generate(
          tags.length - 1,
          (index) => const SizedBox(
            width: 5.0,
          ),
        ),
      ),
    );
  }

  TagWidget _getProjectStatusTag() {
    if (widget.acceleratorProject.status == AcceleratorProjectStatus.closed) {
      return TagWidget(
        text: 'Rejected',
        hexColorCode: AppColors.errorColor.value.toRadixString(16).substring(2),
      );
    }
    if (widget.acceleratorProject.status == AcceleratorProjectStatus.active) {
      return TagWidget(
        text: 'Accepted',
        hexColorCode: AppColors.znnColor.value.toRadixString(16),
      );
    }
    if (widget.acceleratorProject.status == AcceleratorProjectStatus.voting) {
      return TagWidget(
        text: 'Voting open',
        iconData: MaterialCommunityIcons.vote,
        hexColorCode:
            AppColors.znnColor.withOpacity(0.7).value.toRadixString(16),
      );
    }
    if (widget.acceleratorProject.status == AcceleratorProjectStatus.paid) {
      return TagWidget(
        text: 'Paid',
        hexColorCode: AppColors.alertNotification.value.toRadixString(16),
      );
    }
    if (widget.acceleratorProject.status ==
        AcceleratorProjectStatus.completed) {
      return TagWidget(
        text: 'Completed',
        hexColorCode: AppColors.qsrColor.value.toRadixString(16),
      );
    }
    return const TagWidget(
      text: 'Wrong status',
    );
  }

  TagWidget _getProjectZnnFundsNeededTag(BuildContext context) {
    return TagWidget(
      text:
          '${widget.acceleratorProject.znnFundsNeeded.addDecimals(coinDecimals)} ${kZnnCoin.symbol}',
      hexColorCode:
          Theme.of(context).colorScheme.secondary.value.toRadixString(16),
    );
  }

  TagWidget _getProjectQsrFundsNeededTag(BuildContext context) {
    return TagWidget(
      text:
          '${widget.acceleratorProject.qsrFundsNeeded.addDecimals(coinDecimals)} ${kQsrCoin.symbol}',
      hexColorCode:
          Theme.of(context).colorScheme.secondary.value.toRadixString(16),
    );
  }

  Widget _getVotingResults(
    BuildContext context,
    VoteBreakdown voteBreakdown,
  ) {
    int yesVotes = voteBreakdown.yes;
    int noVotes = voteBreakdown.no;
    int quorum = voteBreakdown.total;
    int quorumNeeded = (kNumOfPillars! * 0.33).ceil();
    int votesToAchieveQuorum = quorumNeeded - quorum;
    int pillarsThatCanStillVote = kNumOfPillars! -
        quorum -
        (votesToAchieveQuorum > 0 ? votesToAchieveQuorum : 0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Text('Voting results'),
          ],
        ),
        kVerticalSpacing,
        Row(
          children: [
            AcceleratorProgressBar(
              context: context,
              child: Row(
                children: [
                  AcceleratorProgressBarSpan(
                    value: yesVotes / (yesVotes + noVotes),
                    color: AppColors.znnColor,
                    tooltipMessage: '$yesVotes Yes votes',
                  ),
                  AcceleratorProgressBarSpan(
                    value: noVotes / (yesVotes + noVotes),
                    color: AppColors.errorColor,
                    tooltipMessage: '$noVotes No votes',
                  ),
                ],
              ),
            ),
            const SizedBox(
              width: 10.0,
            ),
            Tooltip(
              message: yesVotes > noVotes
                  ? 'More yes than no votes'
                  : 'Not enough yes votes',
              child: Icon(
                Icons.check_circle,
                color: yesVotes > noVotes
                    ? AppColors.znnColor
                    : Theme.of(context).colorScheme.secondary,
                size: 15.0,
              ),
            ),
          ],
        ),
        const SizedBox(
          height: 10.0,
        ),
        Row(
          children: [
            AcceleratorProgressBar(
                context: context,
                child: Row(
                  children: [
                    AcceleratorProgressBarSpan(
                      value: quorum / kNumOfPillars!,
                      color: AppColors.qsrColor,
                      tooltipMessage: '${voteBreakdown.total} votes in total',
                    ),
                    if (votesToAchieveQuorum > 0)
                      AcceleratorProgressBarSpan(
                        value: votesToAchieveQuorum / kNumOfPillars!,
                        color: AppColors.alertNotification,
                        tooltipMessage:
                            '$votesToAchieveQuorum more votes needed to achieve quorum',
                      ),
                    AcceleratorProgressBarSpan(
                      value: pillarsThatCanStillVote / kNumOfPillars!,
                      color: Colors.transparent,
                      tooltipMessage:
                          '$pillarsThatCanStillVote Pillars that can still cast a vote',
                    ),
                  ],
                )),
            const SizedBox(
              width: 10.0,
            ),
            Tooltip(
              message: quorum >= quorumNeeded
                  ? 'Quorum achieved'
                  : 'Quorum not achieved',
              child: Icon(
                Icons.check_circle,
                color: quorum >= quorumNeeded
                    ? AppColors.znnColor
                    : Theme.of(context).colorScheme.secondary,
                size: 15.0,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _getOpenLinkIcon(BuildContext context) {
    return RawMaterialButton(
      constraints: const BoxConstraints(
        minWidth: 50.0,
        minHeight: 50.0,
      ),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      shape: const CircleBorder(),
      onPressed: () => NavigationUtils.openUrl(widget.acceleratorProject.url),
      child: Tooltip(
        message: 'Visit ${widget.acceleratorProject.url}',
        child: Container(
          height: 50.0,
          width: 50.0,
          padding: const EdgeInsets.all(4),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white12,
          ),
          child: const Icon(
            Icons.open_in_new,
            size: 25.0,
            color: AppColors.znnColor,
          ),
        ),
      ),
    );
  }

  Widget _getVotingResultsIcon(
    BuildContext context,
    List<PillarVote?>? pillarVoteList,
    ProjectVoteBreakdownBloc projectVoteBreakdownViewModel,
  ) {
    return Row(
      children: [
        if (pillarVoteList != null &&
            ((widget.acceleratorProject is Phase &&
                    (widget.acceleratorProject as Phase).status ==
                        AcceleratorProjectStatus.active) ||
                widget.acceleratorProject.status ==
                    AcceleratorProjectStatus.voting))
          _getVoteProjectViewModel(
            context,
            pillarVoteList,
            projectVoteBreakdownViewModel,
          ),
        if ([
          AcceleratorProjectStatus.voting,
          AcceleratorProjectStatus.active,
          AcceleratorProjectStatus.paid,
        ].contains(widget.acceleratorProject.status))
          Row(
            children: [
              const SizedBox(
                width: 10.0,
              ),
              _getOpenLinkIcon(context),
            ],
          ),
        if (widget.acceleratorProject is Phase &&
            widget.acceleratorProject.status ==
                AcceleratorProjectStatus.voting &&
            widget.project!.owner.toString() == kSelectedAddress)
          Row(
            children: [
              const SizedBox(
                width: 10.0,
              ),
              _getUpdatePhaseIcon(context),
            ],
          )
      ],
    );
  }

  Widget _getVotingIcons(
    BuildContext context,
    VoteProjectBloc model,
    List<PillarVote?> pillarVoteList,
  ) {
    return Row(
      children: [
        Tooltip(
          message: 'No',
          child: RawMaterialButton(
            constraints: const BoxConstraints(
              minWidth: 50.0,
              minHeight: 50.0,
            ),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: const CircleBorder(),
            onPressed: () {
              model.voteProject(
                  widget.acceleratorProject.id, AcceleratorProjectVote.no);
            },
            child: Container(
              height: 50.0,
              width: 50.0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _ifOptionVotedByUser(
                        pillarVoteList, AcceleratorProjectVote.no)
                    ? AppColors.errorColor
                    : Theme.of(context).colorScheme.secondary,
              ),
              child: Icon(
                Icons.close_rounded,
                size: 35.0,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ),
        const SizedBox(
          width: 10.0,
        ),
        Tooltip(
          message: 'Yes',
          child: RawMaterialButton(
            constraints: const BoxConstraints(
              minWidth: 50.0,
              minHeight: 50.0,
            ),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: const CircleBorder(),
            onPressed: () {
              model.voteProject(
                  widget.acceleratorProject.id, AcceleratorProjectVote.yes);
            },
            child: Container(
              height: 50.0,
              width: 50.0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _ifOptionVotedByUser(
                        pillarVoteList, AcceleratorProjectVote.yes)
                    ? AppColors.znnColor
                    : Theme.of(context).colorScheme.secondary,
              ),
              child: Icon(
                Icons.check_rounded,
                size: 35.0,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ),
        const SizedBox(
          width: 10.0,
        ),
        Tooltip(
          message: 'Abstain',
          child: RawMaterialButton(
            constraints: const BoxConstraints(
              minWidth: 50.0,
              minHeight: 50.0,
            ),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            shape: const CircleBorder(),
            onPressed: () {
              model.voteProject(
                widget.acceleratorProject.id,
                AcceleratorProjectVote.abstain,
              );
            },
            child: Container(
              height: 50.0,
              width: 50.0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _ifOptionVotedByUser(
                  pillarVoteList,
                  AcceleratorProjectVote.abstain,
                )
                    ? Theme.of(context).primaryColorLight
                    : Theme.of(context).colorScheme.secondary,
              ),
              child: Icon(
                Icons.stop,
                size: 35.0,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _getUpdatePhaseIcon(BuildContext context) {
    return Tooltip(
      message: 'Update phase',
      child: RawMaterialButton(
        constraints: const BoxConstraints(
          minWidth: 50.0,
          minHeight: 50.0,
        ),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: const CircleBorder(),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => StepperScreen(
                stepper: UpdatePhaseStepper(
                  widget.acceleratorProject as Phase,
                  widget.project!,
                ),
                onStepperNotificationSeeMorePressed:
                    widget.onStepperNotificationSeeMorePressed,
              ),
            ),
          );
        },
        child: Container(
          height: 50.0,
          width: 50.0,
          padding: const EdgeInsets.all(4),
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white12,
          ),
          child: const Icon(
            Icons.edit,
            size: 25.0,
            color: AppColors.znnColor,
          ),
        ),
      ),
    );
  }

  Widget _getVoteProjectViewModel(
    BuildContext context,
    List<PillarVote?> pillarVoteList,
    ProjectVoteBreakdownBloc projectVoteBreakdownViewModel,
  ) {
    return ViewModelBuilder<VoteProjectBloc>.reactive(
      onViewModelReady: (model) {
        model.stream.listen((event) {
          if (event != null) {
            projectVoteBreakdownViewModel.getVoteBreakdown(
              widget.pillarInfo?.name,
              widget.acceleratorProject.id,
            );
          }
        }, onError: (error) {
          NotificationUtils.sendNotificationError(
            error,
            'Error while voting project',
          );
        });
      },
      builder: (_, model, __) => StreamBuilder<AccountBlockTemplate?>(
          stream: model.stream,
          builder: (_, snapshot) {
            if (snapshot.hasError) {
              return _getVotingIcons(context, model, pillarVoteList);
            }
            if (snapshot.connectionState == ConnectionState.active) {
              if (snapshot.hasData) {
                return _getVotingIcons(context, model, pillarVoteList);
              }
              return const SyriusLoadingWidget();
            }
            return _getVotingIcons(context, model, pillarVoteList);
          }),
      viewModelBuilder: () => VoteProjectBloc(),
    );
  }

  Widget _getProjectVoteBreakdownViewModel(BuildContext context) {
    return ViewModelBuilder<ProjectVoteBreakdownBloc>.reactive(
      onViewModelReady: (model) {
        model.getVoteBreakdown(
            widget.pillarInfo?.name, widget.acceleratorProject.id);
        model.stream.listen((event) {}, onError: (error) {
          NotificationUtils.sendNotificationError(
            error,
            'Error while trying to get the vote breakdown',
          );
        });
      },
      builder: (_, model, __) =>
          StreamBuilder<Pair<VoteBreakdown, List<PillarVote?>?>?>(
        stream: model.stream,
        builder: (_, snapshot) {
          if (snapshot.hasError) {
            return SyriusErrorWidget(snapshot.error!);
          }
          if (snapshot.connectionState == ConnectionState.active) {
            if (snapshot.hasData) {
              return _getVotingRow(
                context,
                snapshot.data!.first,
                snapshot.data!.second,
                model,
              );
            }
            return const SyriusLoadingWidget();
          }
          return const SyriusLoadingWidget();
        },
      ),
      viewModelBuilder: () => ProjectVoteBreakdownBloc(),
    );
  }

  bool _ifOptionVotedByUser(
      List<PillarVote?> pillarVoteList, AcceleratorProjectVote vote) {
    try {
      PillarVote? pillarVote = pillarVoteList.firstWhere(
        (pillarVote) => pillarVote?.name == widget.pillarInfo!.name,
      );
      return pillarVote!.vote == vote.index;
    } catch (e) {
      return false;
    }
  }
}
