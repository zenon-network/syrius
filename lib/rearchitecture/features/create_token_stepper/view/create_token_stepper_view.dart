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
                        context.l10n.tokenCreation,
                        context.l10n.nameAndSymbol,
                        context.l10n.options,
                        context.l10n.supply,
                        context.l10n.issue,
                      ],
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
            Expanded(
              child: completed
                  ? TokenCreatedSuccess(
                      tokenName: _tokenNameController.text,
                      onCreateAnotherTokenPressed:
                          _onCreateAnotherTokenPressed,
                      onViewTokensPressed: () => Navigator.of(context).pop(),
                    )
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
