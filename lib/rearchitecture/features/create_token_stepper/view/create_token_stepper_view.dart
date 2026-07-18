import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lottie/lottie.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/tokens/cubit/tokens_cubit.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
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
  GlobalKey<FormState> _tokenSymbolKey = GlobalKey();
  GlobalKey<FormState> _tokenNameKey = GlobalKey();
  GlobalKey<FormState> _totalSupplyKey = GlobalKey();
  GlobalKey<FormState> _tokenDomainKey = GlobalKey();
  final GlobalKey<LoadingButtonState> _createButtonKey = GlobalKey();

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
        MultipleBalanceStatus.success => _getBody(
          context,
          state.data![_addressController.text]!,
        ),
      },
    );
  }

  Widget _getTokenDetailsStepContent(
    BuildContext context,
    AccountInfo accountInfo,
  ) {
    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: Form(
                key: _tokenNameKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: InputField(
                  onChanged: (String value) {
                    setState(() {});
                  },
                  controller: _tokenNameController,
                  hintText: context.l10n.tokenName,
                  validator: Validations.tokenName,
                ),
              ),
            ),
          ],
        ),
        kVerticalSpacing,
        Row(
          children: <Widget>[
            Expanded(
              child: Form(
                key: _tokenSymbolKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: InputField(
                  onChanged: (String value) {
                    setState(() {});
                  },
                  controller: _tokenSymbolController,
                  validator: Validations.tokenSymbol,
                  hintText: context.l10n.tokenSymbol,
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
            suffixIcon: FieldSuffixButtons(
              controller: _tokenDomainController,
            ),
            onChanged: (String value) {
              setState(() {});
            },
            controller: _tokenDomainController,
            validator: InputValidators.checkUrl,
            hintText: context.l10n.tokenDomain,
          ),
        ),
        const SizedBox(
          height: 25,
        ),
        _getTokenDetailsActionButtons(),
      ],
    );
  }

  Widget _getStepBackButton() {
    return StepperButton(
      text: context.l10n.goBack,
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
        steps: <custom_material_stepper.Step>[
          StepperUtils.getMaterialStep(
            stepTitle: context.l10n.tokenCreationPlasmaCheck,
            stepContent: _getPlasmaCheckFutureBuilder(),
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
            stepContent: _getTokenCreationStepContent(accountInfo),
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
            stepContent: _getTokenDetailsStepContent(context, accountInfo),
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
            stepContent: _getTokenMintableAndBurnableStepContent(),
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
            stepContent: _getTokenMetricsStepContent(context, accountInfo),
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
            stepContent: _getIssueTokenStepContent(context),
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

  Widget _getPlasmaCheckFutureBuilder() {
    return FutureBuilder<PlasmaInfo?>(
      future: zenon!.embedded.plasma.get(Address.parse(kSelectedAddress!)),
      builder: (_, AsyncSnapshot<PlasmaInfo?> snapshot) {
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
      children: <Widget>[
        Text(
          context.l10n.morePlasmaRequired,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(
          height: 25,
        ),
        Row(
          children: <Widget>[
            Expanded(
              child: DisabledAddressField(_addressController),
            ),
            const SizedBox(
              width: 25,
            ),
            PlasmaIcon(plasmaInfo),
          ],
        ),
        const SizedBox(
          height: 25,
        ),
        StepperButton(
          text: context.l10n.next,
          onPressed: plasmaInfo.currentPlasma >= kIssueTokenPlasmaAmountNeeded
              ? _onPlasmaCheckNextPressed
              : null,
        ),
      ],
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

  Widget _getIssueTokenStepContent(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Checkbox(
                activeColor: AppColors.ztsColor,
                value: _isUtility,
                onChanged: (bool? value) {
                  setState(() {
                    _isUtility = value!;
                  });
                },
              ),
              Text(
                context.l10n.utilityToken,
                style: Theme.of(context).inputDecorationTheme.hintStyle,
              ),
              const SizedBox(
                width: 3,
              ),
              const Icon(Icons.settings, size: 15, color: AppColors.ztsColor),
              StandardTooltipIcon(
                context.l10n.tokenStatusUtilityTooltip,
                Icons.help,
                iconColor: AppColors.ztsColor,
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 25, bottom: 25, left: 15),
            child: DottedBorderInfoWidget(
              text: context.l10n.burnTokenIssueFee(
                tokenZtsIssueFeeInZnn.addDecimals(coinDecimals),
                kZnnCoin.symbol,
              ),
              borderColor: AppColors.ztsColor,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 15),
            child: Row(
              children: <Widget>[
                Visibility(
                  visible:
                      (_createButtonKey.currentState?.btnState ??
                          ButtonState.idle) ==
                      ButtonState.idle,
                  child: Row(
                    children: <Widget>[
                      _getStepBackButton(),
                      const SizedBox(
                        width: 25,
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

  Widget _getCreateButton() {
    return LoadingButton.stepper(
      text: context.l10n.create,
      outlineColor: AppColors.ztsColor,
      onPressed: _onCreatePressed,
      key: _createButtonKey,
    );
  }

  Widget _getTokenMetricsStepContent(
    BuildContext context,
    AccountInfo accountInfo,
  ) {
    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: CustomSlider(
            activeColor: AppColors.ztsColor,
            description: context.l10n.numberOfDecimals(_selectedNumDecimals),
            startValue: 0,
            min: 0,
            maxValue: 18,
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
            margin: const EdgeInsets.only(bottom: 15),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Form(
                    key: _maxSupplyKey,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    child: InputField(
                      inputFormatters: FormatUtils.getAmountTextInputFormatters(
                        _maxSupplyController.text,
                      ),
                      onChanged: (String value) {
                        setState(() {});
                      },
                      controller: _maxSupplyController,
                      hintText: context.l10n.maxSupply,
                      validator: _isMintable
                          ? (String? value) => InputValidators.correctValue(
                              value,
                              kBigP255m1,
                              _selectedNumDecimals,
                              kMinTokenTotalMaxSupply,
                              canBeEqualToMin: true,
                            )
                          : InputValidators.isMaxSupplyZero,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Row(
          children: <Widget>[
            Expanded(
              child: Form(
                key: _totalSupplyKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: InputField(
                  inputFormatters: FormatUtils.getAmountTextInputFormatters(
                    _totalSupplyController.text,
                  ),
                  onChanged: (String value) {
                    setState(() {});
                  },
                  controller: _totalSupplyController,
                  hintText: context.l10n.totalSupply,
                  validator: (String? value) => InputValidators.correctValue(
                    value,
                    _isMintable
                        ? _maxSupplyController.text.isNotEmpty
                              ? _maxSupplyController.text.extractDecimals(
                                  _selectedNumDecimals,
                                )
                              : kBigP255m1
                        : kBigP255m1,
                    _selectedNumDecimals,
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
      children: <Widget>[
        Row(
          children: <Widget>[
            _getStepBackButton(),
            const SizedBox(
              width: 25,
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
          _currentStep = _Step.values[_currentStep.index - 1];
        });
      }
    }
  }

  Widget _getBody(BuildContext context, AccountInfo accountInfo) {
    return Stack(
      children: <Widget>[
        ListView(
          children: <Widget>[
            _getMaterialStepper(context, accountInfo),
            Padding(
              padding: const EdgeInsets.only(
                top: 50,
                bottom: 20,
              ),
              child: Visibility(
                visible: (_lastCompletedStep?.index ?? -1) == _numSteps - 1,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    StepperButton.icon(
                      label: context.l10n.createAnotherToken,
                      onPressed: _onCreateAnotherTokenPressed,
                      iconData: Icons.refresh,
                    ),
                    const SizedBox(
                      width: 80,
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
            right: 50,
            child: SizedBox(
              width: 400,
              height: 400,
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
      text: context.l10n.viewMyTokens,
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
    setState(_initStepperControllers);
  }

  Widget _getTokenCreationStepContent(AccountInfo accountInfo) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          context.l10n.tokenIssuanceAddressDescription,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        kVerticalSpacing,
        Row(
          children: <Widget>[
            Expanded(
              child: DisabledAddressField(_addressController),
            ),
          ],
        ),
        StepperUtils.getBalanceWidget(kZnnCoin, accountInfo),
        DottedBorderInfoWidget(
          text: context.l10n.burnTokenIssueFee(
            tokenZtsIssueFeeInZnn.addDecimals(coinDecimals),
            kZnnCoin.symbol,
          ),
          borderColor: AppColors.ztsColor,
        ),
        kVerticalSpacing,
        _getTokenCreationActionButtons(accountInfo),
      ],
    );
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

  Widget _getIssueTokenViewModel() {
    return BlocListener<IssueTokenBloc, IssueTokenState>(
      listener: (_, IssueTokenState state) => _onIssueTokenStateChanged(state),
      child: _getCreateButton(),
    );
  }

  void _onIssueTokenStateChanged(IssueTokenState state) {
    if (state is IssueTokenLoading) {
      _createButtonKey.currentState?.animateForward();
    } else if (state is IssueTokenDone) {
      _createButtonKey.currentState?.animateReverse();
      _saveProgressAndNavigateToNextStep(_Step.issueToken);
      sl.get<TokensCubit>().fetch();
    } else if (state is IssueTokenFailure) {
      _createButtonKey.currentState?.animateReverse();
      unawaited(
        NotificationUtils.sendNotificationError(
          state.exception,
          context.l10n.errorCreatingToken,
        ),
      );
    }
  }

  Widget _getTokenCreationContinueButton(AccountInfo accountInfo) {
    return StepperButton(
      text: context.l10n.continueText,
      onPressed:
          accountInfo.getBalance(
                kZnnCoin.tokenStandard,
              ) >=
              tokenZtsIssueFeeInZnn
          ? _onTokenCreationContinuePressed
          : null,
    );
  }

  Widget _getTokenDetailsActionButtons() {
    return Row(
      children: <Widget>[
        _getStepBackButton(),
        const SizedBox(
          width: 25,
        ),
        _getTokenDetailsContinueButton(),
      ],
    );
  }

  Widget _getTokenDetailsContinueButton() {
    return StepperButton(
      text: context.l10n.continueText,
      onPressed: _areTokenDetailsCorrect()
          ? _onTokenDetailsContinuePressed
          : null,
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
      InputValidators.checkUrl(
            _tokenDomainController.text,
          ) ==
          null;

  Widget _getTokenMetricsContinueButton() {
    return StepperButton(
      text: context.l10n.continueText,
      onPressed: _areTokenMetricsCorrect()
          ? _onTokenMetricsContinuePressed
          : null,
    );
  }

  bool _areTokenMetricsCorrect() =>
      (_isMintable
          ? InputValidators.correctValue(
                  _maxSupplyController.text,
                  kBigP255m1,
                  _selectedNumDecimals,
                  kMinTokenTotalMaxSupply,
                  canBeEqualToMin: true,
                ) ==
                null
          : true) &&
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

  Widget _getTokenMintableAndBurnableStepContent() {
    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            const SizedBox(
              width: 20,
            ),
            Checkbox(
              activeColor: AppColors.ztsColor,
              value: _isMintable,
              onChanged: (bool? value) {
                setState(() {
                  if (value! && _totalSupplyController.text.isNotEmpty) {
                    _maxSupplyController.text = _totalSupplyController.text;
                  }
                  _isMintable = value;
                });
              },
            ),
            Text(
              context.l10n.mintable,
              style: Theme.of(context).inputDecorationTheme.hintStyle,
            ),
            StandardTooltipIcon(
              context.l10n.tokenMintableTooltip,
              Icons.help,
              iconColor: AppColors.ztsColor,
            ),
          ],
        ),
        Row(
          children: <Widget>[
            const SizedBox(
              width: 20,
            ),
            Checkbox(
              activeColor: AppColors.ztsColor,
              value: _isBurnable,
              onChanged: (bool? value) {
                setState(() {
                  _isBurnable = value!;
                });
              },
            ),
            Text(
              context.l10n.burn,
              style: Theme.of(context).inputDecorationTheme.hintStyle,
            ),
            const Icon(
              Icons.whatshot,
              size: 15,
              color: AppColors.ztsColor,
            ),
            StandardTooltipIcon(
              context.l10n.tokenBurnTooltip,
              Icons.help,
              iconColor: AppColors.ztsColor,
            ),
          ],
        ),
        kVerticalSpacing,
        Row(
          children: <Widget>[
            _getStepBackButton(),
            const SizedBox(
              width: 25,
            ),
            StepperButton(
              text: context.l10n.continueText,
              onPressed: () {
                setState(() {
                  _lastCompletedStep = _Step.tokenMintableBurnable;
                  _currentStep = _Step.tokenMetrics;
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
