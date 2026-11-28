import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/extensions.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:zenon_syrius_wallet_flutter/utils/zts_utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

enum _Step {
  checkPlasma,
  tokenCreation,
  tokenDetails,
  tokenMintableBurnable,
  tokenMetrics,
  issueToken,
}

/// Split-pane stepper guiding the user through creating a ZTS token
/// (Screen 25).
class CreateTokenStepperView extends StatefulWidget {
  /// Creates a [CreateTokenStepperView].
  const CreateTokenStepperView({super.key});

  @override
  State<CreateTokenStepperView> createState() => _CreateTokenStepperViewState();
}

class _CreateTokenStepperViewState extends State<CreateTokenStepperView> {
  final ValueNotifier<_Step?> _currentStep = ValueNotifier<_Step?>(
    _Step.checkPlasma,
  );

  final TextEditingController _addressController = TextEditingController(
    text: kSelectedAddress,
  );
  final TextEditingController _tokenNameController = TextEditingController();
  final TextEditingController _totalSupplyController = TextEditingController();
  final TextEditingController _maxSupplyController = TextEditingController();
  final TextEditingController _tokenDomainController = TextEditingController();
  final TextEditingController _tokenSymbolController = TextEditingController();

  final ValueNotifier<NewTokenData> _tokenData = ValueNotifier<NewTokenData>(
    NewTokenData.initial(address: kSelectedAddress!),
  );

  @override
  void initState() {
    super.initState();
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
    final BigInt znnHave = accountInfo.getBalance(kZnnCoin.tokenStandard);

    return ValueListenableBuilder<_Step?>(
      valueListenable: _currentStep,
      builder: (_, _Step? currentStep, _) {
        final bool completed = currentStep == null;
        final int stepIndex = completed
            ? _Step.values.length
            : currentStep.index;
        final List<String> steps = <String>[
          context.l10n.plasmaCheck,
          context.l10n.tokenCreation,
          context.l10n.nameAndSymbol,
          context.l10n.options,
          context.l10n.supply,
          context.l10n.issue,
        ];

        return LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool isCompact = constraints.maxWidth < 900;
            final Widget stepPane = completed
                ? TokenCreatedSuccess(
                    tokenName: _tokenNameController.text,
                    onCreateAnotherTokenPressed: _onCreateAnotherTokenPressed,
                    onViewTokensPressed: () => Navigator.of(context).pop(),
                  )
                : SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: isCompact ? 20 : 28,
                      vertical: isCompact ? 16 : 28,
                    ),
                    child: Align(
                      alignment: Alignment.topLeft,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: isCompact ? double.infinity : 600,
                        ),
                        child: ValueListenableBuilder<NewTokenData>(
                          valueListenable: _tokenData,
                          builder: (_, _, _) =>
                              _buildActiveStep(currentStep, accountInfo),
                        ),
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
                        Row(
                          children: <Widget>[
                            SizedBox(
                              width: 54,
                              child: Text(
                                context.l10n.fee.toUpperCase(),
                                style: tokens.microLabelStyle(),
                              ),
                            ),
                            Text(
                              '1 ${kZnnCoin.symbol} ',
                              style: tokens.monoStyle(
                                fontSize: 12.5,
                                color: tokens.textPrimary,
                              ),
                            ),
                            Text(
                              context.l10n.burned,
                              style: TextStyle(
                                fontSize: 12,
                                color: tokens.textMuted,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: <Widget>[
                            SizedBox(
                              width: 54,
                              child: Text(
                                context.l10n.have.toUpperCase(),
                                style: tokens.microLabelStyle(),
                              ),
                            ),
                            Expanded(
                              child: Text(
                                '${znnHave.addDecimals(coinDecimals)} '
                                '${kZnnCoin.symbol}',
                                style: tokens.monoStyle(
                                  fontSize: 12.5,
                                  color: tokens.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 18),
                        _buildTokenPreviewCard(context, tokens),
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
                  width: 16,
                  height: 1,
                  margin: const EdgeInsets.symmetric(horizontal: 6),
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

  Widget _buildTokenPreviewCard(
    BuildContext context,
    SyriusThemeTokens tokens,
  ) {
    return ListenableBuilder(
      listenable: Listenable.merge(<Listenable>[
        _tokenNameController,
        _tokenSymbolController,
      ]),
      builder: (_, _) {
        final String name = _tokenNameController.text.trim().isEmpty
            ? context.l10n.tokenName
            : _tokenNameController.text.trim();
        final String symbol = _tokenSymbolController.text.trim().isEmpty
            ? 'ZTS'
            : _tokenSymbolController.text.trim().toUpperCase();

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: tokens.surfaceSubtle,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: tokens.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                context.l10n.preview.toUpperCase(),
                style: tokens.microLabelStyle(),
              ),
              const SizedBox(height: 10),
              Row(
                children: <Widget>[
                  SyriusTokenAvatar(symbol: symbol, size: 30),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          name,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                            color: tokens.textPrimary,
                          ),
                        ),
                        Text(
                          '$symbol · zts1…',
                          style: tokens.monoStyle(
                            fontSize: 11,
                            color: tokens.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActiveStep(_Step step, AccountInfo accountInfo) {
    return switch (step) {
      _Step.checkPlasma => TokenPlasmaCheckStep(
        addressController: _addressController,
        onNextPressed: _navigateToNextStep,
      ),
      _Step.tokenCreation => TokenZnnCheckStep(
        accountInfo: accountInfo,
        addressController: _addressController,
        onContinuePressed: _navigateToNextStep,
        tokenData: _tokenData,
      ),
      _Step.tokenDetails => TokenDetailsStep(
        onBackPressed: _onBackButtonPressed,
        onContinuePressed: _navigateToNextStep,
        tokenData: _tokenData,
        tokenDomainController: _tokenDomainController,
        tokenNameController: _tokenNameController,
        tokenSymbolController: _tokenSymbolController,
      ),
      _Step.tokenMintableBurnable => TokenMintableBurnableStep(
        onBackPressed: _onBackButtonPressed,
        onContinuePressed: _onTokenMintableBurnableContinuePressed,
        tokenData: _tokenData,
      ),
      _Step.tokenMetrics => TokenMetricsStep(
        maxSupplyController: _maxSupplyController,
        onBackPressed: _onBackButtonPressed,
        onContinuePressed: _navigateToNextStep,
        tokenData: _tokenData,
        totalSupplyController: _totalSupplyController,
      ),
      _Step.issueToken => IssueTokenStep(
        onBackPressed: _onBackButtonPressed,
        onIssueDone: _onIssueDone,
        onIssuePressed: _onCreatePressed,
        tokenData: _tokenData,
      ),
    };
  }

  void _onBackButtonPressed() {
    final _Step? currentStep = _currentStep.value;
    if (currentStep == null || currentStep.index == 0) {
      return;
    }
    _currentStep.value = _Step.values[currentStep.index - 1];
  }

  void _onCreateAnotherTokenPressed() {
    _tokenNameController.clear();
    _tokenSymbolController.clear();
    _totalSupplyController.clear();
    _maxSupplyController.clear();
    _tokenDomainController.clear();
    _tokenData.value = NewTokenData.initial(address: _addressController.text);
    _currentStep.value = _Step.checkPlasma;
  }

  void _navigateToNextStep() {
    final int currentStepIndex = _currentStep.value!.index;
    _currentStep.value = _Step.values[currentStepIndex + 1];
  }

  void _onCreatePressed() {
    context.read<IssueTokenBloc>().add(
      IssueTokenRequested(tokenData: _tokenData.value),
    );
  }

  void _onIssueDone() {
    _currentStep.value = null;
    context.read<AllTokensBloc>().add(const AllTokensRequested());
  }

  void _onTokenMintableBurnableContinuePressed() {
    if (_tokenData.value.isMintable && _totalSupplyController.text.isNotEmpty) {
      _maxSupplyController.text = _totalSupplyController.text;
    }
    _navigateToNextStep();
  }

  @override
  void dispose() {
    _addressController.dispose();
    _tokenNameController.dispose();
    _totalSupplyController.dispose();
    _maxSupplyController.dispose();
    _tokenDomainController.dispose();
    _tokenSymbolController.dispose();
    _currentStep.dispose();
    _tokenData.dispose();
    super.dispose();
  }
}
