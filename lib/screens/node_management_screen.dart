import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/embedded_node/embedded_node.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

class NodeManagementScreen extends StatefulWidget {
  final VoidCallback? nodeConfirmationCallback;

  static const String route = 'node-management-screen';

  const NodeManagementScreen({
    this.nodeConfirmationCallback,
    Key? key,
  }) : super(key: key);

  @override
  State<NodeManagementScreen> createState() => _NodeManagementScreenState();
}

class _NodeManagementScreenState extends State<NodeManagementScreen> {
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
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 30.0,
          horizontal: 50.0,
        ),
        child: ListView(
          shrinkWrap: true,
          children: [
            const NotificationWidget(),
            Text(
              'Node Management',
              style: Theme.of(context).textTheme.headlineLarge,
              textAlign: TextAlign.center,
            ),
            kVerticalSpacing,
            Text(
              'By default Syrius connects to its own built-in full node, which is called the Embedded Node. If you want to connect to a different node, you can add one below. Otherwise just connect and continue.',
              style: Theme.of(context).textTheme.headlineMedium,
              textAlign: TextAlign.center,
            ),
            SizedBox(
              height: kVerticalSpacing.height! * 2,
            ),
            Row(
              children: [
                const Expanded(
                  child: SizedBox(),
                ),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Node selection',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      _getNodeSelectionColumn(),
                      kVerticalSpacing,
                      Text(
                        'Add node',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      kVerticalSpacing,
                      _getAddNodeColumn(),
                    ],
                  ),
                ),
                const Expanded(
                  child: SizedBox(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _getNodeSelectionColumn() {
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
          text: 'Continue',
          onPressed: _onConfirmNodeButtonPressed,
          key: _confirmNodeButtonKey,
        ),
      ],
    );
  }

  Future<void> _onConfirmNodeButtonPressed() async {
    // Acquire WakeLock
    if (!await WakelockPlus.enabled) {
      WakelockPlus.enable();
    }

    try {
      _confirmNodeButtonKey.currentState?.animateForward();
      String url = _selectedNode == 'Embedded Node'
          ? kLocalhostDefaultNodeUrl
          : _selectedNode!;
      bool isConnectionEstablished =
          await NodeUtils.establishConnectionToNode(url);
      if (_selectedNode == 'Embedded Node') {
        // Check if node is already running
        if (!isConnectionEstablished) {
          // Initialize local full node
          await Isolate.spawn(EmbeddedNode.runNode, [''],
              onExit:
                  sl<ReceivePort>(instanceName: 'embeddedStoppedPort').sendPort,
              debugName: 'EmbeddedNodeIsolate');
          kEmbeddedNodeRunning = true;
          // The node needs a couple of seconds to actually start
          await Future.delayed(kEmbeddedConnectionDelay);
          isConnectionEstablished =
              await NodeUtils.establishConnectionToNode(url);
        }
      } else {
        isConnectionEstablished =
            await NodeUtils.establishConnectionToNode(url);
        if (isConnectionEstablished) {
          await NodeUtils.closeEmbeddedNode();
        }
      }
      if (isConnectionEstablished) {
        await sharedPrefsService!.put(
          kSelectedNodeKey,
          _selectedNode,
        );
        kCurrentNode = _selectedNode!;
        _sendChangingNodeSuccessNotification();
        if (widget.nodeConfirmationCallback != null) {
          widget.nodeConfirmationCallback!();
        } else {
          _navigateToHomeScreen();
        }
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

  void _navigateToHomeScreen() {
    Navigator.of(
      context,
      rootNavigator: true,
    ).pushReplacementNamed(MainAppContainer.route);
  }

  Widget _getAddNodeColumn() {
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
      await NodeUtils.loadDbNodes();
      _sendAddNodeSuccessNotification();
      setState(() {
        _newNodeController = TextEditingController();
        _newNodeKey = GlobalKey();
      });
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
