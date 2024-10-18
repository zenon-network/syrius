import 'dart:isolate';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:hive/hive.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/embedded_node/embedded_node.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/services/i_web3wallet_service.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class NodeManagement extends StatefulWidget {

  const NodeManagement({
    required this.onNodeChangedCallback,
    super.key,
  });
  final VoidCallback onNodeChangedCallback;

  @override
  State<NodeManagement> createState() => _NodeManagementState();
}

class _NodeManagementState extends State<NodeManagement> {
  String? _selectedNode;

  final GlobalKey<LoadingButtonState> _confirmNodeButtonKey = GlobalKey();
  final GlobalKey<LoadingButtonState> _addNodeButtonKey = GlobalKey();
  final GlobalKey<LoadingButtonState> _confirmChainIdButtonKey = GlobalKey();

  TextEditingController _newNodeController = TextEditingController();
  GlobalKey<FormState> _newNodeKey = GlobalKey();

  TextEditingController _newChainIdController = TextEditingController();
  GlobalKey<FormState> _newChainIdKey = GlobalKey();

  late String _selectedNodeConfirmed;
  late int _currentChainId;

  int get _newChainId => int.parse(_newChainIdController.text);

  @override
  void initState() {
    super.initState();
    kDefaultCommunityNodes.shuffle();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _selectedNode ??= kCurrentNode!;
    _selectedNodeConfirmed = _selectedNode!;
    _initCurrentChainId();
  }

  void _initCurrentChainId() {
    _currentChainId = sharedPrefsService!.get(
      kChainIdKey,
      defaultValue: kChainIdDefaultValue,
    );
  }

  @override
  Widget build(BuildContext context) {
    return CardScaffold(
      title: 'Node Management',
      description:
          'This card allows one to set the ZNN Node used to connect to. '
          'By default the wallet is connected to the Embedded Node. '
          'If you are running a local ZNN Node, please use the localhost option',
      childBuilder: _getWidgetBody,
    );
  }

  Widget _getWidgetBody() {
    return ListView(
      shrinkWrap: true,
      children: [
        CustomExpandablePanel(
          'Client chain identifier selection',
          _getChainIdSelectionExpandableChild(),
        ),
        CustomExpandablePanel(
          'Node selection',
          _getNodeSelectionExpandableChild(),
        ),
        CustomExpandablePanel(
          'Add node',
          _getAddNodeExpandableChild(),
        ),
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

  Row _getConfirmNodeSelectionButton() {
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
    if (!await WakelockPlus.enabled) {
      WakelockPlus.enable();
    }

    try {
      _confirmNodeButtonKey.currentState?.animateForward();
      final isConnectionEstablished =
          await _establishConnectionToNode(_selectedNode);
      if (isConnectionEstablished) {
        kNodeChainId = await NodeUtils.getNodeChainIdentifier();
        if (await _checkForChainIdMismatch()) {
          await htlcSwapsService!.storeLastCheckedHtlcBlockHeight(0);
          await sharedPrefsService!.put(
            kSelectedNodeKey,
            _selectedNode,
          );
          kCurrentNode = _selectedNode;
          await _sendChangingNodeSuccessNotification();
          widget.onNodeChangedCallback();
        } else {
          await _establishConnectionToNode(kCurrentNode);
          kNodeChainId = await NodeUtils.getNodeChainIdentifier();
          setState(() {
            _selectedNode = kCurrentNode;
          });
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

  Future<bool> _establishConnectionToNode(String? url) async {
    final targetUrl = url == kEmbeddedNode ? kLocalhostDefaultNodeUrl : url!;
    var isConnectionEstablished =
        await NodeUtils.establishConnectionToNode(targetUrl);
    if (url == kEmbeddedNode) {
      // Check if node is already running
      if (!isConnectionEstablished) {
        // Initialize local full node
        await Isolate.spawn(EmbeddedNode.runNode, [''],
            onExit:
                sl<ReceivePort>(instanceName: 'embeddedStoppedPort').sendPort,);
        kEmbeddedNodeRunning = true;
        // The node needs a couple of seconds to actually start
        await Future.delayed(kEmbeddedConnectionDelay);
        isConnectionEstablished =
            await NodeUtils.establishConnectionToNode(targetUrl);
      }
    } else {
      isConnectionEstablished =
          await NodeUtils.establishConnectionToNode(targetUrl);
      if (isConnectionEstablished) {
        await NodeUtils.closeEmbeddedNode();
      }
    }
    return isConnectionEstablished;
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
      _newNodeController = TextEditingController();
      _newNodeKey = GlobalKey();
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
    _newChainIdController.dispose();
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

  Widget _getChainIdSelectionExpandableChild() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
                child: Form(
              key: _newChainIdKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: InputField(
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                controller: _newChainIdController,
                hintText:
                    'Current client chain identifier is ${getChainIdentifier()}',
                onSubmitted: (value) async {
                  if (_isChainIdSelectionInputIsValid()) {
                    _onConfirmChainIdPressed();
                  }
                },
                onChanged: (String value) {
                  if (value.isNotEmpty) {
                    setState(() {});
                  }
                },
                validator: InputValidators.validateNumber,
              ),
            ),),
            StandardTooltipIcon(
              (getChainIdentifier() == 1)
                  ? 'Alphanet chain identifier'
                  : 'Non-alphanet chain identifier',
              MaterialCommunityIcons.network,
              iconColor: (getChainIdentifier() == 1)
                  ? AppColors.znnColor
                  : Colors.orange,
            ),
            const StandardTooltipIcon(
              'The chain identifier is used in transaction signing to prevent replay attacks',
              MaterialCommunityIcons.alert,
              iconColor: Colors.orange,
            ),
          ],
        ),
        kVerticalSpacing,
        LoadingButton.settings(
          onPressed: _isChainIdSelectionInputIsValid()
              ? _onConfirmChainIdPressed
              : null,
          text: 'Confirm',
          key: _confirmChainIdButtonKey,
        ),
      ],
    );
  }

  bool _isChainIdSelectionInputIsValid() =>
      InputValidators.validateNumber(_newChainIdController.text) == null &&
      _newChainId != _currentChainId;

  Future<void> _onConfirmChainIdPressed() async {
    try {
      _confirmChainIdButtonKey.currentState?.animateForward();
      setChainIdentifier(chainIdentifier: _newChainId);
      await sharedPrefsService!.put(kChainIdKey, _newChainId);
      await sl<IWeb3WalletService>().emitChainIdChangeEvent(_newChainId.toString());
      await _sendSuccessfullyChangedChainIdNotification(_newChainId);
      _initCurrentChainId();
      _newChainIdController = TextEditingController();
      _newChainIdKey = GlobalKey();
    } catch (e) {
      await NotificationUtils.sendNotificationError(
        e,
        'Error while setting the new client chain identifier',
      );
    } finally {
      _confirmChainIdButtonKey.currentState?.animateReverse();
    }
  }

  Future<void> _sendSuccessfullyChangedChainIdNotification(int newChainId) async {
    await sl.get<NotificationsBloc>().addNotification(
          WalletNotification(
            title:
                'Successfully changed client chain identifier to $newChainId',
            timestamp: DateTime.now().millisecondsSinceEpoch,
            details:
                'Successfully changed client chain identifier from $_currentChainId to $_newChainId',
            type: NotificationType.changedNode,
          ),
        );
  }

  Future<bool> _checkForChainIdMismatch() async {
    var match = false;
    await zenon!.ledger.getFrontierMomentum().then((momentum) async {
      final nodeChainId = momentum.chainIdentifier;
      if (nodeChainId != _currentChainId) {
        match = await _showChainIdWarningDialog(nodeChainId, _currentChainId);
      } else {
        match = true;
      }
    });
    return match;
  }

  Future<bool> _showChainIdWarningDialog(
      int nodeChainId, int currentChainId,) async {
    return showWarningDialog(
      context: context,
      title: 'Chain identifier mismatch',
      buttonText: 'Proceed anyway',
      description:
          'The node $_selectedNode you are connecting to has a different '
          'chain identifier $nodeChainId than the current client chain identifier $currentChainId',
    );
  }
}
