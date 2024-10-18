import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:hive/hive.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:zenon_syrius_wallet_flutter/utils/input_validators.dart';
import 'package:zenon_syrius_wallet_flutter/utils/node_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/notification_utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class SettingsNode extends StatefulWidget {

  const SettingsNode({
    required this.node,
    required this.onNodePressed,
    required this.onChangedOrDeletedNode,
    required this.currentNode,
    super.key,
  });
  final String node;
  final void Function(String?) onNodePressed;
  final VoidCallback onChangedOrDeletedNode;
  final String currentNode;

  @override
  State<SettingsNode> createState() => _SettingsNodeState();
}

class _SettingsNodeState extends State<SettingsNode> {
  bool _editable = false;
  String? _nodeError;

  final TextEditingController _nodeController = TextEditingController();

  final GlobalKey<MyOutlinedButtonState> _changeButtonKey = GlobalKey();

  int connectedNodeChainIdentifier = 1;

  @override
  void initState() {
    _nodeController.text = widget.node;

    NodeUtils.getNodeChainIdentifier().then((chainIdentifier) {
      connectedNodeChainIdentifier = chainIdentifier;
      setState(() {});
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        vertical: 5,
      ),
      child: _editable ? _getNodeInputField() : _getNode(context),
    );
  }

  Row _getNode(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(
              10,
            ),
            onTap: () => widget.onNodePressed(widget.node),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _nodeController.text,
                    style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                          color: Theme.of(context)
                              .textTheme
                              .bodyLarge!
                              .color!
                              .withOpacity(0.7),
                        ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Visibility(
            visible: widget.currentNode.contains(widget.node),
            child: StandardTooltipIcon(
                (connectedNodeChainIdentifier == getChainIdentifier())
                    ? 'Client chain identifier: ${getChainIdentifier()}\n'
                        'Node chain identifier: $connectedNodeChainIdentifier'
                    : 'Chain identifier mismatch\n'
                        'Client chain identifier: ${getChainIdentifier()}\n'
                        'Node chain identifier: $connectedNodeChainIdentifier',
                MaterialCommunityIcons.identifier,
                iconColor:
                    (getChainIdentifier() == connectedNodeChainIdentifier)
                        ? AppColors.znnColor
                        : AppColors.errorColor,),),
        Visibility(
          visible: widget.node.contains('wss://'),
          child: const StandardTooltipIcon('Encrypted connection', Icons.lock),
        ),
        Visibility(
          visible: widget.node.contains('ws://'),
          child: const StandardTooltipIcon(
            'Unencrypted connection',
            Icons.lock_open,
            iconColor: AppColors.errorColor,
          ),
        ),
        Visibility(
          visible: widget.node.contains('Embedded'),
          child: const StandardTooltipIcon(
            'Integrated Full Node: enhanced security and privacy',
            MaterialCommunityIcons.security,
          ),
        ),
        Visibility(
          visible: widget.node.contains('Embedded'),
          child: const StandardTooltipIcon(
            'The Embedded Node validates all network transactions\n'
            'It may take several hours to fully sync with the network',
            MaterialCommunityIcons.clock,
            iconColor: Colors.amber,
          ),
        ),
        Visibility(
          visible: kDefaultCommunityNodes.contains(widget.node),
          child: const StandardTooltipIcon(
            'Community Node',
            MaterialCommunityIcons.vector_link,
            iconColor: Colors.amber,
          ),
        ),
        Visibility(
            visible: !kDefaultNodes.contains(widget.node) &&
                !kDefaultCommunityNodes.contains(widget.node),
            child: IconButton(
              hoverColor: Colors.transparent,
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(),
              iconSize: 15,
              icon: const Icon(
                Icons.edit,
                color: AppColors.znnColor,
              ),
              onPressed: () {
                setState(() {
                  _editable = true;
                });
              },
              tooltip: 'Edit node',
            ),),
        Visibility(
            visible: !kDefaultNodes.contains(widget.node) &&
                !kDefaultCommunityNodes.contains(widget.node),
            child: IconButton(
              hoverColor: Colors.transparent,
              padding: const EdgeInsets.all(4),
              constraints: const BoxConstraints(),
              iconSize: 15,
              icon: const Icon(
                Icons.delete_forever,
                color: AppColors.znnColor,
              ),
              onPressed: () => showDialogWithNoAndYesOptions(
                isBarrierDismissible: true,
                context: context,
                title: 'Node Management',
                description: 'Are you sure you want to delete '
                    '${widget.node} from the list of nodes? This action '
                    "can't be undone.",
                onYesButtonPressed: () {
                  _deleteNodeFromDb(widget.node);
                },
              ),
              tooltip: 'Delete node',
            ),),
      ],
    );
  }

  Widget _getNodeInputField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: SizedBox(
                child: Form(
                  key: widget.key,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: InputField(
                      controller: _nodeController,
                      hintText: 'Node address with port',
                      onSubmitted: (value) {
                        if (_nodeController.text != widget.node &&
                            _ifUserInputValid()) {
                          _onChangeButtonPressed();
                        }
                      },
                      onChanged: (String value) {
                        if (value.isNotEmpty) {
                          setState(() {
                            _nodeError = null;
                          });
                        }
                      },
                      validator: (value) =>
                          InputValidators.node(value) ?? _nodeError,),
                ),
              ),
            ),
            const SizedBox(
              width: 15,
            ),
            SettingsButton(
              onPressed:
                  _nodeController.text != widget.node && _ifUserInputValid()
                      ? _onChangeButtonPressed
                      : null,
              text: 'Change',
              key: _changeButtonKey,
            ),
            MaterialIconButton(
              size: 15,
              onPressed: () {
                setState(() {
                  _nodeController.text = widget.node;
                  _editable = false;
                  _nodeError = null;
                });
              },
              iconData: Icons.clear,
            ),
          ],
        ),
      ],
    );
  }

  bool _ifUserInputValid() =>
      InputValidators.node(_nodeController.text) == null;

  Future<void> _onChangeButtonPressed() async {
    try {
      _changeButtonKey.currentState!.showLoadingIndicator(true);
      if (_nodeController.text.isNotEmpty &&
          _nodeController.text.length <= kAddressLabelMaxLength &&
          ![...kDefaultNodes, ...kDefaultCommunityNodes, ...kDbNodes]
              .contains(_nodeController.text)) {
        if (!Hive.isBoxOpen(kNodesBox)) {
          await Hive.openBox<String>(kNodesBox);
        }
        final nodesBox = Hive.box<String>(kNodesBox);
        final nodeKey = nodesBox.keys.firstWhere(
          (key) => nodesBox.get(key) == widget.node,
        );
        await nodesBox.put(nodeKey, _nodeController.text);
        await NodeUtils.loadDbNodes();
        setState(() {
          _editable = false;
          _nodeError = null;
        });
        if (!mounted) return;
        widget.onChangedOrDeletedNode();
      } else if (_nodeController.text.isEmpty) {
        setState(() {
          _nodeError = "Node address can't be empty";
        });
      } else if (_nodeController.text.length > kAddressLabelMaxLength) {
        setState(() {
          _nodeError =
              'The node has more than $kAddressLabelMaxLength characters';
        });
      } else {
        setState(() {
          _nodeError = 'Node already exists';
        });
      }
    } catch (e) {
      await NotificationUtils.sendNotificationError(
        e,
        'Something went wrong',
      );
    } finally {
      _changeButtonKey.currentState!.showLoadingIndicator(false);
    }
  }

  Future<void> _deleteNodeFromDb(String node) async {
    try {
      if (!Hive.isBoxOpen(kNodesBox)) {
        await Hive.openBox<String>(kNodesBox);
      }
      final nodesBox = Hive.box<String>(kNodesBox);
      final nodeKey = nodesBox.keys.firstWhere(
        (key) => nodesBox.get(key) == node,
      );
      await nodesBox.delete(nodeKey);
      kDbNodes.remove(node);
      if (!mounted) return;
      widget.onChangedOrDeletedNode();
    } catch (e) {
      await NotificationUtils.sendNotificationError(
        e,
        'Error during deleting node $node from the database',
      );
    }
  }

  @override
  void dispose() {
    _nodeController.dispose();
    super.dispose();
  }
}
