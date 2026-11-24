import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// A widget that helps the user generate a QR for requesting funds.
///
/// It has two dropdowns:
/// - one for the address on which the funds will be received.
/// - one for the asset that will be transferred - token or native coin.
///
/// And a [TextField] for inputting the transfer amount.
///
/// This data, destination address, asset and amount, is found in the QR.
class ReceiveCard extends StatelessWidget {
  /// Creates a new instance.
  const ReceiveCard({super.key});

  @override
  Widget build(BuildContext context) {
    return NewCardScaffold(
      data: _buildCardData(context: context),
      onRefreshPressed: () {
        context.read<AllTokensBloc>().add(const AllTokensRequested());
      },
      body: BlocBuilder<AllTokensBloc, AllTokensState>(
        builder: (_, AllTokensState state) {
          return switch (state) {
            AllTokensFailure(:final SyriusException exception) =>
              SyriusErrorWidget(exception),
            AllTokensInitial() => const SyriusLoadingWidget(),
            AllTokensPopulated(:final List<Token> data) => _Populated(
              assets: data,
            ),
          };
        },
      ),
    );
  }

  CardData _buildCardData({required BuildContext context}) => CardData(
    description: context.l10n.manageReceivingFunds,
    title: context.l10n.receive,
  );
}

class _Populated extends StatefulWidget {
  /// Creates a new instance.
  const _Populated({
    required this.assets,
  });

  /// The list of available assets on the network - includes tokens and coins
  final List<Token> assets;

  @override
  State<_Populated> createState() => _PopulatedState();
}

class _PopulatedState extends State<_Populated> {
  final TextEditingController _amountController = TextEditingController();

  final ValueNotifier<String> _receiverNotifier = .new(kSelectedAddress!);

  late final ValueNotifier<Token> _tokenNotifier;

  Token get _token => _tokenNotifier.value;

  String get _amount => _amountController.text;

  String? get _amountErrorText => InputValidators.correctValue(
    _amount,
    kBigP255m1,
    _token.decimals,
    BigInt.zero,
  );

  @override
  void initState() {
    super.initState();
    final Token networkZnn = widget.assets.firstWhere(
      (Token asset) => asset.tokenStandard.toString() == znnTokenStandard,
    );
    _tokenNotifier = .new(networkZnn);
  }

  @override
  Widget build(BuildContext context) {
    final List<Token> sortedAssets = sortAssets(widget.assets);

    return ListenableBuilder(
      listenable: Listenable.merge(<Listenable?>[
        _tokenNotifier,
        _receiverNotifier,
      ]),
      builder: (_, _) {
        final String receiver = _receiverNotifier.value;

        return Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              ReceiveQrImage(
                data: _getQrString(
                  address: receiver,
                ),
                tokenStandard: _token.tokenStandard,
              ),
              kHorizontalGap16,
              Expanded(
                child: Column(
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: _buildDefaultAddressDropdown(),
                        ),
                        CopyToClipboardButton(
                          _receiverNotifier.value,
                        ),
                      ],
                    ),
                    kVerticalGap16,
                    ZtsDropdown(
                      availableTokens: sortedAssets,
                      selectedToken: _tokenNotifier,
                    ),
                    kVerticalGap16,
                    TextField(
                      decoration: InputDecoration(
                        errorText: _amount.isNotEmpty ? _amountErrorText : null,
                        hintText: context.l10n.amount,
                      ),
                      onChanged: (String value) => setState(() {}),
                      inputFormatters: FormatUtils.getAmountTextInputFormatters(
                        _amountController.text,
                      ),
                      controller: _amountController,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getQrString({
    required String address,
  }) {
    return '${_token.symbol.toLowerCase()}:'
        '$address?zts=${_token.tokenStandard}'
        '&amount=${_getAmount()}';
  }

  BigInt _getAmount() {
    try {
      return _amountController.text.extractDecimals(_token.decimals);
    } on Exception catch (_) {
      return BigInt.zero;
    }
  }

  Widget _buildDefaultAddressDropdown() {
    return NewAddressesDropdown(
      addresses: kDefaultAddressList.map((String? e) => e!).toList(),
      selectedAddress: _receiverNotifier,
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _receiverNotifier.dispose();
    super.dispose();
  }
}
