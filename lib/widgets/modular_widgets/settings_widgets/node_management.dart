import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:wakelock/wakelock.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/notifications_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/embedded_node/embedded_node.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/model/database/notification_type.dart';
import 'package:zenon_syrius_wallet_flutter/model/database/wallet_notification.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:zenon_syrius_wallet_flutter/utils/input_validators.dart';
import 'package:zenon_syrius_wallet_flutter/utils/node_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/notification_utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/buttons/loading_button.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/custom_expandable_panel.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/input_field/input_field.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/layout_scaffold/card_scaffold.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/settings_node.dart';

class NodeManagement extends StatefulWidget {
  final VoidCallback onNodeChangedCallback;

  const NodeManagement({
    required this.onNodeChangedCallback,
    Key? key,
  }) : super(key: key);

  @override
  _NodeManagementState createState() => _NodeManagementState();
}

class _NodeManagementState extends State<NodeManagement> {
  String? _selectedNode;

  final GlobalKey<LoadingButtonState> _confirmNodeButtonKey = GlobalKey();
  final GlobalKey<LoadingButtonState> _addNodeButtonKey = GlobalKey();

  TextEditingController _newNodeController = TextEditingController();
  GlobalKey<FormState> _newNodeKey = GlobalKey();

  late String _selectedNodeConfirmed;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _selectedNode ??= kCurrentNode!;
    _selectedNodeConfirmed = _selectedNode!;
  }

  @override
  Widget build(BuildContext context) {
    return CardScaffold(
      title: 'Node Management',
      description:
          'This card allows one to set the ZNN Node used to connect to. '
          'By default the wallet is connected to the embedded node. '
          'If you are running a local ZNN Node, please use the localhost option',
      childBuilder: () => _getWidgetBody(),
    );
  }

  Widget _getWidgetBody() {
    return ListView(
      shrinkWrap: true,
      children: [
        CustomExpandablePanel(
          'Node selection',
          _getNodeSelectionExpandableChild(),
        ),
        CustomExpandablePanel(
          'Add node',
          _getAddNodeExpandableChild(),
        )
      ],
    );
  }

  Widget _getNodeSelectionExpandableChild() {
    return Column(
      children: [
        _getNodeTiles(),
        _getConfirmNodeSelectionButton(),
      ],
    );
  }

  _getConfirmNodeSelectionButton() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        LoadingButton.settings(
          text: 'Confirm node',
          onPressed: _onConfirmNodeButtonPressed,
          key: _confirmNodeButtonKey,
        ),
      ],
    );
  }

  Future<void> _onConfirmNodeButtonPressed() async {
    // Acquire WakeLock
    if (!await Wakelock.enabled) {
      Wakelock.enable();
    }

    try {
      _confirmNodeButtonKey.currentState?.animateForward();
      String url = _selectedNode == 'Embedded Node'
          ? kLocalhostDefaultNodeUrl
          : _selectedNode!;
      bool _isConnectionEstablished =
          await NodeUtils.establishConnectionToNode(url);
      if (_selectedNode == 'Embedded Node') {
        // Check if node is already running
        if (!_isConnectionEstablished) {
          // Initialize local full node
          await Isolate.spawn(EmbeddedNode.runNode, [''],
              onExit: sl<ReceivePort>(instanceName: 'embeddedStoppedPort')
                  .sendPort);
          kEmbeddedNodeRunning = true;
          // The node needs a couple of seconds to actually start
          await Future.delayed(kEmbeddedConnectionDelay);
          _isConnectionEstablished =
              await NodeUtils.establishConnectionToNode(url);
        }
      } else {
        _isConnectionEstablished =
            await NodeUtils.establishConnectionToNode(url);
        if (_isConnectionEstablished) {
          await NodeUtils.closeEmbeddedNode();
        }
      }
      if (_isConnectionEstablished) {
        await sharedPrefsService!.put(
          kSelectedNodeKey,
          _selectedNode,
        );
        kCurrentNode = _selectedNode!;
        _sendChangingNodeSuccessNotification();
        widget.onNodeChangedCallback();
      } else {
        throw 'Connection could not be established to $_selectedNode';
      }
    } catch (e) {
      NotificationUtils.sendNotificationError(
        e,
        'Connection failed',
      );
      setState(() {
        _selectedNode = kCurrentNode!;
      });
    } finally {
      _confirmNodeButtonKey.currentState?.animateReverse();
    }
  }

  Widget _getAddNodeExpandableChild() {
    return Column(
      children: [
        Form(
          key: _newNodeKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: InputField(
            controller: _newNodeController,
            hintText: 'Node address with port',
            onSubmitted: (value) {
              if (_ifUserInputValid()) {
                _onAddNodePressed();
              }
            },
            onChanged: (String value) {
              if (value.isNotEmpty) {
                setState(() {});
              }
            },
            validator: InputValidators.node,
          ),
        ),
        kVerticalSpacing,
        LoadingButton.settings(
          onPressed: _ifUserInputValid() ? _onAddNodePressed : null,
          text: 'Add node',
          key: _addNodeButtonKey,
        ),
      ],
    );
  }

  bool _ifUserInputValid() =>
      InputValidators.node(_newNodeController.text) == null;

  void _onAddNodePressed() async {
    if ([...kDbNodes, ...kDefaultNodes].contains(_newNodeController.text)) {
      NotificationUtils.sendNotificationError(
          'Node already exists', 'Node already exists');
    } else {
      _addNodeToDb();
    }
  }

  Future<void> _addNodeToDb() async {
    try {
      _addNodeButtonKey.currentState?.animateForward();
      if (!Hive.isBoxOpen(kNodesBox)) {
        await Hive.openBox<String>(kNodesBox);
      }
      Hive.box<String>(kNodesBox).add(_newNodeController.text);
      await NodeUtils.loadDbNodes(context);
      _sendAddNodeSuccessNotification();
      _newNodeController = TextEditingController();
      _newNodeKey = GlobalKey();
    } catch (e) {
      NotificationUtils.sendNotificationError(e, 'Error while adding new node');
    } finally {
      _addNodeButtonKey.currentState?.animateReverse();
    }
  }

  Widget _getNodeTiles() {
    return Column(
      children:
          [...kDefaultNodes, ...kDbNodes].map((e) => _getNodeTile(e)).toList(),
    );
  }

  Row _getNodeTile(String node) {
    return Row(
      children: [
        Radio<String?>(
          value: node,
          groupValue: _selectedNode,
          onChanged: (value) {
            setState(() {
              _selectedNode = value;
            });
          },
        ),
        Expanded(
          child: SettingsNode(
            key: ValueKey(node),
            node: node,
            onNodePressed: (value) {
              setState(() {
                _selectedNode = value;
              });
            },
            onChangedOrDeletedNode: () {
              setState(() {});
            },
            currentNode: _selectedNodeConfirmed,
          ),
        ),
      ],
    );
  }

  void _sendChangingNodeSuccessNotification() {
    sl.get<NotificationsBloc>().addNotification(
          WalletNotification(
            title: 'Successfully connected to $_selectedNode',
            timestamp: DateTime.now().millisecondsSinceEpoch,
            details: 'Successfully connected to $_selectedNode',
            type: NotificationType.changedNode,
          ),
        );
  }

  @override
  void dispose() {
    _newNodeController.dispose();
    super.dispose();
  }

  void _sendAddNodeSuccessNotification() {
    sl.get<NotificationsBloc>().addNotification(
          WalletNotification(
            title: 'Successfully added node ${_newNodeController.text}',
            timestamp: DateTime.now().millisecondsSinceEpoch,
            details: 'Successfully added node ${_newNodeController.text}',
            type: NotificationType.changedNode,
          ),
        );
  }
}
