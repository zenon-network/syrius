import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/tokens/cubit/tokens_cubit.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';
import 'package:zenon_syrius_wallet_flutter/utils/extensions.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/custom_material_stepper.dart'
    as syrius_stepper;
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

/// A stepper that guides the user through creating a ZTS token.
class CreateTokenStepperView extends StatefulWidget {
  /// Creates a [CreateTokenStepperView].
  const CreateTokenStepperView({super.key});

  @override
  State createState() {
    return _CreateTokenStepperViewState();
  }
}

class _CreateTokenStepperViewState extends State<CreateTokenStepperView> {
  // When value is null, it means the stepper has completed.
  final ValueNotifier<_Step?> _currentStep = ValueNotifier<_Step?>(
    _Step.checkPlasma,
  );

  final TextEditingController _addressController = TextEditingController();
  TextEditingController _tokenNameController = TextEditingController();
  TextEditingController _totalSupplyController = TextEditingController();
  TextEditingController _maxSupplyController = TextEditingController();
  TextEditingController _tokenDomainController = TextEditingController();
  TextEditingController _tokenSymbolController = TextEditingController();

  final ValueNotifier<int> _selectedNumDecimals = .new(0);

  bool _isMintable = false;
  bool _isBurnable = false;
  bool _isUtility = true;

  final NewTokenData _tokenStepperData = NewTokenData();

  @override
  void initState() {
    super.initState();
    _addressController.text = kSelectedAddress!;
    sl.get<MultipleBalanceBloc>().add(
      MultipleBalanceFetch(
        addresses: kDefaultAddressList.map((String? e) => e!).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<MultipleBalanceBloc, MultipleBalanceState>(
      builder: (_, MultipleBalanceState state) => switch (state.status) {
        MultipleBalanceStatus.failure => SyriusErrorWidget(state.error!),
        MultipleBalanceStatus.initial => const SyriusLoadingWidget(),
        MultipleBalanceStatus.loading => const SyriusLoadingWidget(),
        MultipleBalanceStatus.success => _buildBody(
          context,
          state.data![_addressController.text]!,
        ),
      },
    );
  }

  Widget _buildMaterialStepper({
    required AccountInfo accountInfo,
    required _Step? currentStep,
  }) {
    final int lastStepIndex = _Step.values.last.index;

    syrius_stepper.StepState getStepState(
      _Step step,
      _Step? currentStep,
    ) {
      return step.index < (currentStep?.index ?? lastStepIndex + 1)
          ? syrius_stepper.StepState.complete
          : syrius_stepper.StepState.indexed;
    }

    return Theme(
      data: Theme.of(context).copyWith(
        highlightColor: Colors.transparent,
        splashColor: Colors.transparent,
        hoverColor: Colors.transparent,
      ),
      child: syrius_stepper.Stepper(
        activeColor: AppColors.ztsColor,
        currentStep: currentStep?.index ?? lastStepIndex,
        onStepTapped: (int index) {},
        steps: <syrius_stepper.Step>[
          StepperUtils.getMaterialStep(
            stepTitle: context.l10n.plasmaCheck,
            stepContent: TokenPlasmaCheckStep(
              addressController: _addressController,
              onNextPressed: _navigateToNextStep,
            ),
            stepSubtitle: context.l10n.sufficientPlasma,
            stepState: getStepState(
              _Step.checkPlasma,
              currentStep,
            ),
            context: context,
            stepSubtitleColor: AppColors.ztsColor,
          ),
          StepperUtils.getMaterialStep(
            stepTitle: context.l10n.tokenCreation,
            stepContent: TokenCreationStep(
              accountInfo: accountInfo,
              addressController: _addressController,
              onContinuePressed: _onTokenCreationContinuePressed,
            ),
            stepSubtitle: _addressController.text,
            stepState: getStepState(
              _Step.tokenCreation,
              currentStep,
            ),
            context: context,
            stepSubtitleColor: AppColors.ztsColor,
          ),
          StepperUtils.getMaterialStep(
            stepTitle: context.l10n.tokenDetails,
            stepContent: TokenDetailsStep(
              onBackPressed: _onBackButtonPressed,
              onContinuePressed: _onTokenDetailsContinuePressed,
              tokenDomainController: _tokenDomainController,
              tokenNameController: _tokenNameController,
              tokenSymbolController: _tokenSymbolController,
            ),
            stepSubtitle:
                '${_tokenNameController.text} ${_tokenSymbolController.text}',
            stepState: getStepState(
              _Step.tokenDetails,
              currentStep,
            ),
            context: context,
            stepSubtitleColor: AppColors.ztsColor,
          ),
          StepperUtils.getMaterialStep(
            stepTitle: context.l10n.tokenMintableBurnableOptions,
            stepContent: TokenMintableBurnableStep(
              isBurnable: _isBurnable,
              isMintable: _isMintable,
              onBackPressed: _onBackButtonPressed,
              onBurnableChanged: _onBurnableChanged,
              onContinuePressed: _navigateToNextStep,
              onMintableChanged: _onMintableChanged,
            ),
            stepSubtitle: context.l10n.tokenMintableBurnableSubtitle(
              _isBurnable ? context.l10n.yes : context.l10n.no,
              _isMintable ? context.l10n.yes : context.l10n.no,
            ),
            stepState: getStepState(
              _Step.tokenMintableBurnable,
              currentStep,
            ),
            stepSubtitleColor: AppColors.ztsColor,
            context: context,
          ),
          StepperUtils.getMaterialStep(
            stepTitle: context.l10n.tokenMetrics,
            stepContent: TokenMetricsStep(
              isMintable: _isMintable,
              maxSupplyController: _maxSupplyController,
              onBackPressed: _onBackButtonPressed,
              onContinuePressed: _onTokenMetricsContinuePressed,
              selectedNumDecimals: _selectedNumDecimals,
              totalSupplyController: _totalSupplyController,
            ),
            stepSubtitle:
                '${_totalSupplyController.text} '
                '${_tokenSymbolController.text}',
            stepState: getStepState(
              _Step.tokenMetrics,
              currentStep,
            ),
            context: context,
            stepSubtitleColor: AppColors.ztsColor,
            stepSubtitleIconData: Icons.whatshot,
          ),
          StepperUtils.getMaterialStep(
            stepTitle: context.l10n.issueToken,
            stepContent: IssueTokenStep(
              isUtility: _isUtility,
              onBackPressed: _onBackButtonPressed,
              onIssueDone: _onIssueDone,
              onIssuePressed: _onCreatePressed,
              onUtilityChanged: _onUtilityChanged,
            ),
            stepSubtitle: _isMintable
                ? context.l10n.tokenSupplyOutOfMax(
                    _maxSupplyController.text,
                    _tokenSymbolController.text,
                    _totalSupplyController.text,
                  )
                : _isUtility
                ? context.l10n.utilityToken
                : '',
            stepState: getStepState(
              _Step.issueToken,
              currentStep,
            ),
            context: context,
            stepSubtitleColor: AppColors.ztsColor,
          ),
        ],
      ),
    );
  }

  void _onBackButtonPressed() {
    final _Step? currentStep = _currentStep.value;

    if (currentStep == null || currentStep.index == 0) {
      return;
    }

    _currentStep.value = _Step.values[currentStep.index - 1];
  }

  Widget _buildBody(BuildContext context, AccountInfo accountInfo) {
    return ValueListenableBuilder<_Step?>(
      valueListenable: _currentStep,
      builder: (_, _Step? currentStep, _) {
        final bool hasTokenBeenCreated = currentStep == null;

        return Stack(
          children: <Widget>[
            ListView(
              children: <Widget>[
                _buildMaterialStepper(
                  accountInfo: accountInfo,
                  currentStep: currentStep,
                ),
                if (hasTokenBeenCreated)
                  TokenCreatedSuccess(
                    onCreateAnotherTokenPressed: _onCreateAnotherTokenPressed,
                    onViewTokensPressed: () {
                      Navigator.pop(context);
                    },
                  ),
              ],
            ),
            if (hasTokenBeenCreated) const TokenCreatedSuccessAnimation(),
          ],
        );
      },
    );
  }

  void _onCreateAnotherTokenPressed() {
    _tokenNameController.dispose();
    _tokenSymbolController.dispose();
    _totalSupplyController.dispose();
    _maxSupplyController.dispose();
    _tokenDomainController.dispose();

    _tokenNameController = TextEditingController();
    _tokenSymbolController = TextEditingController();
    _totalSupplyController = TextEditingController();
    _maxSupplyController = TextEditingController();
    _tokenDomainController = TextEditingController();
    _selectedNumDecimals.value = 0;
    _isMintable = false;
    _isBurnable = false;
    _isUtility = true;
    setState(() {});
    _currentStep.value = _Step.checkPlasma;
  }

  void _onTokenCreationContinuePressed() {
    _tokenStepperData.address = _addressController.text;
    _navigateToNextStep();
  }

  void _navigateToNextStep() {
    final int currentStepIndex = _currentStep.value!.index;
    _currentStep.value = _Step.values[currentStepIndex + 1];
  }

  void _onCreatePressed() {
    _tokenStepperData.isUtility = _isUtility;
    context.read<IssueTokenBloc>().add(
      IssueTokenRequested(tokenData: _tokenStepperData),
    );
  }

  void _onIssueDone() {
    _currentStep.value = null;
    unawaited(sl.get<TokensCubit>().fetch());
  }

  void _onUtilityChanged(bool value) {
    setState(() {
      _isUtility = value;
    });
  }

  void _onMintableChanged(bool value) {
    setState(() {
      if (value && _totalSupplyController.text.isNotEmpty) {
        _maxSupplyController.text = _totalSupplyController.text;
      }
      _isMintable = value;
    });
  }

  void _onBurnableChanged(bool value) {
    setState(() {
      _isBurnable = value;
    });
  }

  void _onTokenDetailsContinuePressed() {
    _tokenStepperData.tokenName = _tokenNameController.text;
    _tokenStepperData.tokenSymbol = _tokenSymbolController.text;
    _tokenStepperData.tokenDomain = _tokenDomainController.text;
    _navigateToNextStep();
  }

  void _onTokenMetricsContinuePressed() {
    final int decimals = _selectedNumDecimals.value;

    _tokenStepperData.decimals = decimals;
    _tokenStepperData.totalSupply = _totalSupplyController.text
        .extractDecimals(decimals);
    _tokenStepperData.isMintable = _isMintable;
    _tokenStepperData.maxSupply = (_isMintable
        ? _maxSupplyController.text.extractDecimals(decimals)
        : _totalSupplyController.text.extractDecimals(decimals));
    _tokenStepperData.isOwnerBurnOnly = _isBurnable;
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
    super.dispose();
  }
}
