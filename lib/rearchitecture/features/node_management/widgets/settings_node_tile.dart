import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

/// Displays a selectable node row with connection tooltips and inline
/// edit/delete controls for user-added nodes.
class SettingsNodeTile extends StatefulWidget {
  /// Creates a [SettingsNodeTile].
  const SettingsNodeTile({
    required this._node,
    required this._currentNode,
    required this._clientChainId,
    required this._connectedNodeChainId,
    required this._isDefaultNode,
    required this._isCommunityNode,
    required this._isSavingEdit,
    required this._onNodePressed,
    required this._onEditSubmitted,
    required this._onDeleteConfirmed,
    this._editError,
    super.key,
  });

  final String _node;
  final String _currentNode;
  final int _clientChainId;
  final int _connectedNodeChainId;
  final bool _isDefaultNode;
  final bool _isCommunityNode;
  final bool _isSavingEdit;
  final ValueChanged<String> _onNodePressed;
  final ValueChanged<String> _onEditSubmitted;
  final VoidCallback _onDeleteConfirmed;
  final String? _editError;

  @override
  State<SettingsNodeTile> createState() => _SettingsNodeTileState();
}

class _SettingsNodeTileState extends State<SettingsNodeTile> {
  bool _editable = false;
  bool _hideExternalError = false;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _nodeController;

  @override
  void initState() {
    super.initState();
    _nodeController = TextEditingController(text: widget._node);
  }

  @override
  void didUpdateWidget(covariant SettingsNodeTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget._node != widget._node) {
      _nodeController.text = widget._node;
      _editable = false;
      _hideExternalError = false;
    } else if (oldWidget._editError != widget._editError &&
        widget._editError != null) {
      _hideExternalError = false;
      _formKey.currentState?.validate();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      child: _editable ? _buildNodeInputField(context) : _buildNodeRow(context),
    );
  }

  Widget _buildNodeRow(BuildContext context) {
    final bool isCustomNode =
        !widget._isDefaultNode && !widget._isCommunityNode;
    final bool isCurrentNode = widget._currentNode == widget._node;
    final bool chainIdsMatch =
        widget._connectedNodeChainId == widget._clientChainId;
    final TextStyle bodyLarge = Theme.of(context).textTheme.bodyLarge!;

    return Row(
      children: <Widget>[
        Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => widget._onNodePressed(widget._node),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
              child: Text(
                widget._node,
                style: bodyLarge.copyWith(
                  color: bodyLarge.color?.withValues(alpha: 0.7),
                ),
              ),
            ),
          ),
        ),
        if (isCurrentNode)
          StandardTooltipIcon(
            chainIdsMatch
                ? context.l10n.clientAndNodeChainIdentifiers(
                    widget._clientChainId,
                    widget._connectedNodeChainId,
                  )
                : context.l10n.chainIdentifierMismatchDetails(
                    widget._clientChainId,
                    widget._connectedNodeChainId,
                  ),
            MaterialCommunityIcons.identifier,
            iconColor: chainIdsMatch
                ? AppColors.znnColor
                : AppColors.errorColor,
          ),
        if (widget._node.contains('wss://'))
          StandardTooltipIcon(context.l10n.encryptedConnection, Icons.lock),
        if (widget._node.contains('ws://'))
          StandardTooltipIcon(
            context.l10n.unencryptedConnection,
            Icons.lock_open,
            iconColor: AppColors.errorColor,
          ),
        if (widget._node.contains('Embedded')) ...<Widget>[
          StandardTooltipIcon(
            context.l10n.integratedFullNodeEnhancedSecurity,
            MaterialCommunityIcons.security,
          ),
          StandardTooltipIcon(
            context.l10n.embeddedNodeValidatesTransactions,
            MaterialCommunityIcons.clock,
            iconColor: Colors.amber,
          ),
        ],
        if (widget._isCommunityNode)
          StandardTooltipIcon(
            context.l10n.communityNode,
            MaterialCommunityIcons.vector_link,
            iconColor: Colors.amber,
          ),
        if (isCustomNode) ...<Widget>[
          IconButton(
            hoverColor: Colors.transparent,
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(),
            iconSize: 15,
            icon: const Icon(Icons.edit, color: AppColors.znnColor),
            onPressed: () {
              setState(() {
                _nodeController.text = widget._node;
                _editable = true;
                _hideExternalError = true;
              });
            },
            tooltip: context.l10n.editNode,
          ),
          IconButton(
            hoverColor: Colors.transparent,
            padding: const EdgeInsets.all(4),
            constraints: const BoxConstraints(),
            iconSize: 15,
            icon: const Icon(Icons.delete_forever, color: AppColors.znnColor),
            onPressed: () => _confirmDelete(context),
            tooltip: context.l10n.deleteNode,
          ),
        ],
      ],
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final bool? deleteConfirmed = await showDialogWithNoAndYesOptions(
      isBarrierDismissible: true,
      context: context,
      title: context.l10n.nodeManagement,
      description: context.l10n.deleteNodeConfirmation(widget._node),
    );
    if (!mounted) {
      return;
    }
    if (deleteConfirmed ?? false) {
      widget._onDeleteConfirmed();
    }
  }

  Widget _buildNodeInputField(BuildContext context) {
    final bool canSubmit =
        !widget._isSavingEdit &&
        _nodeController.text != widget._node &&
        _isInputValid();

    return Row(
      children: <Widget>[
        Expanded(
          child: Form(
            key: _formKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: InputField(
              controller: _nodeController,
              hintText: context.l10n.nodeAddressWithPort,
              onSubmitted: (String value) {
                if (canSubmit) {
                  widget._onEditSubmitted(_nodeController.text);
                }
              },
              onChanged: (String value) {
                setState(() {
                  _hideExternalError = true;
                });
              },
              validator: (String? value) =>
                  InputValidators.node(value) ??
                  (_hideExternalError ? null : widget._editError),
            ),
          ),
        ),
        const SizedBox(width: 15),
        SettingsButton(
          onPressed: canSubmit
              ? () => widget._onEditSubmitted(_nodeController.text)
              : null,
          text: context.l10n.change,
        ),
        MaterialIconButton(
          size: 15,
          onPressed: () {
            setState(() {
              _nodeController.text = widget._node;
              _editable = false;
              _hideExternalError = true;
            });
          },
          iconData: Icons.clear,
        ),
      ],
    );
  }

  bool _isInputValid() => InputValidators.node(_nodeController.text) == null;

  @override
  void dispose() {
    _nodeController.dispose();
    super.dispose();
  }
}
