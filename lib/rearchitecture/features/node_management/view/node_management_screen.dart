import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/node_management/node_management.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

/// Full-screen node selection flow shown during onboarding or when no default
/// node has been selected yet.
class NodeManagementScreen extends StatelessWidget {
  /// Creates a [NodeManagementScreen].
  const NodeManagementScreen({
    this._nodeConfirmationCallback,
    this._bloc,
    super.key,
  });

  /// Named route identifier for [NodeManagementScreen].
  static const String route = 'node-management-screen';

  final VoidCallback? _nodeConfirmationCallback;
  final NodeManagementBloc? _bloc;

  @override
  Widget build(BuildContext context) {
    final NodeManagementBloc? injected = _bloc;
    final Widget view = _View(
      nodeConfirmationCallback: _nodeConfirmationCallback,
    );
    if (injected != null) {
      return BlocProvider<NodeManagementBloc>.value(
        value: injected,
        child: view,
      );
    }

    return BlocProvider<NodeManagementBloc>(
      create: (_) => NodeManagementBloc(
        checkChainIdMismatch: false,
        resetHtlcBlockHeightOnChange: false,
      )..add(const NodeManagementChainIdLoaded()),
      child: view,
    );
  }
}

class _View extends StatefulWidget {
  const _View({this._nodeConfirmationCallback});

  final VoidCallback? _nodeConfirmationCallback;

  @override
  State<_View> createState() => _ViewState();
}

class _ViewState extends State<_View> {
  final GlobalKey<LoadingButtonState> _confirmNodeButtonKey =
      GlobalKey<LoadingButtonState>();
  final GlobalKey<LoadingButtonState> _addNodeButtonKey =
      GlobalKey<LoadingButtonState>();

  final TextEditingController _newNodeController = TextEditingController();
  final GlobalKey<FormState> _newNodeKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MultiBlocListener(
        listeners: <BlocListener<NodeManagementBloc, NodeManagementState>>[
          BlocListener<NodeManagementBloc, NodeManagementState>(
            listenWhen:
                (NodeManagementState previous, NodeManagementState current) =>
                    previous.nodeConfirmedNonce != current.nodeConfirmedNonce,
            listener: (BuildContext context, _) {
              final VoidCallback? callback = widget._nodeConfirmationCallback;
              if (callback != null) {
                callback();
              } else {
                Navigator.of(
                  context,
                  rootNavigator: true,
                ).pushReplacementNamed(MainAppContainer.route);
              }
            },
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
        ],
        child: BlocConsumer<NodeManagementBloc, NodeManagementState>(
          listener: _syncLoadingButtons,
          builder: (BuildContext context, NodeManagementState state) {
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 50),
              child: ListView(
                shrinkWrap: true,
                children: <Widget>[
                  const NotificationWidget(),
                  Text(
                    context.l10n.nodeManagement,
                    style: Theme.of(context).textTheme.headlineLarge,
                    textAlign: TextAlign.center,
                  ),
                  kVerticalSpacing,
                  Text(
                    context.l10n.embeddedNodeSyncExplanation,
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: kVerticalSpacing.height! * 2),
                  Row(
                    children: <Widget>[
                      const Expanded(child: SizedBox()),
                      Expanded(
                        flex: 2,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              context.l10n.nodeSelection,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            _buildNodeTiles(context, state),
                            kVerticalSpacing,
                            Text(
                              context.l10n.walletOptions,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            _buildAutoReceiveCheckbox(context, state),
                            _buildConfirmNodeButton(context, state),
                            kVerticalSpacing,
                            Text(
                              context.l10n.addNode,
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            kVerticalSpacing,
                            _buildAddNodeColumn(context),
                          ],
                        ),
                      ),
                      const Expanded(child: SizedBox()),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

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
  }

  Widget _buildAutoReceiveCheckbox(
    BuildContext context,
    NodeManagementState state,
  ) {
    return Row(
      children: <Widget>[
        Checkbox(
          value: state.autoReceive,
          checkColor: Theme.of(context).colorScheme.primary,
          activeColor: AppColors.znnColor,
          onChanged: (bool? value) {
            final bool enabled = value ?? false;
            final String status = enabled
                ? context.l10n.enabled
                : context.l10n.disabled;
            context.read<NodeManagementBloc>().add(
              NodeManagementAutoReceiveToggled(
                enabled: enabled,
                notificationTitle: context.l10n.autoReceiverStatus(status),
                notificationDetails: context.l10n.autoReceiverPreferenceStatus(
                  status,
                ),
                errorTitle: context.l10n.errorSettingAutoReceivePreference,
              ),
            );
          },
        ),
        Text(
          context.l10n.automaticallyReceiveTransactions,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ],
    );
  }

  Widget _buildConfirmNodeButton(
    BuildContext context,
    NodeManagementState state,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        LoadingButton.settings(
          text: context.l10n.continueText,
          onPressed: () {
            final String selected = state.selectedNode;
            context.read<NodeManagementBloc>().add(
              NodeManagementConfirmNodeRequested(
                successTitle: context.l10n.successfullyConnectedToNode(
                  selected,
                ),
                successDetails: context.l10n.successfullyConnectedToNode(
                  selected,
                ),
                connectionUnavailableMessage: context.l10n
                    .connectionCouldNotBeEstablished(selected),
                connectionFailedTitle: context.l10n.connectionFailed,
              ),
            );
          },
          key: _confirmNodeButtonKey,
        ),
      ],
    );
  }

  Widget _buildAddNodeColumn(BuildContext context) {
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

  @override
  void dispose() {
    _newNodeController.dispose();
    super.dispose();
  }
}
