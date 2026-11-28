import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/extensions.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:zenon_syrius_wallet_flutter/utils/notifiers/app_ui_preferences_notifier.dart';
import 'package:zenon_syrius_wallet_flutter/utils/zts_utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

enum _Step { checkPlasma, qsrManagement, znnManagement, deployPillar }

/// Split-pane stepper guiding the user through spawning a Pillar
/// (Screens 19–20).
class CreatePillarStepperView extends StatefulWidget {
  /// Creates a [CreatePillarStepperView].
  const CreatePillarStepperView({super.key});

  @override
  State<CreatePillarStepperView> createState() => _MainPillarState();
}

class _MainPillarState extends State<CreatePillarStepperView> {
  final TextEditingController _qsrAmountController = TextEditingController();
  final TextEditingController _znnAmountController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  // When value is null, it means the stepper has completed.
  final ValueNotifier<_Step?> _currentStep = ValueNotifier<_Step?>(
    _Step.checkPlasma,
  );
  String? _registeredPillarName;

  bool _isHideBalancesEnabled(BuildContext context) {
    try {
      return context.watch<AppUiPreferencesNotifier>().hideBalances;
    } on ProviderNotFoundException {
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    _znnAmountController.text = pillarRegisterZnnAmount.addDecimals(
      coinDecimals,
    );
    _addressController.text = kSelectedAddress!;
    sl.get<MultipleBalanceBloc>().add(
      MultipleBalanceFetch(
        addresses: kDefaultAddressList.whereType<String>().toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MultipleBalanceBloc, MultipleBalanceState>(
      builder: (_, MultipleBalanceState state) => switch (state.status) {
        MultipleBalanceStatus.failure => SyriusErrorWidget(state.error!),
        MultipleBalanceStatus.initial ||
        MultipleBalanceStatus.loading => const SyriusLoadingWidget(),
        MultipleBalanceStatus.success => _buildBody(
          context,
          state.data![_addressController.text]!,
        ),
      },
    );
  }

  Widget _buildBody(BuildContext context, AccountInfo accountInfo) {
    final SyriusThemeTokens tokens = context.syriusTheme;

    return ValueListenableBuilder<_Step?>(
      valueListenable: _currentStep,
      builder: (_, _Step? currentStep, _) {
        final bool completed = currentStep == null;
        final int stepIndex = completed
            ? _Step.values.length
            : currentStep.index;
        final bool hideBalances = _isHideBalancesEnabled(context);
        final BigInt znnHave = accountInfo.getBalance(kZnnCoin.tokenStandard);
        final String haveValue = hideBalances
            ? '•••••• ${kZnnCoin.symbol}'
            : '${znnHave.addDecimals(coinDecimals)} ${kZnnCoin.symbol}';
        final String lockedZnn = pillarRegisterZnnAmount.addDecimals(
          coinDecimals,
        );
        final List<String> steps = <String>[
          context.l10n.plasmaCheck,
          context.l10n.depositQsr,
          context.l10n.management(kZnnCoin.symbol),
          context.l10n.register,
        ];

        return LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool isCompact = constraints.maxWidth < 900;
            final double stepMaxWidth = currentStep == _Step.qsrManagement
                ? 820
                : 600;
            final Widget stepPane = completed
                ? _buildCompletionPane(context, tokens)
                : SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: isCompact ? 20 : 28,
                      vertical: isCompact ? 16 : 28,
                    ),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: isCompact ? double.infinity : stepMaxWidth,
                        ),
                        child: _buildActiveStep(currentStep, accountInfo),
                      ),
                    ),
                  );

            if (isCompact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  _buildCompactStepBar(tokens, steps, stepIndex),
                  Expanded(child: stepPane),
                ],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Container(
                  width: 260,
                  decoration: BoxDecoration(
                    border: Border(right: BorderSide(color: tokens.border)),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        SyriusVerticalStepRail(
                          steps: steps,
                          currentStep: stepIndex,
                        ),
                        const SizedBox(height: 20),
                        Divider(height: 1, color: tokens.border),
                        const SizedBox(height: 16),
                        BlocBuilder<
                          CreatePillarQsrInfoBloc,
                          FetchState<CreatePillarQsrInfoData>
                        >(
                          builder:
                              (
                                _,
                                FetchState<CreatePillarQsrInfoData> qsrState,
                              ) {
                                final String slotFeeValue = switch (qsrState) {
                                  FetchPopulated<CreatePillarQsrInfoData>(
                                    :final CreatePillarQsrInfoData data,
                                  ) =>
                                    '${data.cost.addDecimals(coinDecimals)} '
                                        '${kQsrCoin.symbol}',
                                  _ => '— ${kQsrCoin.symbol}',
                                };
                                return _summaryRow(
                                  tokens,
                                  context.l10n.slotFee,
                                  slotFeeValue,
                                );
                              },
                        ),
                        const SizedBox(height: 8),
                        _summaryRow(
                          tokens,
                          context.l10n.locks,
                          '$lockedZnn ${kZnnCoin.symbol}',
                        ),
                        const SizedBox(height: 8),
                        _summaryRow(tokens, context.l10n.have, haveValue),
                      ],
                    ),
                  ),
                ),
                Expanded(child: stepPane),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildCompactStepBar(
    SyriusThemeTokens tokens,
    List<String> steps,
    int currentStep,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: tokens.border)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: <Widget>[
            for (int i = 0; i < steps.length; i++) ...<Widget>[
              if (i > 0)
                Container(
                  width: 20,
                  height: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 8),
                  color: i <= currentStep
                      ? tokens.znnGreen.withValues(alpha: 0.45)
                      : tokens.border,
                ),
              _buildCompactStepChip(tokens, i, steps[i], currentStep),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCompactStepChip(
    SyriusThemeTokens tokens,
    int index,
    String label,
    int currentStep,
  ) {
    final bool completed = index < currentStep;
    final bool active = index == currentStep;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Container(
          width: 20,
          height: 20,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: completed ? tokens.znnGreen : Colors.transparent,
            border: Border.all(
              color: completed || active ? tokens.znnGreen : tokens.border,
              width: 1.4,
            ),
          ),
          child: completed
              ? Icon(
                  Icons.check,
                  size: 12,
                  color: tokens.gradientButtonForeground,
                )
              : Text(
                  '${index + 1}',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: active ? tokens.znnGreen : tokens.textMuted,
                  ),
                ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: active ? FontWeight.w600 : FontWeight.w400,
            color: active ? tokens.textPrimary : tokens.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _summaryRow(SyriusThemeTokens tokens, String label, String value) {
    return Row(
      children: <Widget>[
        SizedBox(
          width: 72,
          child: Text(label.toUpperCase(), style: tokens.microLabelStyle()),
        ),
        Expanded(
          child: Text(
            value,
            style: tokens.monoStyle(fontSize: 12.5, color: tokens.textPrimary),
          ),
        ),
      ],
    );
  }

  Widget _buildActiveStep(_Step step, AccountInfo accountInfo) {
    return switch (step) {
      _Step.checkPlasma => PillarPlasmaCheckStep(
        addressController: _addressController,
        onNextPressed: _onPlasmaCheckNextPressed,
      ),
      _Step.qsrManagement => PillarQsrManagementStep(
        accountInfo: accountInfo,
        addressController: _addressController,
        onNextPressed: _navigateToNextStep,
        qsrAmountController: _qsrAmountController,
      ),
      _Step.znnManagement => PillarZnnManagementStep(
        accountInfo: accountInfo,
        addressController: _addressController,
        onNextPressed: _navigateToNextStep,
        znnAmountController: _znnAmountController,
      ),
      _Step.deployPillar => DeployPillarStep(
        onDeployDone: _onDeployDone,
        onDeployDoneWithName: (String name) {
          _registeredPillarName = name;
        },
      ),
    };
  }

  Widget _buildCompletionPane(BuildContext context, SyriusThemeTokens tokens) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            SizedBox.square(
              dimension: 180,
              child: Lottie.asset(
                'assets/lottie/ic_anim_pillar.json',
                repeat: false,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              context.l10n.pillarRegistered,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: tokens.textPrimary,
              ),
            ),
            const SizedBox(height: 22),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.center,
              children: <Widget>[
                SyriusGradientButton(
                  label: context.l10n.viewPillar,
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  onPressed: () =>
                      Navigator.of(context).pop<String>(_registeredPillarName),
                ),
                SyriusPillButton(
                  label: context.l10n.registerAnotherPillar,
                  height: 38,
                  onPressed: _onRegisterAnotherPressed,
                ),
                SyriusPillButton(
                  label: context.l10n.done,
                  height: 38,
                  onPressed: () => Navigator.of(context).pop<String>(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _onRegisterAnotherPressed() {
    _registeredPillarName = null;
    _qsrAmountController.clear();
    _currentStep.value = _Step.checkPlasma;
    sl.get<MultipleBalanceBloc>().add(
      MultipleBalanceFetch(
        addresses: kDefaultAddressList.whereType<String>().toList(),
      ),
    );
    context.read<CreatePillarQsrInfoBloc>().add(
      FetchRequestData(address: Address.parse(_addressController.text)),
    );
  }

  void _onDeployDone() {
    _currentStep.value = null;
  }

  void _navigateToNextStep() {
    final int currentStepIndex = _currentStep.value!.index;
    _currentStep.value = _Step.values[currentStepIndex + 1];
  }

  void _onPlasmaCheckNextPressed() {
    _navigateToNextStep();
    context.read<CreatePillarQsrInfoBloc>().add(
      FetchRequestData(address: Address.parse(_addressController.text)),
    );
  }

  @override
  void dispose() {
    _qsrAmountController.dispose();
    _znnAmountController.dispose();
    _addressController.dispose();
    _currentStep.dispose();
    super.dispose();
  }
}
