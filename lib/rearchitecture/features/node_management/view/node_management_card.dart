import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/node_management/node_management.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

/// Displays node selection, custom node management, and client chain
/// identifier configuration inside the Settings tab.
class NodeManagementCard extends StatelessWidget {
  /// Creates a [NodeManagementCard].
  const NodeManagementCard({
    required this._onNodeChangedCallback,
    this._bloc,
    super.key,
  });

  final VoidCallback _onNodeChangedCallback;
  final NodeManagementBloc? _bloc;

  @override
  Widget build(BuildContext context) {
    final NodeManagementBloc? injected = _bloc;
    final Widget view = _View(onNodeChangedCallback: _onNodeChangedCallback);
    if (injected != null) {
      return BlocProvider<NodeManagementBloc>.value(
        value: injected,
        child: view,
      );
    }

    return BlocProvider<NodeManagementBloc>(
      create: (_) => NodeManagementBloc(
        checkChainIdMismatch: true,
        resetHtlcBlockHeightOnChange: true,
      )..add(const NodeManagementChainIdLoaded()),
      child: view,
    );
  }
}

class _View extends StatefulWidget {
  const _View({required this._onNodeChangedCallback});

  final VoidCallback _onNodeChangedCallback;

  @override
  State<_View> createState() => _ViewState();
}

class _ViewState extends State<_View> {
  final GlobalKey<LoadingButtonState> _confirmNodeButtonKey =
      GlobalKey<LoadingButtonState>();
  final GlobalKey<LoadingButtonState> _addNodeButtonKey =
      GlobalKey<LoadingButtonState>();
  final GlobalKey<LoadingButtonState> _confirmChainIdButtonKey =
      GlobalKey<LoadingButtonState>();

  final TextEditingController _newNodeController = TextEditingController();
  final GlobalKey<FormState> _newNodeKey = GlobalKey<FormState>();

  final TextEditingController _newChainIdController = TextEditingController();
  final GlobalKey<FormState> _newChainIdKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return NewCardScaffold(
      data: _buildCardData(context: context),
      body: MultiBlocListener(
        listeners: <BlocListener<NodeManagementBloc, NodeManagementState>>[
          BlocListener<NodeManagementBloc, NodeManagementState>(
            listenWhen:
                (NodeManagementState previous, NodeManagementState current) =>
                    previous.nodeConfirmedNonce != current.nodeConfirmedNonce,
            listener: (_, _) => widget._onNodeChangedCallback(),
          ),
          BlocListener<NodeManagementBloc, NodeManagementState>(
            listenWhen:
                (NodeManagementState previous, NodeManagementState current) =>
                    previous.nodeAddedNonce != current.nodeAddedNonce,
            listener: (_, _) {
              _newNodeController.clear();
              _newNodeKey.currentState?.reset();
              setState(() {});
            },
          ),
          BlocListener<NodeManagementBloc, NodeManagementState>(
            listenWhen:
                (NodeManagementState previous, NodeManagementState current) =>
                    previous.chainIdChangedNonce != current.chainIdChangedNonce,
            listener: (_, _) {
              _newChainIdController.clear();
              _newChainIdKey.currentState?.reset();
              setState(() {});
            },
          ),
          BlocListener<NodeManagementBloc, NodeManagementState>(
            listenWhen:
                (NodeManagementState previous, NodeManagementState current) =>
                    previous.pendingChainIdMismatch == null &&
                    current.pendingChainIdMismatch != null &&
                    !current.pendingChainIdMismatch!.reconnectFailed,
            listener: _onChainIdMismatch,
          ),
        ],
        child: BlocConsumer<NodeManagementBloc, NodeManagementState>(
          listener: _syncLoadingButtons,
          builder: (BuildContext context, NodeManagementState state) {
            return ListView(
              shrinkWrap: true,
              children: <Widget>[
                CustomExpandablePanel(
                  context.l10n.clientChainIdentifierSelection,
                  _buildChainIdPanel(context, state),
                ),
                CustomExpandablePanel(
                  context.l10n.nodeSelection,
                  _buildNodeSelectionPanel(context, state),
                ),
                CustomExpandablePanel(
                  context.l10n.addNode,
                  _buildAddNodePanel(context),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  CardData _buildCardData({required BuildContext context}) => CardData(
    title: context.l10n.nodeManagement,
    description: context.l10n.setZnnNodeToConnect,
  );

  void _syncLoadingButtons(BuildContext context, NodeManagementState state) {
    if (state.isConfirmingNode) {
      _confirmNodeButtonKey.currentState?.animateForward();
    } else {
      _confirmNodeButtonKey.currentState?.animateReverse();
    }
    if (state.isAddingNode) {
      _addNodeButtonKey.currentState?.animateForward();
    } else {
      _addNodeButtonKey.currentState?.animateReverse();
    }
    if (state.isConfirmingChainId) {
      _confirmChainIdButtonKey.currentState?.animateForward();
    } else {
      _confirmChainIdButtonKey.currentState?.animateReverse();
    }
  }

  void _onChainIdMismatch(BuildContext context, NodeManagementState state) {
    final NodeChainIdMismatchPrompt? prompt = state.pendingChainIdMismatch;
    if (prompt == null) {
      return;
    }
    unawaited(_showChainIdWarningAndResolve(context, prompt));
  }

  Future<void> _showChainIdWarningAndResolve(
    BuildContext context,
    NodeChainIdMismatchPrompt prompt,
  ) async {
    final bool proceed = await showWarningDialog(
      context: context,
      title: context.l10n.chainIdentifierMismatch,
      buttonText: context.l10n.proceedAnyway,
      description: context.l10n.nodeHasDifferentChainIdentifier(
        prompt.node,
        prompt.nodeChainId,
        prompt.clientChainId,
      ),
    );
    if (!context.mounted) {
      return;
    }
    context.read<NodeManagementBloc>().add(
      NodeManagementChainIdMismatchResolved(
        proceed: proceed,
        connectionFailedTitle: context.l10n.connectionFailed,
        connectionUnavailableMessage: context.l10n
            .connectionCouldNotBeEstablished(
              proceed ? prompt.node : prompt.previousNode,
            ),
      ),
    );
  }

  Widget _buildNodeSelectionPanel(
    BuildContext context,
    NodeManagementState state,
  ) {
    final NodeChainIdMismatchPrompt? mismatch = state.pendingChainIdMismatch;
    return Column(
      children: <Widget>[
        _buildNodeTiles(context, state),
        if (mismatch != null && mismatch.reconnectFailed)
          _buildReconnectRetryBanner(context, mismatch)
        else if (state.isDisconnected)
          _buildDisconnectedBanner(context),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            LoadingButton.settings(
              text: context.l10n.confirmNode,
              onPressed: () => _onConfirmNodePressed(context, state),
              key: _confirmNodeButtonKey,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReconnectRetryBanner(
    BuildContext context,
    NodeChainIdMismatchPrompt prompt,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: <Widget>[
          Text(
            context.l10n.couldNotReconnectToNode(prompt.previousNode),
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.errorColor),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: <Widget>[
              SettingsButton(
                text: context.l10n.reconnect,
                onPressed: () {
                  context.read<NodeManagementBloc>().add(
                    NodeManagementChainIdMismatchResolved(
                      proceed: false,
                      connectionFailedTitle: context.l10n.connectionFailed,
                      connectionUnavailableMessage: context.l10n
                          .connectionCouldNotBeEstablished(prompt.previousNode),
                    ),
                  );
                },
              ),
              SettingsButton(
                text: context.l10n.proceedAnyway,
                onPressed: () {
                  context.read<NodeManagementBloc>().add(
                    NodeManagementChainIdMismatchResolved(
                      proceed: true,
                      connectionFailedTitle: context.l10n.connectionFailed,
                      connectionUnavailableMessage: context.l10n
                          .connectionCouldNotBeEstablished(prompt.node),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDisconnectedBanner(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        context.l10n.disconnectedFromNode,
        style: Theme.of(
          context,
        ).textTheme.bodySmall?.copyWith(color: AppColors.errorColor),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildNodeTiles(BuildContext context, NodeManagementState state) {
    final NodeManagementBloc bloc = context.read<NodeManagementBloc>();
    return RadioGroup<String>(
      groupValue: state.selectedNode,
      onChanged: (String? value) {
        if (value != null) {
          bloc.add(NodeManagementNodeSelected(node: value));
        }
      },
      child: Column(
        children: state.nodes
            .map((String node) => _buildNodeTile(context, state, node))
            .toList(),
      ),
    );
  }

  Widget _buildNodeTile(
    BuildContext context,
    NodeManagementState state,
    String node,
  ) {
    final NodeManagementBloc bloc = context.read<NodeManagementBloc>();
    return Row(
      children: <Widget>[
        Radio<String>(value: node),
        Expanded(
          child: SettingsNodeTile(
            key: ValueKey<String>(node),
            node: node,
            currentNode: state.confirmedNode,
            clientChainId: state.clientChainId,
            connectedNodeChainId: state.connectedNodeChainId,
            isDefaultNode: bloc.isDefaultNode(node),
            isCommunityNode: bloc.isCommunityNode(node),
            isSavingEdit: state.editingNode == node,
            editError: state.editNodeErrorTarget == node
                ? state.editNodeError
                : null,
            onNodePressed: (String value) {
              bloc.add(NodeManagementNodeSelected(node: value));
            },
            onEditSubmitted: (String newNode) {
              bloc.add(
                NodeManagementEditNodeRequested(
                  oldNode: node,
                  newNode: newNode,
                  emptyErrorMessage: context.l10n.nodeAddressCannotBeEmpty,
                  tooLongErrorMessage: context.l10n.nodeHasTooManyCharacters(
                    kAddressLabelMaxLength,
                  ),
                  duplicateErrorMessage: context.l10n.nodeAlreadyExists,
                  errorTitle: context.l10n.somethingWentWrong,
                ),
              );
            },
            onDeleteConfirmed: () {
              bloc.add(
                NodeManagementDeleteNodeRequested(
                  node: node,
                  errorTitle: context.l10n.errorDeletingNodeFromDatabase(node),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _onConfirmNodePressed(BuildContext context, NodeManagementState state) {
    final String selected = state.selectedNode;
    context.read<NodeManagementBloc>().add(
      NodeManagementConfirmNodeRequested(
        successTitle: context.l10n.successfullyConnectedToNode(selected),
        successDetails: context.l10n.successfullyConnectedToNode(selected),
        connectionUnavailableMessage: context.l10n
            .connectionCouldNotBeEstablished(selected),
        connectionFailedTitle: context.l10n.connectionFailed,
      ),
    );
  }

  Widget _buildAddNodePanel(BuildContext context) {
    return Column(
      children: <Widget>[
        Form(
          key: _newNodeKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: InputField(
            controller: _newNodeController,
            hintText: context.l10n.nodeAddressWithPort,
            onSubmitted: (String value) {
              if (_isNewNodeValid()) {
                _onAddNodePressed(context);
              }
            },
            onChanged: (String value) {
              setState(() {});
            },
            validator: InputValidators.node,
          ),
        ),
        kVerticalSpacing,
        LoadingButton.settings(
          onPressed: _isNewNodeValid()
              ? () => _onAddNodePressed(context)
              : null,
          text: context.l10n.addNode,
          key: _addNodeButtonKey,
        ),
      ],
    );
  }

  bool _isNewNodeValid() =>
      InputValidators.node(_newNodeController.text) == null;

  void _onAddNodePressed(BuildContext context) {
    final String node = _newNodeController.text;
    context.read<NodeManagementBloc>().add(
      NodeManagementAddNodeRequested(
        node: node,
        duplicateDetails: context.l10n.nodeAlreadyExistsNamed(node),
        duplicateTitle: context.l10n.nodeAlreadyExists,
        successTitle: context.l10n.successfullyAddedNode(node),
        successDetails: context.l10n.successfullyAddedNode(node),
        errorTitle: context.l10n.errorAddingNewNode,
      ),
    );
  }

  Widget _buildChainIdPanel(BuildContext context, NodeManagementState state) {
    final bool isAlphanet = state.clientChainId == 1;
    final bool canConfirm = _isChainIdValid(state.clientChainId);

    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Form(
                key: _newChainIdKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: InputField(
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  controller: _newChainIdController,
                  hintText: context.l10n.currentClientChainIdentifier(
                    state.clientChainId,
                  ),
                  onSubmitted: (String value) {
                    if (canConfirm) {
                      _onConfirmChainIdPressed(context, state.clientChainId);
                    }
                  },
                  onChanged: (String value) {
                    setState(() {});
                  },
                  validator: InputValidators.validateNumber,
                ),
              ),
            ),
            StandardTooltipIcon(
              isAlphanet
                  ? context.l10n.alphanetChainIdentifier
                  : context.l10n.nonAlphanetChainIdentifier,
              MaterialCommunityIcons.network,
              iconColor: isAlphanet ? AppColors.znnColor : Colors.orange,
            ),
            StandardTooltipIcon(
              context.l10n.chainIdentifierPreventsReplayAttacks,
              MaterialCommunityIcons.alert,
              iconColor: Colors.orange,
            ),
          ],
        ),
        kVerticalSpacing,
        LoadingButton.settings(
          onPressed: canConfirm
              ? () => _onConfirmChainIdPressed(context, state.clientChainId)
              : null,
          text: context.l10n.confirm,
          key: _confirmChainIdButtonKey,
        ),
      ],
    );
  }

  bool _isChainIdValid(int currentChainId) {
    if (InputValidators.validateNumber(_newChainIdController.text) != null) {
      return false;
    }
    return int.tryParse(_newChainIdController.text) != currentChainId;
  }

  void _onConfirmChainIdPressed(BuildContext context, int currentChainId) {
    final int newChainId = int.parse(_newChainIdController.text);
    context.read<NodeManagementBloc>().add(
      NodeManagementChainIdChanged(
        newChainId: newChainId,
        successTitle: context.l10n.changedClientChainIdentifier(newChainId),
        successDetails: context.l10n.changedClientChainIdentifierFromTo(
          currentChainId,
          newChainId,
        ),
        errorTitle: context.l10n.errorSettingClientChainIdentifier,
      ),
    );
  }

  @override
  void dispose() {
    _newNodeController.dispose();
    _newChainIdController.dispose();
    super.dispose();
  }
}
