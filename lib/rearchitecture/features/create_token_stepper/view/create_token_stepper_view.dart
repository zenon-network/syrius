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
import 'package:zenon_syrius_wallet_flutter/utils/input_validators.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/custom_material_stepper.dart'
    as custom_material_stepper;
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
  late _Step _currentStep;
  _Step? _lastCompletedStep;

  final int _numSteps = _Step.values.length;

  final TextEditingController _addressController = TextEditingController();
  TextEditingController _tokenNameController = TextEditingController();
  TextEditingController _totalSupplyController = TextEditingController();
  TextEditingController _maxSupplyController = TextEditingController();
  TextEditingController _tokenDomainController = TextEditingController();
  TextEditingController _tokenSymbolController = TextEditingController();

  GlobalKey<FormState> _maxSupplyKey = GlobalKey();
  GlobalKey<FormState> _totalSupplyKey = GlobalKey();

  int _selectedNumDecimals = 0;

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
    _initStepperControllers();
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

  Widget _buildMaterialStepper(BuildContext context, AccountInfo accountInfo) {
    return Theme(
      data: Theme.of(context).copyWith(
        highlightColor: Colors.transparent,
        splashColor: Colors.transparent,
        hoverColor: Colors.transparent,
      ),
      child: custom_material_stepper.Stepper(
        activeColor: AppColors.ztsColor,
        currentStep: _currentStep.index,
        onStepTapped: (int index) {},
        steps: <custom_material_stepper.Step>[
          StepperUtils.getMaterialStep(
            stepTitle: context.l10n.plasmaCheck,
            stepContent: TokenPlasmaCheckStep(
              addressController: _addressController,
              onNextPressed: _onPlasmaCheckNextPressed,
            ),
            stepSubtitle: context.l10n.sufficientPlasma,
            stepState: StepperUtils.getStepState(
              _Step.checkPlasma.index,
              _lastCompletedStep?.index,
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
            stepState: StepperUtils.getStepState(
              _Step.tokenCreation.index,
              _lastCompletedStep?.index,
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
            stepState: StepperUtils.getStepState(
              _Step.tokenDetails.index,
              _lastCompletedStep?.index,
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
              onContinuePressed: _onMintableBurnableContinuePressed,
              onMintableChanged: _onMintableChanged,
            ),
            stepSubtitle: context.l10n.tokenMintableBurnableSubtitle(
              _isBurnable ? context.l10n.yes : context.l10n.no,
              _isMintable ? context.l10n.yes : context.l10n.no,
            ),
            stepState: StepperUtils.getStepState(
              _Step.tokenMintableBurnable.index,
              _lastCompletedStep?.index,
            ),
            stepSubtitleColor: AppColors.ztsColor,
            context: context,
          ),
          StepperUtils.getMaterialStep(
            stepTitle: context.l10n.tokenMetrics,
            stepContent: TokenMetricsStep(
              isContinueEnabled: _areTokenMetricsCorrect(),
              isMintable: _isMintable,
              maxSupplyController: _maxSupplyController,
              maxSupplyKey: _maxSupplyKey,
              onBackPressed: _onBackButtonPressed,
              onChanged: (_) {},
              onContinuePressed: _onTokenMetricsContinuePressed,
              onDecimalsChanged: _onDecimalsChanged,
              selectedNumDecimals: _selectedNumDecimals,
              totalSupplyController: _totalSupplyController,
              totalSupplyKey: _totalSupplyKey,
            ),
            stepSubtitle:
                '${_totalSupplyController.text} '
                '${_tokenSymbolController.text}',
            stepState: StepperUtils.getStepState(
              _Step.tokenMetrics.index,
              _lastCompletedStep?.index,
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
            stepState: StepperUtils.getStepState(
              _Step.issueToken.index,
              _lastCompletedStep?.index,
            ),
            context: context,
            stepSubtitleColor: AppColors.ztsColor,
          ),
        ],
      ),
    );
  }

  void _onPlasmaCheckNextPressed() {
    if (_lastCompletedStep == null) {
      _saveProgressAndNavigateToNextStep(_Step.checkPlasma);
    } else if (StepperUtils.getStepState(
          _Step.checkPlasma.index,
          _lastCompletedStep?.index,
        ) ==
        custom_material_stepper.StepState.complete) {
      setState(() {
        _currentStep = _Step.values[_currentStep.index + 1];
      });
    }
  }

  void _onBackButtonPressed() {
    if (_currentStep.index > 0) {
      if (StepperUtils.getStepState(
            _currentStep.index,
            _lastCompletedStep?.index,
          ) !=
          custom_material_stepper.StepState.complete) {
        setState(() {
          _currentStep = _Step.values[_currentStep.index - 1];
        });
      }
    }
  }

  Widget _buildBody(BuildContext context, AccountInfo accountInfo) {
    return Stack(
      children: <Widget>[
        ListView(
          children: <Widget>[
            _buildMaterialStepper(context, accountInfo),
            Visibility(
              visible: (_lastCompletedStep?.index ?? -1) == _numSteps - 1,
              child: TokenCreatedSuccess(
                onCreateAnotherTokenPressed: _onCreateAnotherTokenPressed,
                onViewTokensPressed: () {
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
        if ((_lastCompletedStep?.index ?? -1) == _numSteps - 1)
          const TokenCreatedSuccessAnimation(),
      ],
    );
  }

  void _onCreateAnotherTokenPressed() {
    _tokenNameController = TextEditingController();
    _tokenSymbolController = TextEditingController();
    _totalSupplyKey = GlobalKey();
    _totalSupplyController = TextEditingController();
    _maxSupplyKey = GlobalKey();
    _maxSupplyController = TextEditingController();
    _tokenDomainController = TextEditingController();
    _lastCompletedStep = null;
    setState(_initStepperControllers);
  }

  void _onTokenCreationContinuePressed() {
    _tokenStepperData.address = _addressController.text;
    _saveProgressAndNavigateToNextStep(_Step.tokenCreation);
  }

  void _saveProgressAndNavigateToNextStep(_Step completedStep) {
    setState(() {
      _lastCompletedStep = completedStep;
      if (_lastCompletedStep!.index + 1 < _numSteps) {
        _currentStep = _Step.values[completedStep.index + 1];
      }
    });
  }

  void _initStepperControllers() {
    _currentStep = _Step.values.first;
  }

  void _onCreatePressed() {
    _tokenStepperData.isUtility = _isUtility;
    context.read<IssueTokenBloc>().add(
      IssueTokenRequested(tokenData: _tokenStepperData),
    );
  }

  void _onIssueDone() {
    _saveProgressAndNavigateToNextStep(_Step.issueToken);
    unawaited(sl.get<TokensCubit>().fetch());
  }

  void _onUtilityChanged(bool value) {
    setState(() {
      _isUtility = value;
    });
  }

  void _onDecimalsChanged(int value) {
    setState(() {
      _selectedNumDecimals = value;
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

  void _onMintableBurnableContinuePressed() {
    setState(() {
      _lastCompletedStep = _Step.tokenMintableBurnable;
      _currentStep = _Step.tokenMetrics;
    });
  }

  void _onTokenDetailsContinuePressed() {
    _tokenStepperData.tokenName = _tokenNameController.text;
    _tokenStepperData.tokenSymbol = _tokenSymbolController.text;
    _tokenStepperData.tokenDomain = _tokenDomainController.text;
    _saveProgressAndNavigateToNextStep(_Step.tokenDetails);
  }

  void _onTokenMetricsContinuePressed() {
    if ((!_isMintable || _maxSupplyKey.currentState!.validate()) &&
        _totalSupplyKey.currentState!.validate()) {
      _tokenStepperData.decimals = _selectedNumDecimals;
      _tokenStepperData.totalSupply = _totalSupplyController.text
          .extractDecimals(_selectedNumDecimals);
      _tokenStepperData.isMintable = _isMintable;
      _tokenStepperData.maxSupply = (_isMintable
          ? _maxSupplyController.text.extractDecimals(_selectedNumDecimals)
          : _totalSupplyController.text.extractDecimals(_selectedNumDecimals));
      _tokenStepperData.isOwnerBurnOnly = _isBurnable;
      _saveProgressAndNavigateToNextStep(_Step.tokenMetrics);
    }
  }

  bool _areTokenMetricsCorrect() =>
      (!_isMintable ||
          InputValidators.correctValue(
                _maxSupplyController.text,
                kBigP255m1,
                _selectedNumDecimals,
                kMinTokenTotalMaxSupply,
                canBeEqualToMin: true,
              ) ==
              null) &&
      InputValidators.correctValue(
            _totalSupplyController.text,
            _isMintable
                ? _maxSupplyController.text.extractDecimals(
                    _selectedNumDecimals,
                  )
                : kBigP255m1,
            _selectedNumDecimals,
            _isMintable ? BigInt.zero : kMinTokenTotalMaxSupply,
            canBeEqualToMin: true,
          ) ==
          null;

  @override
  void dispose() {
    _addressController.dispose();
    _tokenNameController.dispose();
    _totalSupplyController.dispose();
    _maxSupplyController.dispose();
    _tokenDomainController.dispose();
    _tokenSymbolController.dispose();
    super.dispose();
  }
}
