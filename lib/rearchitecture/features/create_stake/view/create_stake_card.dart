import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// A card that lets the user create a stake for the selected address.
class CreateStakeCard extends StatelessWidget {
  /// Creates a stake creation widget.
  const CreateStakeCard({
    required this.onStakeCreated,
    super.key,
  });

  /// Called after a stake transaction was successfully created.
  final VoidCallback onStakeCreated;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SendTransactionBloc>(
      create: (_) => SendTransactionBloc(),
      child: _View(onStakeCreated: onStakeCreated),
    );
  }
}

class _View extends StatelessWidget {
  const _View({required this.onStakeCreated});

  final VoidCallback onStakeCreated;

  @override
  Widget build(BuildContext context) {
    return NewCardScaffold(
      data: _buildCardData(context: context),
      onRefreshPressed: _fetchBalance,
      body: BlocBuilder<MultipleBalanceBloc, MultipleBalanceState>(
        builder: (_, MultipleBalanceState state) => switch (state.status) {
          MultipleBalanceStatus.failure => SyriusErrorWidget(state.error!),
          MultipleBalanceStatus.initial => const SyriusLoadingWidget(),
          MultipleBalanceStatus.loading => const SyriusLoadingWidget(),
          MultipleBalanceStatus.success => _Populated(
            mapAccountInfo: state.data!,
            onStakeCreated: onStakeCreated,
          ),
        },
      ),
    );
  }

  CardData _buildCardData({required BuildContext context}) => CardData(
    title: context.l10n.createStakeTitle,
    description: context.l10n.createStakeDescription(
      kQsrCoin.symbol,
      kZnnCoin.symbol,
    ),
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
    required this.onStakeCreated,
  });

  final Map<String, AccountInfo> mapAccountInfo;

  final VoidCallback onStakeCreated;

  @override
  State<_Populated> createState() => _PopulatedState();
}

class _PopulatedState extends State<_Populated> {
  final TextEditingController _amountController = TextEditingController();
  // TODO(maznnwell): this should be deleted because it wont change
  final TextEditingController _addressController = TextEditingController();

  final GlobalKey<LoadingButtonState> _stakeButtonKey = GlobalKey();

  final List<Duration> _durations = List<Duration>.generate(
    stakeTimeMaxSec ~/ stakeTimeUnitSec,
    (int index) => Duration(seconds: (index + 1) * stakeTimeUnitSec),
  );

  Duration? _selectedStakeDuration;

  BigInt get _maxZnnAmount =>
      widget.mapAccountInfo[kSelectedAddress!]!.getBalance(
        kZnnCoin.tokenStandard,
      );

  String get _amount => _amountController.text;

  String? get _amountErrorText => _amount.isNotEmpty
      ? InputValidators.correctValue(
          _amount,
          _maxZnnAmount,
          kZnnCoin.decimals,
          stakeMinZnnAmount,
          canBeEqualToMin: true,
        )
      : null;

  bool get _isInputValid =>
      _selectedStakeDuration != null &&
      _amount.isNotEmpty &&
      _amountErrorText == null;

  @override
  void dispose() {
    _addressController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _addressController.text = kSelectedAddress!;
  }

  @override
  Widget build(BuildContext context) {
    final AccountInfo accountInfo =
        widget.mapAccountInfo[_addressController.text]!;

    return BlocListener<SendTransactionBloc, SendTransactionState>(
      listener: (_, SendTransactionState state) =>
          _onTransactionStateChanged(state),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: .stretch,
          children: <Widget>[
            DisabledAddressField(
              _addressController,
            ),
            AvailableBalance.stepper(
              kZnnCoin,
              accountInfo,
            ),
            _buildStakeDurationDropdown(context),
            kVerticalGap16,
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: _amountController,
              builder: (_, TextEditingValue amount, _) {
                return TextField(
                  key: const Key('create_stake_amount_field'),
                  controller: _amountController,
                  decoration: InputDecoration(
                    errorText: _amountErrorText,
                    hintText: context.l10n.amount,
                    suffixIcon: TextButton(
                      onPressed: _maxZnnAmount > BigInt.zero
                          ? _onMaxPressed
                          : null,
                      child: Text(context.l10n.max.toUpperCase()),
                    ),
                  ),
                  inputFormatters: FormatUtils.getAmountTextInputFormatters(
                    _amountController.text,
                  ),
                  onSubmitted: (_) {
                    if (_isInputValid) {
                      _onStakePressed();
                    }
                  },
                );
              },
            ),
            kVerticalGap16,
            ListenableBuilder(
              listenable: _amountController,
              builder: (_, _) {
                return _StakeButton(
                  buttonKey: _stakeButtonKey,
                  isInputValid: _isInputValid,
                  onPressed: _onStakePressed,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStakeDurationDropdown(BuildContext context) {
    final List<DropdownMenuEntry<Duration>> entries = _durations
        .map(_buildDropdownMenuEntry)
        .toList();

    return DropdownMenu<Duration>(
      key: const Key('create_stake_duration_dropdown'),
      hintText: context.l10n.duration,
      dropdownMenuEntries: entries,
      onSelected: _onStakeDurationChanged,
      selectOnly: true,
      expandedInsets: EdgeInsets.zero,
      inputDecorationTheme: const InputDecorationTheme(
        filled: true,
      ),
      menuHeight: kDropdownMenuHeight,
      trailingIcon: const Icon(
        Icons.keyboard_arrow_down_rounded,
        color: AppColors.znnColor,
      ),
      selectedTrailingIcon: const Icon(
        Icons.keyboard_arrow_up_rounded,
        color: AppColors.znnColor,
      ),
    );
  }

  DropdownMenuEntry<Duration> _buildDropdownMenuEntry(Duration duration) {
    final int durationInUnits = duration.inSeconds ~/ stakeTimeUnitSec;

    return DropdownMenuEntry<Duration>(
      value: duration,
      label:
          '$durationInUnits $stakeUnitDurationName'
          '${durationInUnits > 1 ? 's' : ''}',
    );
  }

  void _onStakeDurationChanged(Duration? value) {
    setState(() {
      _selectedStakeDuration = value;
    });
  }

  void _onMaxPressed() {
    _amountController.text = _maxZnnAmount.addDecimals(kZnnCoin.decimals);
  }

  void _onStakePressed() {
    if (!_isInputValid) {
      return;
    }

    final AccountBlockTemplate block = zenon!.embedded.stake.stake(
      _selectedStakeDuration!.inSeconds,
      _amount.extractDecimals(kZnnCoin.decimals),
    );

    context.read<SendTransactionBloc>().add(
      SendTransactionInitiateFromBlock(
        block: block,
        fromAddress: _addressController.text,
        reasonForGeneratingPlasma: context.l10n.createStake,
      ),
    );
  }

  void _onTransactionStateChanged(SendTransactionState state) {
    if (state.status == SendTransactionStatus.loading) {
      _stakeButtonKey.currentState?.animateForward();
    } else if (state.status == SendTransactionStatus.success) {
      _stakeButtonKey.currentState?.animateReverse();
      setState(() {
        _amountController.clear();
        _selectedStakeDuration = null;
      });
      widget.onStakeCreated();
      _fetchBalance();
    } else if (state.status == SendTransactionStatus.failure) {
      _stakeButtonKey.currentState?.animateReverse();
      unawaited(
        NotificationUtils.sendNotificationError(
          state.error!,
          context.l10n.errorWhileGeneratingStake,
        ),
      );
    }
  }
}

class _StakeButton extends StatelessWidget {
  const _StakeButton({
    required this.buttonKey,
    required this.isInputValid,
    required this.onPressed,
  });

  final GlobalKey<LoadingButtonState> buttonKey;
  final bool isInputValid;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    // TODO(maznnwell): when in loading state, the button should shrink
    return KeyedSubtree(
      key: const Key('create_stake_submit_button'),
      child: LoadingButton.icon(
        key: buttonKey,
        onPressed: isInputValid ? onPressed : null,
        label: context.l10n.stake,
        icon: const Icon(
          Icons.lock_clock,
        ),
      ),
    );
  }
}
