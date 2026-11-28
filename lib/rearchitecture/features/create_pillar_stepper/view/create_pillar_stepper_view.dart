import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/extensions.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
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
        final BigInt znnHave = accountInfo.getBalance(kZnnCoin.tokenStandard);

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
                      steps: <String>[
                        context.l10n.plasmaCheck,
                        context.l10n.depositQsr,
                        context.l10n.management(kZnnCoin.symbol),
                        context.l10n.register,
                      ],
                      currentStep: stepIndex,
                    ),
                    const SizedBox(height: 20),
                    Divider(height: 1, color: tokens.border),
                    const SizedBox(height: 16),
                    _summaryRow(
                      tokens,
                      context.l10n.slotFee,
                      _qsrAmountController.text.isNotEmpty
                          ? '${_qsrAmountController.text} ${kQsrCoin.symbol}'
                          : '— ${kQsrCoin.symbol}',
                    ),
                    const SizedBox(height: 8),
                    _summaryRow(
                      tokens,
                      context.l10n.locks,
                      '${pillarRegisterZnnAmount.addDecimals(coinDecimals)} '
                      '${kZnnCoin.symbol}',
                    ),
                    const SizedBox(height: 8),
                    _summaryRow(
                      tokens,
                      context.l10n.have,
                      '${znnHave.addDecimals(coinDecimals)} ${kZnnCoin.symbol}',
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: completed
                  ? _buildCompletionPane(context, tokens)
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(28),
                      child: Align(
                        alignment: Alignment.topLeft,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 560),
                          child: _buildActiveStep(currentStep, accountInfo),
                        ),
                      ),
                    ),
            ),
          ],
        );
      },
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
      _Step.deployPillar => DeployPillarStep(onDeployDone: _onDeployDone),
    };
  }

  Widget _buildCompletionPane(BuildContext context, SyriusThemeTokens tokens) {
    return Center(
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
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              SyriusGradientButton(
                label: context.l10n.viewPillar,
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 22),
                onPressed: () => Navigator.of(context).pop(),
              ),
              const SizedBox(width: 10),
              SyriusPillButton(
                label: context.l10n.done,
                height: 38,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ],
      ),
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
