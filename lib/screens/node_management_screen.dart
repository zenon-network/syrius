import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:logging/logging.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/embedded_node/embedded_node.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

class NodeManagementScreen extends StatefulWidget {

  const NodeManagementScreen({
    this.nodeConfirmationCallback,
    super.key,
  });
  final VoidCallback? nodeConfirmationCallback;

  static const String route = 'node-management-screen';

  @override
  State<NodeManagementScreen> createState() => _NodeManagementScreenState();
}

class _NodeManagementScreenState extends State<NodeManagementScreen> {
  String? _selectedNode;
  bool? _autoReceive;

  final GlobalKey<LoadingButtonState> _confirmNodeButtonKey = GlobalKey();
  final GlobalKey<LoadingButtonState> _addNodeButtonKey = GlobalKey();

  TextEditingController _newNodeController = TextEditingController();
  GlobalKey<FormState> _newNodeKey = GlobalKey();

  late String _selectedNodeConfirmed;

  @override
  void initState() {
    super.initState();
    kDefaultCommunityNodes.shuffle();
    _autoReceive = sharedPrefsService!.get(
      kAutoReceiveKey,
      defaultValue: kAutoReceiveDefaultValue,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _selectedNode ??= kCurrentNode ?? kEmbeddedNode;
    _selectedNodeConfirmed = _selectedNode ?? kEmbeddedNode;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        padding: const EdgeInsets.symmetric(
          vertical: 30,
          horizontal: 50,
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
              'By default Syrius connects to its own built-in full node, which is called the Embedded Node. '
              'It may take up to 24 hours to fully sync the network via the embedded node. '
              'During this time, you cannot send or receive transactions.\n\n'
              'It you want to get started right away, please connect to a community node.',
              style: Theme.of(context).textTheme.headlineSmall,
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
                      _getNodeTiles(),
                      kVerticalSpacing,
                      Text(
                        'Wallet options',
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      _getAutoReceiveCheckboxContainer(),
                      _getConfirmNodeSelectionButton(),
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

  Widget _getAutoReceiveCheckboxContainer() {
    return Row(
      children: <Widget>[
        Checkbox(
          value: _autoReceive,
          checkColor: Theme.of(context).colorScheme.primary,
          activeColor: AppColors.znnColor,
          onChanged: (bool? value) async {
            if (value == true) {
              NodeUtils.getUnreceivedTransactions().then((value) {
                sl<AutoReceiveTxWorker>().autoReceive();
              }).onError((error, stackTrace) {
                Logger('MainAppContainer').log(Level.WARNING,
                    '_getAutoReceiveCheckboxContainer', error, stackTrace,);
              });
            } else if (value == false &&
                sl<AutoReceiveTxWorker>().pool.isNotEmpty) {
              sl<AutoReceiveTxWorker>().pool.clear();
            }
            setState(() {
              _autoReceive = value;
            });
            await _changeAutoReceiveStatus(value ?? false);
          },
        ),
        Text(
          'Automatically receive transactions',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ],
    );
  }

  Future<void> _changeAutoReceiveStatus(bool enabled) async {
    try {
      await _saveAutoReceiveValueToCache(enabled);
      await _sendAutoReceiveNotification(enabled);
    } on Exception catch (e) {
      await NotificationUtils.sendNotificationError(
        e,
        'Something went wrong while setting automatic receive preference',
      );
    }
  }

  Future<void> _sendAutoReceiveNotification(bool enabled) async {
    await sl.get<NotificationsBloc>().addNotification(
          WalletNotification(
            title: 'Auto-receiver ${enabled ? 'enabled' : 'disabled'}',
            details:
                'Auto-receiver preference was ${enabled ? 'enabled' : 'disabled'}',
            timestamp: DateTime.now().millisecondsSinceEpoch,
            type: NotificationType.paymentSent,
          ),
        );
  }

  Future<void> _saveAutoReceiveValueToCache(bool enabled) async {
    await sharedPrefsService!.put(
      kAutoReceiveKey,
      enabled,
    );
  }

  Row _getConfirmNodeSelectionButton() {
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
      final url = _selectedNode == kEmbeddedNode
          ? kLocalhostDefaultNodeUrl
          : _selectedNode!;
      var isConnectionEstablished =
          await NodeUtils.establishConnectionToNode(url);
      if (_selectedNode == kEmbeddedNode) {
        // Check if node is already running
        if (!isConnectionEstablished) {
          // Initialize local full node
          await Isolate.spawn(EmbeddedNode.runNode, [''],
              onExit:
                  sl<ReceivePort>(instanceName: 'embeddedStoppedPort').sendPort,
              debugName: 'EmbeddedNodeIsolate',);
          kEmbeddedNodeRunning = true;
          // The node needs a couple of seconds to actually start
          await Future.delayed(kEmbeddedConnectionDelay);
          isConnectionEstablished =
              await NodeUtils.establishConnectionToNode(url);
        }
      } else {
        if (isConnectionEstablished) {
          await NodeUtils.closeEmbeddedNode();
        }
      }
      if (isConnectionEstablished) {
        await sharedPrefsService!.put(
          kSelectedNodeKey,
          _selectedNode,
        );
        kCurrentNode = _selectedNode;
        await _sendChangingNodeSuccessNotification();
        if (widget.nodeConfirmationCallback != null) {
          widget.nodeConfirmationCallback!();
        } else {
          _navigateToHomeScreen();
        }
      } else {
        throw 'Connection could not be established to $_selectedNode';
      }
    } catch (e) {
      await NotificationUtils.sendNotificationError(
        e,
        'Connection failed',
      );
      setState(() {
        _selectedNode = kCurrentNode;
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

  Future<void> _onAddNodePressed() async {
    if ([...kDbNodes, ...kDefaultCommunityNodes, ...kDefaultNodes]
        .contains(_newNodeController.text)) {
      await NotificationUtils.sendNotificationError(
          'Node ${_newNodeController.text} already exists',
          'Node already exists',);
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
      await _sendAddNodeSuccessNotification();
      setState(() {
        _newNodeController = TextEditingController();
        _newNodeKey = GlobalKey();
      });
    } catch (e) {
      await NotificationUtils.sendNotificationError(e, 'Error while adding new node');
    } finally {
      _addNodeButtonKey.currentState?.animateReverse();
    }
  }

  Widget _getNodeTiles() {
    return Column(
      children: <String>{
        ...kDefaultNodes,
        ...kDefaultCommunityNodes,
        ...kDbNodes,
      }.toList().map(_getNodeTile).toList(),
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

  Future<void> _sendChangingNodeSuccessNotification() async {
    await sl.get<NotificationsBloc>().addNotification(
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

  Future<void> _sendAddNodeSuccessNotification() async {
    await sl.get<NotificationsBloc>().addNotification(
          WalletNotification(
            title: 'Successfully added node ${_newNodeController.text}',
            timestamp: DateTime.now().millisecondsSinceEpoch,
            details: 'Successfully added node ${_newNodeController.text}',
            type: NotificationType.changedNode,
          ),
        );
  }
}
