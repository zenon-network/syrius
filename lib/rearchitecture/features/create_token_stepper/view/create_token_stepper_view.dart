import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';
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

  final TextEditingController _addressController = TextEditingController(
    text: kSelectedAddress,
  );
  final TextEditingController _tokenNameController = TextEditingController();
  final TextEditingController _totalSupplyController = TextEditingController();
  final TextEditingController _maxSupplyController = TextEditingController();
  final TextEditingController _tokenDomainController = TextEditingController();
  final TextEditingController _tokenSymbolController = TextEditingController();

  final ValueNotifier<int> _selectedNumDecimals = .new(0);

  final ValueNotifier<NewTokenData> _tokenData = .new(
    NewTokenData.initial(address: kSelectedAddress!),
  );

  @override
  void initState() {
    super.initState();
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

    return ValueListenableBuilder<NewTokenData>(
      valueListenable: _tokenData,
      builder: (_, NewTokenData value, _) {
        final bool isBurnable = value.isBurnable;
        final bool isMintable = value.isMintable;
        final bool isUtility = value.isUtility;

        return syrius_stepper.Stepper(
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
              stepContent: TokenZnnCheckStep(
                accountInfo: accountInfo,
                addressController: _addressController,
                onContinuePressed: _navigateToNextStep,
                tokenData: _tokenData,
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
                onContinuePressed: _navigateToNextStep,
                tokenData: _tokenData,
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
                onBackPressed: _onBackButtonPressed,
                onContinuePressed: _onTokenMintableBurnableContinuePressed,
                tokenData: _tokenData,
              ),
              stepSubtitle: context.l10n.tokenMintableBurnableSubtitle(
                isBurnable ? context.l10n.yes : context.l10n.no,
                isMintable ? context.l10n.yes : context.l10n.no,
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
                maxSupplyController: _maxSupplyController,
                onBackPressed: _onBackButtonPressed,
                onContinuePressed: _navigateToNextStep,
                selectedNumDecimals: _selectedNumDecimals,
                tokenData: _tokenData,
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
                onBackPressed: _onBackButtonPressed,
                onIssueDone: _onIssueDone,
                onIssuePressed: _onCreatePressed,
                tokenData: _tokenData,
              ),
              stepSubtitle: isMintable
                  ? context.l10n.tokenSupplyOutOfMax(
                      _maxSupplyController.text,
                      _tokenSymbolController.text,
                      _totalSupplyController.text,
                    )
                  : isUtility
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
        );
      },
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
    _tokenNameController.clear();
    _tokenSymbolController.clear();
    _totalSupplyController.clear();
    _maxSupplyController.clear();
    _tokenDomainController.clear();
    _selectedNumDecimals.value = 0;
    _tokenData.value = NewTokenData.initial(
      address: _addressController.text,
    );
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
