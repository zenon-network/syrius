import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/utils/format_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:zenon_syrius_wallet_flutter/utils/input_validators.dart';
import 'package:zenon_syrius_wallet_flutter/utils/notification_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/zts_utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class SwapCard extends StatefulWidget {
  const SwapCard({Key? key}) : super(key: key);

  @override
  State<SwapCard> createState() => _SwapCardState();
}

class _SwapCardState extends State<SwapCard> {
  String? _selectedSelfAddress = kSelectedAddress;

  TextEditingController _amountController = TextEditingController();
  TextEditingController _evmAddressController = TextEditingController();

  GlobalKey<FormState> _amountKey = GlobalKey();
  GlobalKey<FormState> _evmAddressKey = GlobalKey();
  final GlobalKey<LoadingButtonState> _swapButtonKey = GlobalKey();

  final SendPaymentBloc _sendPaymentBloc = SendPaymentBloc();
  bool? _userHasEnoughBnbBalance = false;

  String? _selectedBridge = kBridgeNetworks.first;
  final bool _bridgeStatus = false;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    sl.get<TransferWidgetsBalanceBloc>().getBalanceForAllAddresses();
    _sendPaymentBloc.stream.listen(
      (event) {
        if (event is AccountBlockTemplate) {
          _sendConfirmationNotification();
          setState(() {
            _swapButtonKey.currentState?.animateReverse();
            _amountController = TextEditingController();
            _evmAddressController = TextEditingController();
            _amountKey = GlobalKey();
            _evmAddressKey = GlobalKey();
          });
        }
      },
      onError: (error) {
        _swapButtonKey.currentState?.animateReverse();
        NotificationUtils.sendNotificationError(error,
            'Couldn\'t send ${_amountController.text} ${kZnnCoin.symbol}');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return CardScaffold(
      title: 'Swap',
      description:
          'Bidirectional swap between Alphanet and other networks\nZNN => wZNN (wrapped ZNN): swap fee of 1% + 0.1 ZNN\nwZNN => ZNN: feeless (no swap fee)',
      childBuilder: () => _getBalanceStreamBuilder(),
    );
  }

  Widget _getBalanceStreamBuilder() {
    return StreamBuilder<Map<String, AccountInfo>?>(
      stream: sl.get<TransferWidgetsBalanceBloc>().stream,
      builder: (_, snapshot) {
        if (snapshot.hasError) {
          return SyriusErrorWidget(snapshot.error!);
        }
        if (snapshot.connectionState == ConnectionState.active) {
          if (snapshot.hasData) {
            return _getWidgetBody(
              snapshot.data![_selectedSelfAddress!]!,
            );
          }
          return const SyriusLoadingWidget();
        }
        return const SyriusLoadingWidget();
      },
    );
  }

  Widget _getWidgetBody(AccountInfo accountInfo) {
    return Scrollbar(
      controller: _scrollController,
      child: Container(
        margin: const EdgeInsets.all(20.0),
        child: ListView(
          controller: _scrollController,
          children: [
            _getInputFields(accountInfo),
          ],
        ),
      ),
    );
  }

  Column _getInputFields(AccountInfo accountInfo) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        BridgeNetworkDropdown(
          _selectedBridge,
          (value) => setState(() {
            _selectedBridge = value;
          }),
        ),
        Padding(
          padding: const EdgeInsets.only(
            left: 10.0,
            bottom: 5.0,
            top: 5.0,
          ),
          child: Text(
            'Send from',
            style: Theme.of(context).inputDecorationTheme.hintStyle,
          ),
        ),
        AddressesDropdown(
          _selectedSelfAddress,
          (address) => setState(() {
            _selectedSelfAddress = address;
            sl.get<TransferWidgetsBalanceBloc>().getBalanceForAllAddresses();
          }),
        ),
        Padding(
          padding: const EdgeInsets.only(
            left: 10.0,
            top: 5.0,
            bottom: 5.0,
          ),
          child: AvailableBalance(
            kZnnCoin,
            accountInfo,
          ),
        ),
        Form(
          key: _amountKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: InputField(
            controller: _amountController,
            hintText: 'Amount',
            onChanged: (value) {
              setState(() {});
            },
            inputFormatters: FormatUtils.getAmountTextInputFormatters(
              _amountController.text,
            ),
            validator: (value) => InputValidators.correctValue(
              value,
              accountInfo.getBalance(
                kZnnCoin.tokenStandard,
              ),
              kZnnCoin.decimals,
              BigInt.zero,
              canBeEqualToMin: false,
            ),
            suffixIcon: AmountSuffixWidgets(
              kZnnCoin,
              onMaxPressed: () => _onMaxPressed(accountInfo),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(left: 10.0, bottom: 5.0, top: 5.0),
          child: Text(
            'Receive to',
            style: Theme.of(context).inputDecorationTheme.hintStyle,
          ),
        ),
        Form(
          key: _evmAddressKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: InputField(
            controller: _evmAddressController,
            hintText: 'BNB Smart Chain address',
            validator: InputValidators.evmAddress,
            onChanged: (value) => setState(() {}),
          ),
        ),
      ],
    );
  }

  Widget _getCheckBox() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SyriusCheckbox(
          context: context,
          value: _userHasEnoughBnbBalance,
          onChanged: (value) {
            setState(() {
              _userHasEnoughBnbBalance = value;
            });
          },
        ),
        Text(
          'I have enough funds to cover the gas fees in order to complete the swap',
          style: Theme.of(context).textTheme.bodyMedium,
        )
      ],
    );
  }

  void _sendSwapBlock() {
    _swapButtonKey.currentState?.animateForward();
  }

  void _onMaxPressed(AccountInfo accountInfo) => setState(() {
        _amountController.text = accountInfo
            .getBalance(
              kZnnCoin.tokenStandard,
            )
            .addDecimals(coinDecimals);
      });

  bool _isInputValid(AccountInfo accountInfo) =>
      InputValidators.correctValue(
            _amountController.text,
            accountInfo.getBalance(
              kZnnCoin.tokenStandard,
            ),
            kZnnCoin.decimals,
            BigInt.zero,
            canBeEqualToMin: false,
          ) ==
          null &&
      InputValidators.evmAddress(_evmAddressController.text) == null;

  void _sendConfirmationNotification() {
    sl.get<NotificationsBloc>().addNotification(
          WalletNotification(
            title: 'Sent ${_amountController.text} ${kZnnCoin.symbol}',
            timestamp: DateTime.now().millisecondsSinceEpoch,
            details: 'Sent ${_amountController.text} ${kZnnCoin.symbol}',
            type: NotificationType.paymentSent,
            id: null,
          ),
        );
  }

  void _onSwapButtonPressed() {
    showDialogWithNoAndYesOptions(
      isBarrierDismissible: true,
      context: context,
      title: 'Swap',
      description: 'Are you sure you want to swap ${_amountController.text} '
          '${kZnnCoin.symbol} ?',
      onYesButtonPressed: () {
        _sendSwapBlock();
      },
    );
  }

  List<int> _decodeEvmAddress() {
    String hexCharacters = _evmAddressController.text.split('0x')[1];
    return FormatUtils.decodeHexString(hexCharacters);
  }

  @override
  void dispose() {
    _amountController.dispose();
    _evmAddressController.dispose();
    super.dispose();
  }
}
