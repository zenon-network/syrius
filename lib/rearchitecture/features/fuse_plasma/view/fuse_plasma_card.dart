import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:provider/provider.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/plasma_stats/bloc/plasma_stats_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// A card that lets the user fuse QSR for Plasma.
class FusePlasmaCard extends StatelessWidget {
  /// Creates a [FusePlasmaCard].
  const FusePlasmaCard({
    required this.onPlasmaFused, this.plasmaStatsResults,
    this.errorText,
    super.key,
  });

  /// Plasma stats used to preview generated Plasma for the beneficiary address.
  final List<PlasmaInfoWrapper>? plasmaStatsResults;

  /// Called after a fuse transaction was successfully created.
  final VoidCallback onPlasmaFused;

  /// Error text from the Plasma stats loader.
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<FusePlasmaBloc>(
      create: (_) => FusePlasmaBloc(
        accountBlockUtils: AccountBlockUtils(),
        zenon: zenon!,
        zenonAddressUtils: ZenonAddressUtils(),
      ),
      child: _View(
        plasmaStatsResults: plasmaStatsResults,
        onPlasmaFused: onPlasmaFused,
        errorText: errorText,
      ),
    );
  }
}

class _View extends StatelessWidget {
  const _View({
    required this.onPlasmaFused, required this.errorText, this.plasmaStatsResults,
  });

  final List<PlasmaInfoWrapper>? plasmaStatsResults;
  final VoidCallback onPlasmaFused;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    return NewCardScaffold(
      data: _buildCardData(context: context),
      onRefreshPressed: _fetchBalance,
      body: errorText != null
          ? SyriusErrorWidget(errorText!)
          : BlocBuilder<MultipleBalanceBloc, MultipleBalanceState>(
              builder: (_, MultipleBalanceState state) => switch (state
                  .status) {
                MultipleBalanceStatus.failure => SyriusErrorWidget(
                  state.error!,
                ),
                MultipleBalanceStatus.initial => const SyriusLoadingWidget(),
                MultipleBalanceStatus.loading => const SyriusLoadingWidget(),
                MultipleBalanceStatus.success => _Populated(
                  mapAccountInfo: state.data!,
                  plasmaStatsResults: plasmaStatsResults!,
                  onPlasmaFused: onPlasmaFused,
                ),
              },
            ),
    );
  }

  CardData _buildCardData({required BuildContext context}) => CardData(
    title: context.l10n.fusePlasmaTitle,
    description: context.l10n.fusePlasmaDescription(kQsrCoin.symbol),
  );
}

void _fetchBalance() {
  sl.get<MultipleBalanceBloc>().add(
    MultipleBalanceFetch(
      addresses: kDefaultAddressList.map((String? e) => e!).toList(),
    ),
  );
}

class _Populated extends StatefulWidget {
  const _Populated({
    required this.mapAccountInfo,
    required this.plasmaStatsResults,
    required this.onPlasmaFused,
  });

  final Map<String, AccountInfo> mapAccountInfo;
  final List<PlasmaInfoWrapper> plasmaStatsResults;
  final VoidCallback onPlasmaFused;

  @override
  State<_Populated> createState() => _PopulatedState();
}

class _PopulatedState extends State<_Populated> {
  final TextEditingController _qsrAmountController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _beneficiaryAddressController =
      TextEditingController();
  final GlobalKey<LoadingButtonState> _fuseButtonKey = GlobalKey();
  final ValueNotifier<String> _beneficiaryAddressString = ValueNotifier<String>(
    '',
  );

  late final PlasmaBeneficiaryAddressNotifier _plasmaBeneficiaryAddress;
  final double _marginWidth = 20;
  final double _spaceBetweenExpandedWidgets = 10;

  BigInt get _maxQsrAmount =>
      widget.mapAccountInfo[kSelectedAddress!]?.getBalance(
        kQsrCoin.tokenStandard,
      ) ??
      BigInt.zero;

  AccountInfo? get _accountInfo => widget.mapAccountInfo[kSelectedAddress!];

  String? get _qsrAmountError => InputValidators.correctValue(
    _qsrAmountController.text,
    _maxQsrAmount,
    kQsrCoin.decimals,
    fuseMinQsrAmount,
    canBeEqualToMin: true,
  );

  String? get _beneficiaryAddressError =>
      InputValidators.checkAddress(_beneficiaryAddressController.text);

  bool get _isInputValid =>
      _qsrAmountController.text.isNotEmpty &&
      _qsrAmountError == null &&
      _beneficiaryAddressController.text.isNotEmpty &&
      _beneficiaryAddressError == null;

  @override
  void initState() {
    super.initState();
    _addressController.text = kSelectedAddress!;
    _plasmaBeneficiaryAddress = Provider.of<PlasmaBeneficiaryAddressNotifier>(
      context,
      listen: false,
    );
    _plasmaBeneficiaryAddress.addListener(_beneficiaryAddressListener);
    _fetchBalance();
  }

  @override
  void dispose() {
    _plasmaBeneficiaryAddress.removeListener(_beneficiaryAddressListener);
    _qsrAmountController.dispose();
    _addressController.dispose();
    _beneficiaryAddressController.dispose();
    _beneficiaryAddressString.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<FusePlasmaBloc, FusePlasmaState>(
      listener: (_, FusePlasmaState state) => _onFusePlasmaStateChanged(state),
      child: Consumer<SelectedAddressNotifier>(
        builder: (_, _, Widget? child) {
          _addressController.text = kSelectedAddress!;
          return child!;
        },
        child: LayoutBuilder(
          builder: (_, BoxConstraints constraints) {
            final AccountInfo? accountInfo = _accountInfo;
            if (accountInfo == null) {
              return const SyriusLoadingWidget();
            }

            return _buildBody(accountInfo);
          },
        ),
      ),
    );
  }

  Widget _buildBody(AccountInfo accountInfo) {
    return Container(
      margin: EdgeInsets.all(_marginWidth),
      child: Column(
        crossAxisAlignment: .start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: .start,
                  children: <Widget>[
                    DisabledAddressField(
                      _addressController,
                    ),
                  ],
                ),
              ),
              SizedBox(width: _spaceBetweenExpandedWidgets),
              Expanded(
                child: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _qsrAmountController,
                  builder: (_, TextEditingValue value, _) {
                    return TextField(
                      decoration: InputDecoration(
                        errorText: value.text.isNotEmpty
                            ? _qsrAmountError
                            : null,
                        suffixIcon: TextButton(
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.qsrColor,
                          ),
                          onPressed: _maxQsrAmount > BigInt.zero
                              ? _onMaxPressed
                              : null,
                          child: Text(
                            context.l10n.max.toUpperCase(),
                          ),
                        ),
                        hintText: context.l10n.amount,
                      ),
                      enabled: _maxQsrAmount > BigInt.zero,
                      onChanged: (_) {
                        setState(() {});
                      },
                      inputFormatters:
                          FormatUtils.getPlasmaAmountTextInputFormatters(
                            value.text,
                          ),
                      controller: _qsrAmountController,
                    );
                  },
                ),
              ),
            ],
          ),
          AvailableBalance.stepper(kQsrCoin, accountInfo),
          Row(
            children: <Widget>[
              Expanded(
                child: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _beneficiaryAddressController,
                  builder: (_, TextEditingValue value, _) {
                    return TextField(
                      decoration: InputDecoration(
                        errorText: value.text.isNotEmpty
                            ? _beneficiaryAddressError
                            : null,
                        hintText: context.l10n.beneficiaryAddress,
                        suffixIcon: FieldSuffixButtons(
                          controller: _beneficiaryAddressController,
                        ),
                      ),
                      onChanged: (String value) {
                        _beneficiaryAddressString.value = value;
                      },
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.allow(
                          RegExp('[0-9a-z]'),
                        ),
                      ],
                      controller: _beneficiaryAddressController,
                    );
                  },
                ),
              ),
              SizedBox(width: _spaceBetweenExpandedWidgets),
              Expanded(
                child: Column(
                  crossAxisAlignment: .stretch,
                  children: <Widget>[
                    ListenableBuilder(
                      listenable: Listenable.merge([
                        _beneficiaryAddressString,
                        _beneficiaryAddressController,
                        _qsrAmountController,
                      ]),
                      builder: (_, _) {
                        return _buildFuseButton();
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
          kVerticalGap16,
          ListenableBuilder(
            listenable: Listenable.merge([
              _beneficiaryAddressController,
              _qsrAmountController,
            ]),
            builder: (_, _) {
              return Visibility(
                visible: _isInputValid,
                child: Row(
                  children: [
                    const Text('Future plasma: '),
                    kHorizontalGap8,
                    _buildPlasmaIcon(),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// How plasma is calculated: 1 QSR equals a plasma value of 2100
  ///
  /// The text field seems to not allow the user to enter decimals. Which is
  /// good because the way the plasma value is calculated, converted and
  /// handled, it seems that the decimals are disregarded
  ///
  /// So a number with decimals might break the flow, or those decimals might
  /// be lost in data type conversions
  PlasmaIcon _buildPlasmaIcon() {
    BigInt currentPlasma = BigInt.zero;
    if (_qsrAmountController.text.isNotEmpty) {
      final BigInt qsrAmountWithoutDecimals = _qsrAmountController.text
          .extractDecimals(
            kQsrCoin.decimals,
          );

      final BigInt plasmaValueWithoutDecimals = zenon!.embedded.plasma
          .getPlasmaByQsr(qsrAmountWithoutDecimals);

      final String plasmaValue = plasmaValueWithoutDecimals.addDecimals(
        kQsrCoin.decimals,
      );

      currentPlasma = BigInt.parse(plasmaValue);
    }

    final BigInt pastPlasma = BigInt.from(_getPlasmaForCurrentBeneficiary());

    final BigInt finalPlasma = currentPlasma + pastPlasma;

    return PlasmaIcon(
      PlasmaInfo.fromJson(
        <String, dynamic>{
          'currentPlasma': finalPlasma.toInt(),
          'maxPlasma': 0,
          'qsrAmount': '0',
        },
      ),
    );
  }

  int _getPlasmaForCurrentBeneficiary() {
    final PlasmaInfoWrapper? plasmaInfoWrapper = widget.plasmaStatsResults
        .firstWhereOrNull(
          (PlasmaInfoWrapper plasmaInfo) =>
              plasmaInfo.address == _beneficiaryAddressController.text,
        );

    return plasmaInfoWrapper?.plasmaInfo.currentPlasma ?? 0;
  }

  Widget _buildFuseButton() {
    const Widget icon = Icon(
      Icons.bolt,
    );

    // TODO(maznnwell): make sure the button is as tall as the text field
    return LoadingButton.icon(
      key: _fuseButtonKey,
      onPressed: _isInputValid ? _onFusePressed : null,
      label: context.l10n.fuse,
      outlineColor: AppColors.qsrColor,
      icon: icon,
      textStyle: const TextStyle(
        color: AppColors.qsrColor,
      ),
    );
  }

  void _onFusePressed() {
    context.read<FusePlasmaBloc>().add(
      FusePlasmaRequested(
        beneficiaryAddress: _beneficiaryAddressController.text,
        amount: _qsrAmountController.text.extractDecimals(kQsrCoin.decimals),
      ),
    );
  }

  void _onMaxPressed() {
    if (_qsrAmountController.text.isEmpty ||
        _qsrAmountController.text.extractDecimals(kQsrCoin.decimals) !=
            _maxQsrAmount) {
      _qsrAmountController.text = _maxQsrAmount.addDecimals(kQsrCoin.decimals);
    }
  }

  void _beneficiaryAddressListener() {
    _beneficiaryAddressController.text = _plasmaBeneficiaryAddress
        .getBeneficiaryAddress()!;
    _beneficiaryAddressString.value = _beneficiaryAddressController.text;
  }

  void _onFusePlasmaStateChanged(FusePlasmaState state) {
    if (state is FusePlasmaLoading) {
      _fuseButtonKey.currentState?.animateForward();
    } else if (state is FusePlasmaDone) {
      _fuseButtonKey.currentState?.animateReverse();
      _qsrAmountController.clear();
      _beneficiaryAddressController.clear();
      _fetchBalance();
      sl.get<PlasmaStatsBloc>().add(
        const InfiniteListRefreshRequested(),
      );
      widget.onPlasmaFused();
    } else if (state is FusePlasmaFailure) {
      _fuseButtonKey.currentState?.animateReverse();
      unawaited(
        NotificationUtils.sendNotificationError(
          state.exception,
          context.l10n.errorGeneratingPlasma,
        ),
      );
    }
  }
}
