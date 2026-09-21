import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/notifications_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/transfer_token/bloc/transfer_token_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// Displays the form used to transfer ownership of a ZTS token.
class TransferTokenView extends StatelessWidget {
  /// Creates a [TransferTokenView].
  const TransferTokenView({
    required this._onBackPressed,
    required this._token,
    super.key,
  });

  final VoidCallback _onBackPressed;
  final Token _token;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<TransferTokenBloc>(
      create: (_) => TransferTokenBloc(
        accountBlockUtils: AccountBlockUtils(),
        zenon: zenon!,
      ),
      child: _View(
        onBackPressed: _onBackPressed,
        token: _token,
      ),
    );
  }
}

class _View extends StatefulWidget {
  const _View({
    required this._onBackPressed,
    required this._token,
  });

  final VoidCallback _onBackPressed;
  final Token _token;

  @override
  State<_View> createState() => _ViewState();
}

class _ViewState extends State<_View> {
  final GlobalKey<LoadingButtonState> _buttonKey = GlobalKey();
  final TextEditingController _newOwnerAddressController =
      TextEditingController();

  String get _newOwnerAddress => _newOwnerAddressController.text;

  String? get _newOwnerAddressError => InputValidators.checkAddress(
    _newOwnerAddress,
  );

  @override
  void initState() {
    super.initState();
    _newOwnerAddressController.addListener(() {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<TransferTokenBloc, TransferTokenState>(
      listener: _onTransferTokenStateChanged,
      child: ListView(
        children: <Widget>[
          TextField(
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.allow(RegExp('[0-9a-z]')),
            ],
            controller: _newOwnerAddressController,
            decoration: InputDecoration(
              errorText: _newOwnerAddress.isEmpty
                  ? null
                  : _newOwnerAddressError,
              hintText: context.l10n.newOwnerAddress,
              suffixIcon: FieldSuffixButtons(
                controller: _newOwnerAddressController,
              ),
            ),
          ),
          kVerticalSpacing,
          Column(
            children: <Widget>[
              _buildTransferButton(),
              kVerticalGap16,
              OutlinedButton(
                onPressed: widget._onBackPressed,
                child: Text(context.l10n.goBack),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTransferButton() {
    final bool canTransfer =
        _newOwnerAddress.isNotEmpty && _newOwnerAddressError == null;

    return LoadingButton.stepper(
      text: context.l10n.transfer,
      onPressed: canTransfer ? _transferToken : null,
      key: _buttonKey,
    );
  }

  void _transferToken() {
    context.read<TransferTokenBloc>().add(
      TransferTokenRequested(
        newOwnerAddress: Address.parse(_newOwnerAddress),
        token: widget._token,
      ),
    );
  }

  void _onTransferTokenStateChanged(
    BuildContext context,
    TransferTokenState state,
  ) {
    if (state is TransferTokenLoading) {
      _buttonKey.currentState?.animateForward();
    } else if (state is TransferTokenDone) {
      final String newOwnerAddress = _newOwnerAddress;
      _newOwnerAddressController.clear();
      _buttonKey.currentState?.animateReverse();
      unawaited(_sendSuccessfulNotification(newOwnerAddress));
    } else if (state is TransferTokenFailure) {
      _buttonKey.currentState?.animateReverse();
      unawaited(
        NotificationUtils.sendNotificationError(
          state.exception,
          context.l10n.errorTransferringTokenOwnership,
        ),
      );
    }
  }

  Future<void> _sendSuccessfulNotification(String newOwnerAddress) async {
    await sl.get<NotificationsBloc>().addNotification(
      WalletNotification(
        title: context.l10n.transferredTokenOwnership(widget._token.name),
        timestamp: DateTime.now().millisecondsSinceEpoch,
        details: context.l10n.transferredTokenOwnershipToAddress(
          newOwnerAddress,
          widget._token.name,
        ),
        type: NotificationType.paymentSent,
      ),
    );
  }

  @override
  void dispose() {
    _newOwnerAddressController.dispose();
    super.dispose();
  }
}
