import 'dart:core';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import 'package:stacked/stacked.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/utils/extensions.dart';
import 'package:zenon_syrius_wallet_flutter/utils/format_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/global.dart';
import 'package:zenon_syrius_wallet_flutter/utils/input_validators.dart';
import 'package:zenon_syrius_wallet_flutter/utils/notification_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/zts_utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/custom_material_stepper.dart'
    as custom_material_stepper;
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

enum TokenStepperStep {
  checkPlasma,
  tokenCreation,
  tokenDetails,
  tokenMintableBurnable,
  tokenMetrics,
  issueToken,
}

class TokenStepper extends StatefulWidget {
  const TokenStepper({Key? key}) : super(key: key);

  @override
  State createState() {
    return _TokenStepperState();
  }
}

class _TokenStepperState extends State<TokenStepper> {
  late TokenStepperStep _currentStep;
  TokenStepperStep? _lastCompletedStep;

  final int _numSteps = TokenStepperStep.values.length;

  final TextEditingController _addressController = TextEditingController();
  TextEditingController _tokenNameController = TextEditingController();
  TextEditingController _totalSupplyController = TextEditingController();
  TextEditingController _maxSupplyController = TextEditingController();
  TextEditingController _tokenDomainController = TextEditingController();
  TextEditingController _tokenSymbolController = TextEditingController();

  GlobalKey<FormState> _maxSupplyKey = GlobalKey();
  GlobalKey<FormState> _tokenSymbolKey = GlobalKey();
  GlobalKey<FormState> _tokenNameKey = GlobalKey();
  GlobalKey<FormState> _totalSupplyKey = GlobalKey();
  GlobalKey<FormState> _tokenDomainKey = GlobalKey();
  final GlobalKey<LoadingButtonState> _createButtonKey = GlobalKey();

  int _selectedNumDecimals = 0;

  bool _isMintable = false;
  bool _isBurnable = false;
  bool _isUtility = true;

  late List<FocusNode> _focusNodes;

  Map<Type, Action<Intent>>? _actionMap;
  Map<LogicalKeySet, Intent>? _shortcutMap;

  final NewTokenData _tokenStepperData = NewTokenData();

  @override
  void initState() {
    super.initState();
    _addressController.text = kSelectedAddress!;
    _initFocusNodes(3);
    sl.get<BalanceBloc>().getBalanceForAllAddresses();
    _initStepperControllers();
    _actionMap = <Type, Action<Intent>>{
      ActivateIntent: CallbackAction(
        onInvoke: (Intent intent) => _changeFocusToNextNode(),
      ),
    };
    _shortcutMap = <LogicalKeySet, Intent>{
      LogicalKeySet(LogicalKeyboardKey.tab): const ActivateIntent(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, AccountInfo>?>(
      stream: sl.get<BalanceBloc>().stream,
      builder: (_, snapshot) {
        if (snapshot.hasError) {
          return SyriusErrorWidget(snapshot.error!);
        }
        if (snapshot.connectionState == ConnectionState.active) {
          if (snapshot.hasData) {
            return _getBody(context, snapshot.data![_addressController.text]!);
          }
          return const SyriusLoadingWidget();
        }
        return const SyriusLoadingWidget();
      },
    );
  }

  Widget _getTokenDetailsStepContent(
    BuildContext context,
    AccountInfo accountInfo,
  ) {
    return FocusableActionDetector(
      actions: _actionMap,
      shortcuts: _shortcutMap,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Form(
                  key: _tokenNameKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: InputField(
                    thisNode: _focusNodes[0],
                    onChanged: (value) {
                      setState(() {});
                    },
                    controller: _tokenNameController,
                    hintText: 'Token Name',
                    validator: Validations.tokenName,
                  ),
                ),
              ),
            ],
          ),
          kVerticalSpacing,
          Row(
            children: [
              Expanded(
                child: Form(
                  key: _tokenSymbolKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: InputField(
                    thisNode: _focusNodes[1],
                    onChanged: (value) {
                      setState(() {});
                    },
                    controller: _tokenSymbolController,
                    validator: Validations.tokenSymbol,
                    hintText: 'Token Symbol',
                  ),
                ),
              ),
            ],
          ),
          kVerticalSpacing,
          Form(
            key: _tokenDomainKey,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            child: InputField(
              thisNode: _focusNodes[2],
              onChanged: (value) {
                setState(() {});
              },
              controller: _tokenDomainController,
              validator: Validations.tokenDomain,
              hintText: 'Token Domain',
            ),
          ),
          const SizedBox(
            height: 25.0,
          ),
          _getTokenDetailsActionButtons(),
        ],
      ),
    );
  }

  Widget _getStepBackButton() {
    return StepperButton(
      text: 'Go back',
      onPressed: _onBackButtonPressed,
    );
  }

  Widget _getMaterialStepper(BuildContext context, AccountInfo accountInfo) {
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
        steps: [
          StepperUtils.getMaterialStep(
            stepTitle: 'Token creation: Plasma check',
            stepContent: _getPlasmaCheckFutureBuilder(),
            stepSubtitle: 'Sufficient Plasma',
            stepState: StepperUtils.getStepState(
              TokenStepperStep.checkPlasma.index,
              _lastCompletedStep?.index,
            ),
            context: context,
            stepSubtitleColor: AppColors.ztsColor,
          ),
          StepperUtils.getMaterialStep(
            stepTitle: 'Token Creation',
            stepContent: _getTokenCreationStepContent(accountInfo),
            stepSubtitle: _addressController.text,
            stepState: StepperUtils.getStepState(
              TokenStepperStep.tokenCreation.index,
              _lastCompletedStep?.index,
            ),
            context: context,
            stepSubtitleColor: AppColors.ztsColor,
          ),
          StepperUtils.getMaterialStep(
            stepTitle: 'Token Details',
            stepContent: _getTokenDetailsStepContent(context, accountInfo),
            stepSubtitle:
                '${_tokenNameController.text} ${_tokenSymbolController.text}',
            stepState: StepperUtils.getStepState(
              TokenStepperStep.tokenDetails.index,
              _lastCompletedStep?.index,
            ),
            context: context,
            stepSubtitleColor: AppColors.ztsColor,
          ),
          StepperUtils.getMaterialStep(
            stepTitle: 'Token mintable and burnable options',
            stepContent: _getTokenMintableAndBurnableStepContent(),
            stepSubtitle: 'Mintable: ${_isMintable ? 'yes' : 'no'}\n'
                'Burnable: ${_isBurnable ? 'yes' : 'no'}',
            stepState: StepperUtils.getStepState(
              TokenStepperStep.tokenMintableBurnable.index,
              _lastCompletedStep?.index,
            ),
            stepSubtitleColor: AppColors.ztsColor,
            context: context,
          ),
          StepperUtils.getMaterialStep(
            stepTitle: 'Token Metrics',
            stepContent: _getTokenMetricsStepContent(context, accountInfo),
            stepSubtitle: '${_totalSupplyController.text} '
                '${_tokenSymbolController.text}',
            stepState: StepperUtils.getStepState(
              TokenStepperStep.tokenMetrics.index,
              _lastCompletedStep?.index,
            ),
            context: context,
            stepSubtitleColor: AppColors.ztsColor,
            stepSubtitleIconData: Icons.whatshot,
          ),
          StepperUtils.getMaterialStep(
            stepTitle: 'Issue Token',
            stepContent: _getIssueTokenStepContent(context),
            stepSubtitle: _isMintable
                ? '${_totalSupplyController.text} out of '
                    '${_maxSupplyController.text} ${_tokenSymbolController.text}'
                : _isUtility
                    ? 'Utility Token'
                    : '',
            stepState: StepperUtils.getStepState(
              TokenStepperStep.issueToken.index,
              _lastCompletedStep?.index,
            ),
            context: context,
            stepSubtitleColor: AppColors.ztsColor,
          ),
        ],
      ),
    );
  }

  Widget _getPlasmaCheckFutureBuilder() {
    return FutureBuilder<PlasmaInfo?>(
      future: zenon!.embedded.plasma.get(Address.parse(kSelectedAddress!)),
      builder: (_, snapshot) {
        if (snapshot.hasError) {
          return SyriusErrorWidget(snapshot.error!);
        } else if (snapshot.hasData) {
          return _getPlasmaCheckBody(snapshot.data!);
        }
        return const SyriusLoadingWidget();
      },
    );
  }

  Widget _getPlasmaCheckBody(PlasmaInfo plasmaInfo) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'More Plasma is required to perform complex transactions. Please fuse enough QSR before proceeding.',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(
          height: 25.0,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: DisabledAddressField(_addressController),
            ),
            const SizedBox(
              width: 25.0,
            ),
            PlasmaIcon(plasmaInfo),
          ],
        ),
        const SizedBox(
          height: 25.0,
        ),
        StepperButton(
          text: 'Next',
          onPressed: plasmaInfo.currentPlasma >= kIssueTokenPlasmaAmountNeeded
              ? _onPlasmaCheckNextPressed
              : null,
        ),
      ],
    );
  }

  void _onPlasmaCheckNextPressed() {
    if (_lastCompletedStep == null) {
      _saveProgressAndNavigateToNextStep(TokenStepperStep.checkPlasma);
    } else if (StepperUtils.getStepState(
          TokenStepperStep.checkPlasma.index,
          _lastCompletedStep?.index,
        ) ==
        custom_material_stepper.StepState.complete) {
      setState(() {
        _currentStep = TokenStepperStep.values[_currentStep.index + 1];
      });
    }
  }

  Widget _getIssueTokenStepContent(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 25.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Checkbox(
                activeColor: AppColors.ztsColor,
                value: _isUtility,
                onChanged: (value) {
                  setState(() {
                    _isUtility = value!;
                  });
                },
              ),
              Text(
                'Utility token',
                style: Theme.of(context).inputDecorationTheme.hintStyle,
              ),
              const SizedBox(
                width: 3.0,
              ),
              const Icon(Icons.settings, size: 15.0, color: AppColors.ztsColor),
              const StandardTooltipIcon(
                'Token status: utility or '
                'non-utility (e.g. security token)',
                Icons.help,
                iconColor: AppColors.ztsColor,
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 25.0, bottom: 25.0, left: 15.0),
            child: DottedBorderInfoWidget(
              text: 'You will need to burn '
                  '${tokenZtsIssueFeeInZnn.addDecimals(
                coinDecimals,
              )} ${kZnnCoin.symbol} '
                  'to issue a token',
              borderColor: AppColors.ztsColor,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 15.0),
            child: Row(
              children: [
                Visibility(
                  visible: (_createButtonKey.currentState?.btnState ??
                          ButtonState.idle) ==
                      ButtonState.idle,
                  child: Row(
                    children: [
                      _getStepBackButton(),
                      const SizedBox(
                        width: 25.0,
                      ),
                    ],
                  ),
                ),
                _getIssueTokenViewModel(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _getCreateButton(IssueTokenBloc model) {
    return LoadingButton.stepper(
      text: 'Create',
      outlineColor: AppColors.ztsColor,
      onPressed: () => _onCreatePressed(model),
      key: _createButtonKey,
    );
  }

  Widget _getTokenMetricsStepContent(
    BuildContext context,
    AccountInfo accountInfo,
  ) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 20.0),
          child: CustomSlider(
            activeColor: AppColors.ztsColor,
            description: 'Number of decimals: ${_selectedNumDecimals.toInt()}',
            startValue: 0.0,
            min: 0.0,
            maxValue: 18.0,
            callback: (double value) {
              setState(() {
                _selectedNumDecimals = value.toInt();
              });
            },
          ),
        ),
        Visibility(
          visible: _isMintable,
          child: Container(
            margin: const EdgeInsets.only(bottom: 15.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: <Widget>[
                Expanded(
                  child: Form(
                    key: _maxSupplyKey,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    child: InputField(
                      inputFormatters: FormatUtils.getAmountTextInputFormatters(
                        _maxSupplyController.text,
                      ),
                      onChanged: (value) {
                        setState(() {});
                      },
                      controller: _maxSupplyController,
                      hintText: 'Max supply',
                      validator: _isMintable
                          ? (String? value) => InputValidators.correctValue(
                                value,
                                kBigP255m1,
                                _selectedNumDecimals.toInt(),
                                kMinTokenTotalMaxSupply,
                                canBeEqualToMin: true,
                              )
                          : (String? value) =>
                              InputValidators.isMaxSupplyZero(value),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: Form(
                key: _totalSupplyKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: InputField(
                  inputFormatters: FormatUtils.getAmountTextInputFormatters(
                    _totalSupplyController.text,
                  ),
                  onChanged: (value) {
                    setState(() {});
                  },
                  controller: _totalSupplyController,
                  hintText: 'Total supply',
                  validator: (value) => InputValidators.correctValue(
                    value,
                    _isMintable
                        ? _maxSupplyController.text.isNotEmpty
                            ? _maxSupplyController.text
                                .extractDecimals(_selectedNumDecimals)
                            : kBigP255m1
                        : kBigP255m1,
                    _selectedNumDecimals.toInt(),
                    _isMintable ? BigInt.zero : kMinTokenTotalMaxSupply,
                    canBeEqualToMin: true,
                  ),
                ),
              ),
            ),
          ],
        ),
        kVerticalSpacing,
        _getTokenMetricsActionButtons(),
      ],
    );
  }

  Row _getTokenMetricsActionButtons() {
    return Row(
      children: [
        Row(
          children: [
            _getStepBackButton(),
            const SizedBox(
              width: 25.0,
            ),
            _getTokenMetricsContinueButton(),
          ],
        ),
      ],
    );
  }

  Widget _getTokenCreationActionButtons(AccountInfo accountInfo) {
    return _getTokenCreationContinueButton(accountInfo);
  }

  void _onBackButtonPressed() {
    if (_currentStep.index > 0) {
      if (StepperUtils.getStepState(
            _currentStep.index,
            _lastCompletedStep?.index,
          ) !=
          custom_material_stepper.StepState.complete) {
        setState(() {
          _currentStep = TokenStepperStep.values[_currentStep.index - 1];
        });
      }
    }
  }

  Widget _getBody(BuildContext context, AccountInfo accountInfo) {
    return Stack(
      children: [
        ListView(
          children: [
            _getMaterialStepper(context, accountInfo),
            Padding(
              padding: const EdgeInsets.only(
                top: 50.0,
                bottom: 20.0,
              ),
              child: Visibility(
                visible: (_lastCompletedStep?.index ?? -1) == _numSteps - 1,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    StepperButton.icon(
                      label: 'Create another Token',
                      onPressed: _onCreateAnotherTokenPressed,
                      iconData: Icons.refresh,
                      context: context,
                    ),
                    const SizedBox(
                      width: 80.0,
                    ),
                    _getViewTokensButton(),
                  ],
                ),
              ),
            ),
          ],
        ),
        Visibility(
          visible: (_lastCompletedStep?.index ?? -1) == _numSteps - 1,
          child: Positioned(
            right: 50.0,
            child: SizedBox(
              width: 400.0,
              height: 400.0,
              child: Center(
                child: Lottie.asset(
                  'assets/lottie/ic_anim_zts.json',
                  repeat: false,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _getViewTokensButton() {
    return StepperButton(
      text: 'View my Tokens',
      outlineColor: AppColors.ztsColor,
      onPressed: () {
        Navigator.pop(context);
      },
    );
  }

  void _onCreateAnotherTokenPressed() {
    _tokenNameKey = GlobalKey();
    _tokenNameController = TextEditingController();
    _tokenSymbolKey = GlobalKey();
    _tokenSymbolController = TextEditingController();
    _totalSupplyKey = GlobalKey();
    _totalSupplyController = TextEditingController();
    _maxSupplyKey = GlobalKey();
    _maxSupplyController = TextEditingController();
    _tokenDomainKey = GlobalKey();
    _tokenDomainController = TextEditingController();
    _lastCompletedStep = null;
    setState(() {
      _initStepperControllers();
    });
  }

  Widget _getTokenCreationStepContent(AccountInfo accountInfo) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'This will be your issuance address',
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        kVerticalSpacing,
        Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: DisabledAddressField(_addressController),
            ),
          ],
        ),
        StepperUtils.getBalanceWidget(kZnnCoin, accountInfo),
        DottedBorderInfoWidget(
          text: 'You will need to burn '
              '${tokenZtsIssueFeeInZnn.addDecimals(
            coinDecimals,
          )} ${kZnnCoin.symbol} '
              'to issue a token',
          borderColor: AppColors.ztsColor,
        ),
        kVerticalSpacing,
        _getTokenCreationActionButtons(accountInfo),
      ],
    );
  }

  void _onTokenCreationContinuePressed() {
    _tokenStepperData.address = _addressController.text;
    _saveProgressAndNavigateToNextStep(TokenStepperStep.tokenCreation);
  }

  void _saveProgressAndNavigateToNextStep(TokenStepperStep completedStep) {
    setState(() {
      _lastCompletedStep = completedStep;
      if (_lastCompletedStep!.index + 1 < _numSteps) {
        _currentStep = TokenStepperStep.values[completedStep.index + 1];
      }
    });
  }

  void _initStepperControllers() {
    _currentStep = TokenStepperStep.values.first;
  }

  void _onCreatePressed(IssueTokenBloc model) {
    _tokenStepperData.isUtility = _isUtility;
    _createButtonKey.currentState?.animateForward();
    model.issueToken(_tokenStepperData);
    setState(() {});
  }

  void _onTokenDetailsContinuePressed() {
    _tokenStepperData.tokenName = _tokenNameController.text;
    _tokenStepperData.tokenSymbol = _tokenSymbolController.text;
    _tokenStepperData.tokenDomain = _tokenDomainController.text;
    _saveProgressAndNavigateToNextStep(TokenStepperStep.tokenDetails);
  }

  void _onTokenMetricsContinuePressed() {
    if ((!_isMintable || _maxSupplyKey.currentState!.validate()) &&
        _totalSupplyKey.currentState!.validate()) {
      _tokenStepperData.decimals = _selectedNumDecimals.toInt();
      _tokenStepperData.totalSupply =
          _totalSupplyController.text.extractDecimals(_selectedNumDecimals);
      _tokenStepperData.isMintable = _isMintable;
      _tokenStepperData.maxSupply = (_isMintable
          ? _maxSupplyController.text.extractDecimals(_selectedNumDecimals)
          : _totalSupplyController.text.extractDecimals(_selectedNumDecimals));
      _tokenStepperData.isOwnerBurnOnly = _isBurnable;
      _saveProgressAndNavigateToNextStep(TokenStepperStep.tokenMetrics);
    }
  }

  Widget _getIssueTokenViewModel() {
    return ViewModelBuilder<IssueTokenBloc>.reactive(
      onViewModelReady: (model) {
        model.stream.listen(
          (response) {
            _createButtonKey.currentState?.animateReverse();
            _saveProgressAndNavigateToNextStep(TokenStepperStep.issueToken);
          },
          onError: (error) {
            _createButtonKey.currentState?.animateReverse();
            NotificationUtils.sendNotificationError(
              error,
              'Error while creating a new ZTS token',
            );
          },
        );
      },
      builder: (_, model, __) => _getCreateButton(model),
      viewModelBuilder: () => IssueTokenBloc(),
    );
  }

  Widget _getTokenCreationContinueButton(AccountInfo accountInfo) {
    return StepperButton(
      text: 'Continue',
      onPressed: accountInfo.getBalance(
                kZnnCoin.tokenStandard,
              ) >=
              tokenZtsIssueFeeInZnn
          ? _onTokenCreationContinuePressed
          : null,
    );
  }

  Widget _getTokenDetailsActionButtons() {
    return Row(
      children: [
        _getStepBackButton(),
        const SizedBox(
          width: 25.0,
        ),
        _getTokenDetailsContinueButton(),
      ],
    );
  }

  Widget _getTokenDetailsContinueButton() {
    return StepperButton(
      text: 'Continue',
      onPressed:
          _areTokenDetailsCorrect() ? _onTokenDetailsContinuePressed : null,
    );
  }

  bool _areTokenDetailsCorrect() =>
      Validations.tokenName(
            _tokenNameController.text,
          ) ==
          null &&
      Validations.tokenSymbol(
            _tokenSymbolController.text,
          ) ==
          null &&
      Validations.tokenDomain(
            _tokenDomainController.text,
          ) ==
          null;

  Widget _getTokenMetricsContinueButton() {
    return StepperButton(
      text: 'Continue',
      onPressed:
          _areTokenMetricsCorrect() ? _onTokenMetricsContinuePressed : null,
    );
  }

  bool _areTokenMetricsCorrect() =>
      (_isMintable
          ? InputValidators.correctValue(
                _maxSupplyController.text,
                kBigP255m1,
                _selectedNumDecimals.toInt(),
                kMinTokenTotalMaxSupply,
                canBeEqualToMin: true,
              ) ==
              null
          : true) &&
      InputValidators.correctValue(
            _totalSupplyController.text,
            _isMintable
                ? _maxSupplyController.text
                    .extractDecimals(_selectedNumDecimals.toInt())
                : kBigP255m1,
            _selectedNumDecimals.toInt(),
            _isMintable ? BigInt.zero : kMinTokenTotalMaxSupply,
            canBeEqualToMin: true,
          ) ==
          null;

  void _initFocusNodes(int length) => _focusNodes = List.generate(
        length,
        (index) => FocusNode(),
      );

  void _changeFocusToNextNode() {
    int indexOfFocusedNode = _focusNodes.indexOf(
      _focusNodes.firstWhere(
        (node) => node.hasFocus,
      ),
    );
    if (indexOfFocusedNode + 1 < _focusNodes.length) {
      _focusNodes[indexOfFocusedNode + 1].requestFocus();
    } else {
      _focusNodes[0].requestFocus();
    }
  }

  Widget _getTokenMintableAndBurnableStepContent() {
    return Column(
      children: [
        Row(
          children: [
            const SizedBox(
              width: 20.0,
            ),
            Checkbox(
              activeColor: AppColors.ztsColor,
              value: _isMintable,
              onChanged: (value) {
                setState(() {
                  if (value! && _totalSupplyController.text.isNotEmpty) {
                    _maxSupplyController.text = _totalSupplyController.text;
                  }
                  _isMintable = value;
                });
              },
            ),
            Text(
              'Mintable',
              style: Theme.of(context).inputDecorationTheme.hintStyle,
            ),
            const StandardTooltipIcon(
              'Whether or not this token is mintable after creation',
              Icons.help,
              iconColor: AppColors.ztsColor,
            ),
          ],
        ),
        Row(
          children: [
            const SizedBox(
              width: 20.0,
            ),
            Checkbox(
              activeColor: AppColors.ztsColor,
              value: _isBurnable,
              onChanged: (value) {
                setState(() {
                  _isBurnable = value!;
                });
              },
            ),
            Text(
              'Burn',
              style: Theme.of(context).inputDecorationTheme.hintStyle,
            ),
            const Icon(
              Icons.whatshot,
              size: 15.0,
              color: AppColors.ztsColor,
            ),
            const StandardTooltipIcon(
              'Whether or not only the token owner can burn it',
              Icons.help,
              iconColor: AppColors.ztsColor,
            ),
          ],
        ),
        kVerticalSpacing,
        Row(
          children: [
            _getStepBackButton(),
            const SizedBox(
              width: 25.0,
            ),
            StepperButton(
              text: 'Continue',
              onPressed: () {
                setState(() {
                  _lastCompletedStep = TokenStepperStep.tokenMintableBurnable;
                  _currentStep = TokenStepperStep.tokenMetrics;
                });
              },
            ),
          ],
        ),
      ],
    );
  }

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
