import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:hive/hive.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:zenon_syrius_wallet_flutter/utils/node_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/notification_utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class SettingsNode extends StatefulWidget {
  final String node;
  final void Function(String?) onNodePressed;
  final VoidCallback onChangedOrDeletedNode;
  final String currentNode;

  const SettingsNode({
    required this.node,
    required this.onNodePressed,
    required this.onChangedOrDeletedNode,
    required this.currentNode,
    Key? key,
  }) : super(key: key);

  @override
  State<SettingsNode> createState() => _SettingsNodeState();
}

class _SettingsNodeState extends State<SettingsNode> {
  bool _editable = false;

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
        vertical: 5.0,
      ),
      child: _editable ? _getNodeInputField() : _getNode(context),
    );
  }

  Row _getNode(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 1,
          child: InkWell(
            borderRadius: BorderRadius.circular(
              10.0,
            ),
            onTap: () => widget.onNodePressed(widget.node),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 5.0, vertical: 5.0),
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
                    ? 'Client chain identifier: ${getChainIdentifier().toString()}\n'
                        'Node chain identifier: $connectedNodeChainIdentifier'
                    : 'Chain identifier mismatch\n'
                        'Client chain identifier: ${getChainIdentifier().toString()}\n'
                        'Node chain identifier: $connectedNodeChainIdentifier',
                MaterialCommunityIcons.identifier,
                iconColor:
                    (getChainIdentifier() == connectedNodeChainIdentifier)
                        ? AppColors.znnColor
                        : AppColors.errorColor)),
        const SizedBox(
          width: 8.0,
        ),
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
          ),
        ),
        const SizedBox(
          width: 5.0,
        ),
        Visibility(
          visible: !kDefaultNodes.contains(widget.node),
          child: MaterialIconButton(
            iconData: Icons.edit,
            onPressed: () {
              setState(() {
                _editable = true;
              });
            },
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
        Visibility(
          visible: !kDefaultNodes.contains(widget.node),
          child: MaterialIconButton(
            onPressed: () {
              showDialogWithNoAndYesOptions(
                isBarrierDismissible: true,
                context: context,
                title: 'Node Management',
                description: 'Are you sure you want to delete '
                    '${widget.node} from the list of nodes? This action '
                    'can\'t be undone.',
                onYesButtonPressed: () {
                  _deleteNodeFromDb(widget.node);
                },
              );
            },
            iconData: Icons.delete_forever,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ),
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
                height: 40.0,
                child: InputField(
                  controller: _nodeController,
                  onSubmitted: (value) {
                    if (_nodeController.text != widget.node) {
                      _onChangeButtonPressed();
                    }
                  },
                  onChanged: (value) {
                    setState(() {});
                  },
                  inputtedTextStyle:
                      Theme.of(context).textTheme.bodyMedium!.copyWith(
                            color: AppColors.znnColor,
                          ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide.none,
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  contentLeftPadding: 5.0,
                  disabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.white.withOpacity(0.1),
                    ),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: AppColors.znnColor),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: const BorderSide(
                      color: AppColors.errorColor,
                      width: 2.0,
                    ),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                    borderSide: const BorderSide(
                      color: AppColors.errorColor,
                      width: 2.0,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(
              width: 15.0,
            ),
            SettingsButton(
              onPressed: _nodeController.text != widget.node
                  ? _onChangeButtonPressed
                  : null,
              text: 'Change',
              key: _changeButtonKey,
            ),
            MaterialIconButton(
              onPressed: () {
                setState(() {
                  _nodeController.text = widget.node;
                  _editable = false;
                });
              },
              iconData: Icons.clear,
            ),
          ],
        ),
      ],
    );
  }

  void _onChangeButtonPressed() async {
    try {
      _changeButtonKey.currentState!.showLoadingIndicator(true);
      if (_nodeController.text.isNotEmpty &&
          _nodeController.text.length <= kAddressLabelMaxLength &&
          ![...kDefaultNodes, ...kDbNodes].contains(_nodeController.text)) {
        Box<String> nodesBox = await Hive.openBox<String>(kNodesBox);
        dynamic key = nodesBox.keys.firstWhere(
          (key) => nodesBox.get(key) == widget.node,
        );
        await nodesBox.put(key, _nodeController.text);
        await NodeUtils.loadDbNodes();
        setState(() {
          _editable = false;
        });
      } else if (_nodeController.text.isEmpty) {
        NotificationUtils.sendNotificationError(
          'Node address can\'t be empty',
          'Node error',
        );
      } else if (_nodeController.text.length > kAddressLabelMaxLength) {
        NotificationUtils.sendNotificationError(
          'The node ${_nodeController.text} is ${_nodeController.text.length} '
              'characters long, which is more than the $kAddressLabelMaxLength limit.',
          'The node has more than $kAddressLabelMaxLength characters',
        );
      } else {
        NotificationUtils.sendNotificationError(
          'Node ${_nodeController.text} already exists in the database',
          'Node already exists',
        );
      }
    } catch (e) {
      NotificationUtils.sendNotificationError(
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
      Box<String> nodesBox = Hive.box<String>(kNodesBox);
      var nodeKey = nodesBox.keys.firstWhere(
        (key) => nodesBox.get(key) == node,
      );
      await nodesBox.delete(nodeKey);
      kDbNodes.remove(node);
      if (!mounted) return;
      widget.onChangedOrDeletedNode();
    } catch (e) {
      NotificationUtils.sendNotificationError(
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
