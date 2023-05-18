import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:stacked/stacked.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/utils/extensions.dart';
import 'package:zenon_syrius_wallet_flutter/utils/format_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:zenon_syrius_wallet_flutter/utils/input_validators.dart';
import 'package:zenon_syrius_wallet_flutter/utils/notification_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/zts_utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class StakingOptions extends StatefulWidget {
  final StakingListBloc? stakingListViewModel;

  const StakingOptions(
    this.stakingListViewModel, {
    Key? key,
  }) : super(key: key);

  @override
  State createState() {
    return _StakingOptionsState();
  }
}

class _StakingOptionsState extends State<StakingOptions> {
  Duration? _selectedStakeDuration;

  final List<Duration> _durations = List.generate(
      (stakeTimeMaxSec ~/ stakeTimeUnitSec),
      (index) => Duration(
            seconds: (index + 1) * stakeTimeUnitSec,
          ));

  BigInt _maxZnnAmount = BigInt.zero;

  double? _maxWidth;

  TextEditingController _znnAmountController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  GlobalKey<FormState> _znnAmountKey = GlobalKey();
  final GlobalKey<LoadingButtonState> _stakeButtonKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    sl.get<BalanceBloc>().getBalanceForAllAddresses();
  }

  @override
  Widget build(BuildContext context) {
    _addressController.text = kSelectedAddress!;

    return LayoutBuilder(
      builder: (_, constraints) {
        _maxWidth = constraints.maxWidth;
        return CardScaffold(
          title: 'Staking Options',
          description: 'This card displays information about staking per '
              'wallet address. Choose the duration and the amount in '
              '${kZnnCoin.symbol} for staking in order to receive '
              '${kQsrCoin.symbol}',
          childBuilder: () => StreamBuilder<Map<String, AccountInfo>?>(
            stream: sl.get<BalanceBloc>().stream,
            builder: (_, snapshot) {
              if (snapshot.hasError) {
                return SyriusErrorWidget(snapshot.error!);
              }
              if (snapshot.connectionState == ConnectionState.active) {
                if (snapshot.hasData) {
                  _maxZnnAmount =
                      snapshot.data![_addressController.text]!.getBalance(
                    kZnnCoin.tokenStandard,
                  );
                  return _getWidgetBody(
                    snapshot.data![_addressController.text],
                  );
                }
                return const SyriusLoadingWidget();
              }
              return const SyriusLoadingWidget();
            },
          ),
        );
      },
    );
  }

  Widget _getWidgetBody(AccountInfo? accountInfo) {
    return Container(
      margin: const EdgeInsets.all(
        20.0,
      ),
      child: ListView(
        shrinkWrap: true,
        children: [
          DisabledAddressField(
            _addressController,
            contentLeftPadding: 20.0,
          ),
          StepperUtils.getBalanceWidget(kZnnCoin, accountInfo!),
          Container(
            padding: const EdgeInsets.only(left: 20.0),
            decoration: BoxDecoration(
              color: Theme.of(context).inputDecorationTheme.fillColor,
              borderRadius: BorderRadius.circular(5.0),
            ),
            child: _getStakeDurationDropdown(),
          ),
          kVerticalSpacing,
          Form(
            key: _znnAmountKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: InputField(
              onChanged: (String value) {
                setState(() {});
              },
              inputFormatters: FormatUtils.getAmountTextInputFormatters(
                _znnAmountController.text,
              ),
              controller: _znnAmountController,
              validator: (value) => InputValidators.correctValue(
                value,
                _maxZnnAmount,
                kZnnCoin.decimals,
                stakeMinZnnAmount,
                canBeEqualToMin: true,
              ),
              suffixIcon: _getZnnAmountSuffix(),
              hintText: 'Amount',
              contentLeftPadding: 20.0,
            ),
          ),
          kVerticalSpacing,
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _getStakeForQsrViewModel(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _getStakeForQsrViewModel() {
    return ViewModelBuilder<StakingOptionsBloc>.reactive(
      onViewModelReady: (model) {
        model.stream.listen(
          (event) {
            if (event != null) {
              _stakeButtonKey.currentState?.animateReverse();
              widget.stakingListViewModel!.refreshResults();
              setState(() {
                _znnAmountController = TextEditingController();
                _znnAmountKey = GlobalKey();
                _selectedStakeDuration = null;
              });
            }
          },
          onError: (error) {
            _stakeButtonKey.currentState?.animateReverse();
            NotificationUtils.sendNotificationError(
              error,
              'Error while generating stake',
            );
          },
        );
      },
      builder: (_, model, __) => _getStakeForQsrButton(model),
      viewModelBuilder: () => StakingOptionsBloc(),
    );
  }

  Widget _getStakeForQsrButton(StakingOptionsBloc model) {
    Widget icon = Container(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.znnColor,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 5.0, vertical: 15.0),
      child: const Icon(
        MaterialCommunityIcons.lock_smart,
        size: 15.0,
        color: Colors.white,
      ),
    );

    return LoadingButton.icon(
      onPressed: _isInputValid() ? () => _onStakePressed(model) : null,
      label: 'Stake',
      icon: icon,
      key: _stakeButtonKey,
      minimumSize: Size(_maxWidth! - 2 * 20.0, 40.0),
    );
  }

  Widget _getStakeDurationDropdown() {
    return DropdownButtonHideUnderline(
      child: DropdownButton<Duration>(
        hint: Text(
          'Staking duration',
          style: Theme.of(context).inputDecorationTheme.hintStyle,
        ),
        icon: Container(
          margin: const EdgeInsets.symmetric(horizontal: 10.0),
          child: Icon(
            SimpleLineIcons.arrow_down,
            size: 10.0,
            color: Theme.of(context).inputDecorationTheme.hintStyle!.color,
          ),
        ),
        value: _selectedStakeDuration,
        items: _durations
            .map(
              (duration) => DropdownMenuItem<Duration>(
                value: duration,
                child: Text(
                  '${duration.inSeconds ~/ stakeTimeUnitSec} $stakeUnitDurationName'
                  '${(duration.inSeconds ~/ stakeTimeUnitSec) > 1 ? 's' : ''}',
                  style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                        fontSize: 12.0,
                        color: _selectedStakeDuration?.inDays == duration.inDays
                            ? AppColors.znnColor
                            : null,
                      ),
                ),
              ),
            )
            .toList(),
        onChanged: (value) {
          setState(() {
            _selectedStakeDuration = value;
          });
        },
      ),
    );
  }

  void _onStakePressed(StakingOptionsBloc? model) {
    if (_selectedStakeDuration != null &&
        _znnAmountKey.currentState!.validate() &&
        _znnAmountController.text.extractDecimals(coinDecimals) >=
            stakeMinZnnAmount) {
      _stakeButtonKey.currentState?.animateForward();
      model!.stakeForQsr(
        _selectedStakeDuration!,
        _znnAmountController.text.extractDecimals(coinDecimals),
      );
    }
  }

  Widget _getZnnAmountSuffix() {
    return AmountSuffixWidgets(
      kZnnCoin,
      onMaxPressed: _onMaxPressed,
    );
  }

  void _onMaxPressed() {
    setState(() {
      _znnAmountController.text = _maxZnnAmount.addDecimals(coinDecimals);
    });
  }

  bool _isInputValid() =>
      _selectedStakeDuration != null &&
      InputValidators.correctValue(
            _znnAmountController.text,
            _maxZnnAmount,
            kZnnCoin.decimals,
            stakeMinZnnAmount,
            canBeEqualToMin: true,
          ) ==
          null;
}
