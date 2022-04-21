import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';
import 'package:rxdart/rxdart.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/accelerator/project_list_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/utils/format_utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/modular_widgets/accelerator_widgets/accelerator_project_list_item.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/error_widget.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/input_field/input_field.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/layout_scaffold/card_scaffold.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/loading_widget.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/tag_widget.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

enum ProjectsFilterTag {
  myProjects,
  onlyAccepted,
  votingOpened,
  alreadyVoted,
}

class ProjectList extends StatefulWidget {
  final VoidCallback onStepperNotificationSeeMorePressed;
  final PillarInfo? pillarInfo;

  const ProjectList({
    required this.onStepperNotificationSeeMorePressed,
    required this.pillarInfo,
    Key? key,
  }) : super(key: key);

  @override
  _ProjectListState createState() => _ProjectListState();
}

class _ProjectListState extends State<ProjectList> {
  final ScrollController _scrollController = ScrollController();
  final PagingController<int, Project> _pagingController = PagingController(
    firstPageKey: 0,
  );
  late StreamSubscription _blocListingStateSubscription;
  late ProjectListBloc _bloc;

  final TextEditingController _searchKeyWordController =
      TextEditingController();

  final StreamController<String> _textChangeStreamController =
      StreamController();
  late StreamSubscription _textChangesSubscription;

  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    _bloc = ProjectListBloc(
      pillarInfo: widget.pillarInfo,
    );
    _textChangesSubscription = _textChangeStreamController.stream
        .debounceTime(
          const Duration(seconds: 1),
        )
        .distinct()
        .listen((text) {
      _bloc.onSearchInputChangedSink.add(text);
    });
    _pagingController.addPageRequestListener((pageKey) {
      _bloc.onPageRequestSink.add(pageKey);
    });
    _blocListingStateSubscription = _bloc.onNewListingState.listen(
      (listingState) {
        _pagingController.value = PagingState(
          nextPageKey: listingState.nextPageKey,
          error: listingState.error,
          itemList: listingState.itemList,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return CardScaffold(
      title: 'Project List',
      childBuilder: () => _getInfiniteScrollList(),
      onRefreshPressed: () {
        _searchKeyWordController.clear();
        _bloc.refreshResults();
      },
      description: 'This card displays a list that contains all the projects',
    );
  }

  Widget _getInfiniteScrollList() {
    return Padding(
      padding: const EdgeInsets.all(15.0),
      child: Column(
        children: [
          _getSearchInputField(),
          kVerticalSpacing,
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _getProjectsFilterTags(),
              InkWell(
                onTap: _sortProjectListByLastUpdate,
                child: Icon(
                  Entypo.select_arrows,
                  size: 15.0,
                  color: Theme.of(context).iconTheme.color,
                ),
              ),
            ],
          ),
          kVerticalSpacing,
          Expanded(
            child: Scrollbar(
              controller: _scrollController,
              isAlwaysShown: true,
              child: PagedListView.separated(
                scrollController: _scrollController,
                pagingController: _pagingController,
                separatorBuilder: (_, __) => const SizedBox(
                  height: 15.0,
                ),
                builderDelegate: PagedChildBuilderDelegate<Project>(
                  itemBuilder: (_, project, __) => AcceleratorProjectListItem(
                    key: ValueKey(
                      project.id.toString(),
                    ),
                    pillarInfo: widget.pillarInfo,
                    acceleratorProject: project,
                    onStepperNotificationSeeMorePressed:
                        widget.onStepperNotificationSeeMorePressed,
                  ),
                  firstPageProgressIndicatorBuilder: (_) =>
                      const SyriusLoadingWidget(),
                  firstPageErrorIndicatorBuilder: (_) => SyriusErrorWidget(
                    _pagingController.error,
                  ),
                  newPageProgressIndicatorBuilder: (_) =>
                      const SyriusLoadingWidget(),
                  noMoreItemsIndicatorBuilder: (_) =>
                      const SyriusErrorWidget('No more items'),
                  noItemsFoundIndicatorBuilder: (_) =>
                      const SyriusErrorWidget('No items found'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _getSearchInputField() {
    return InputField(
      controller: _searchKeyWordController,
      hintText: 'Search by id, owner, name, description, or URL',
      suffixIcon: const Icon(
        Icons.search,
        color: Colors.green,
      ),
      onChanged: _textChangeStreamController.add,
    );
  }

  Row _getProjectsFilterTags() {
    List<TagWidget> children = [];

    for (var tag in ProjectsFilterTag.values) {
      if (widget.pillarInfo == null) {
        if ([ProjectsFilterTag.votingOpened, ProjectsFilterTag.alreadyVoted]
            .contains(tag)) {
          continue;
        }
      }
      children.add(_getProjectsFilterTag(tag));
    }

    return Row(
      children: children,
    );
  }

  _getProjectsFilterTag(ProjectsFilterTag filterTag) {
    return TagWidget(
      text: FormatUtils.extractNameFromEnum<ProjectsFilterTag>(filterTag),
      hexColorCode: Theme.of(context)
          .colorScheme
          .primaryContainer
          .value
          .toRadixString(16)
          .substring(2),
      iconData: _bloc.selectedProjectsFilterTag.contains(filterTag)
          ? Icons.check_rounded
          : null,
      onPressed: () {
        setState(() {
          if (_bloc.selectedProjectsFilterTag.contains(filterTag)) {
            _bloc.selectedProjectsFilterTag.remove(filterTag);
          } else {
            _bloc.selectedProjectsFilterTag.add(filterTag);
          }
          _bloc.refreshResults();
        });
      },
    );
  }

  @override
  void dispose() {
    _textChangesSubscription.cancel();
    _blocListingStateSubscription.cancel();
    _bloc.dispose();
    _pagingController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sortProjectListByLastUpdate() {
    if (_pagingController.itemList != null &&
        _pagingController.itemList!.isNotEmpty) {
      _sortAscending
          ? _pagingController.itemList!.sort(
              (a, b) => a.lastUpdateTimestamp.compareTo(b.lastUpdateTimestamp))
          : _pagingController.itemList!.sort(
              (a, b) => b.lastUpdateTimestamp.compareTo(a.lastUpdateTimestamp));
      setState(() {
        _sortAscending = !_sortAscending;
      });
    }
  }
}
