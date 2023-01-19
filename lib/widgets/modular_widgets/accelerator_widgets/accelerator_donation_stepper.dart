import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:stacked/stacked.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/custom_material_stepper.dart'
    as custom_material_stepper;
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

enum AcceleratorDonationStep {
  donationAddress,
  donationDetails,
  submitDonation,
}

class AcceleratorDonationStepper extends StatefulWidget {
  const AcceleratorDonationStepper({Key? key}) : super(key: key);

  @override
  State<AcceleratorDonationStepper> createState() =>
      _AcceleratorDonationStepperState();
}

class _AcceleratorDonationStepperState
    extends State<AcceleratorDonationStepper> {
  AcceleratorDonationStep? _lastCompletedStep;
  AcceleratorDonationStep _currentStep = AcceleratorDonationStep.values.first;

  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _znnAmountController = TextEditingController();
  final TextEditingController _qsrAmountController = TextEditingController();

  final GlobalKey<FormState> _znnAmountKey = GlobalKey();
  final GlobalKey<FormState> _qsrAmountKey = GlobalKey();
  final GlobalKey<LoadingButtonState> _submitButtonKey = GlobalKey();

  num _znnAmount = 0;
  num _qsrAmount = 0;

  @override
  void initState() {
    super.initState();
    _addressController.text = kSelectedAddress!;
    sl.get<BalanceBloc>().getBalanceForAllAddresses();
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
            return _getWidgetBody(
              context,
              snapshot.data![_addressController.text]!,
            );
          }
          return const SyriusLoadingWidget();
        }
        return const SyriusLoadingWidget();
      },
    );
  }

  Widget _getWidgetBody(BuildContext context, AccountInfo accountInfo) {
    return Stack(
      children: [
        ListView(
          children: [
            _getMaterialStepper(context, accountInfo),
          ],
        ),
        Visibility(
          visible: _lastCompletedStep == AcceleratorDonationStep.values.last,
          child: Positioned(
            bottom: 20.0,
            right: 0.0,
            left: 0.0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                StepperButton.icon(
                  label: 'Make another donation',
                  onPressed: () {
                    setState(() {
                      _currentStep = AcceleratorDonationStep.values.first;
                      _lastCompletedStep = null;
                    });
                  },
                  iconData: Icons.refresh,
                  context: context,
                ),
                const SizedBox(
                  width: 75.0,
                ),
                StepperButton(
                  text: 'Return to project list',
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
        ),
        Visibility(
          visible: _lastCompletedStep == AcceleratorDonationStep.values.last,
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

  Widget _getMaterialStepper(BuildContext context, AccountInfo accountInfo) {
    return Theme(
      data: Theme.of(context).copyWith(
        highlightColor: Colors.transparent,
        splashColor: Colors.transparent,
        hoverColor: Colors.transparent,
      ),
      child: custom_material_stepper.Stepper(
        currentStep: _currentStep.index,
        onStepTapped: (int index) {},
        steps: [
          StepperUtils.getMaterialStep(
            stepTitle: 'Donation address',
            stepContent: _getDonationAddressStepContent(accountInfo),
            stepSubtitle: _addressController.text,
            stepState: StepperUtils.getStepState(
              AcceleratorDonationStep.donationAddress.index,
              _lastCompletedStep?.index,
            ),
            context: context,
          ),
          StepperUtils.getMaterialStep(
            stepTitle: 'Donation details',
            stepContent: _getDonationDetailsStepContent(accountInfo),
            stepSubtitle: _getDonationDetailsStepSubtitle(),
            stepState: StepperUtils.getStepState(
              AcceleratorDonationStep.donationDetails.index,
              _lastCompletedStep?.index,
            ),
            context: context,
          ),
          StepperUtils.getMaterialStep(
            stepTitle: 'Submit donation',
            stepContent: _getSubmitDonationStepContent(),
            stepSubtitle: 'Donation submitted',
            stepState: StepperUtils.getStepState(
              AcceleratorDonationStep.submitDonation.index,
              _lastCompletedStep?.index,
            ),
            context: context,
          ),
        ],
      ),
    );
  }

  String _getDonationDetailsStepSubtitle() {
    String znnPrefix = _znnAmountController.text.isNotEmpty
        ? '${_znnAmountController.text} ${kZnnCoin.symbol}'
        : '';
    String qsrSuffix = _qsrAmountController.text.isNotEmpty
        ? '${_qsrAmountController.text} ${kQsrCoin.symbol}'
        : '';
    String splitter = znnPrefix.isNotEmpty && qsrSuffix.isNotEmpty ? ' ● ' : '';

    return znnPrefix + splitter + qsrSuffix;
  }

  Widget _getDonationAddressStepContent(AccountInfo accountInfo) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DisabledAddressField(_addressController),
        StepperUtils.getBalanceWidget(kZnnCoin, accountInfo),
        const DottedBorderInfoWidget(
          text: 'All donated funds go directly into the Accelerator address',
        ),
        kVerticalSpacing,
        Row(
          children: [
            StepperButton(
              onPressed: () {
                Navigator.pop(context);
              },
              text: 'Cancel',
            ),
            const SizedBox(
              width: 15.0,
            ),
            StepperButton(
              onPressed: accountInfo.znn()! > 0
                  ? () {
                      setState(() {
                        _lastCompletedStep =
                            AcceleratorDonationStep.donationAddress;
                        _currentStep = AcceleratorDonationStep.donationDetails;
                      });
                    }
                  : null,
              text: 'Continue',
            ),
          ],
        ),
      ],
    );
  }

  Widget _getDonationDetailsStepContent(AccountInfo accountInfo) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: const [
            Text('Total donation budget'),
            StandardTooltipIcon(
              'Your donation matters',
              Icons.help,
            ),
          ],
        ),
        kVerticalSpacing,
        Form(
          key: _znnAmountKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: InputField(
            hintText: 'ZNN Amount',
            controller: _znnAmountController,
            suffixIcon: AmountSuffixWidgets(
              kZnnCoin,
              onMaxPressed: () {
                num maxZnn = accountInfo.getBalanceWithDecimals(
                  kZnnCoin.tokenStandard,
                );
                if (_znnAmountController.text.isEmpty ||
                    _znnAmountController.text.toNum() < maxZnn) {
                  setState(() {
                    _znnAmountController.text = maxZnn.toString();
                  });
                }
              },
            ),
            validator: (value) => InputValidators.correctValue(
              value,
              AmountUtils.addDecimals(
                accountInfo.znn()!,
                znnDecimals,
              ),
              znnDecimals,
              canBeEqualToMin: true,
              canBeBlank: true,
            ),
            onChanged: (value) {
              setState(() {});
            },
            inputFormatters: FormatUtils.getAmountTextInputFormatters(
              _znnAmountController.text,
            ),
          ),
        ),
        StepperUtils.getBalanceWidget(kZnnCoin, accountInfo),
        Form(
          key: _qsrAmountKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: InputField(
            hintText: 'QSR Amount',
            controller: _qsrAmountController,
            suffixIcon: AmountSuffixWidgets(
              kQsrCoin,
              onMaxPressed: () {
                num maxQsr = accountInfo.getBalanceWithDecimals(
                  kQsrCoin.tokenStandard,
                );

                if (_qsrAmountController.text.isEmpty ||
                    _qsrAmountController.text.toNum() < maxQsr) {
                  setState(() {
                    _qsrAmountController.text = maxQsr.toString();
                  });
                }
              },
            ),
            validator: (value) => InputValidators.correctValue(
              value,
              AmountUtils.addDecimals(
                accountInfo.qsr()!,
                qsrDecimals,
              ),
              znnDecimals,
              canBeEqualToMin: true,
              canBeBlank: true,
            ),
            onChanged: (value) {
              setState(() {});
            },
            inputFormatters: FormatUtils.getAmountTextInputFormatters(
              _qsrAmountController.text,
            ),
          ),
        ),
        StepperUtils.getBalanceWidget(kQsrCoin, accountInfo),
        Row(
          children: [
            StepperButton(
              text: 'Cancel',
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            const SizedBox(
              width: 15.0,
            ),
            StepperButton(
              text: 'Continue',
              onPressed: _ifInputValid(accountInfo)
                  ? () {
                      setState(() {
                        _lastCompletedStep =
                            AcceleratorDonationStep.donationDetails;
                        _currentStep = AcceleratorDonationStep.submitDonation;
                      });
                    }
                  : null,
            ),
          ],
        ),
      ],
    );
  }

  bool _ifInputValid(AccountInfo accountInfo) {
    try {
      _znnAmount = _znnAmountController.text.isNotEmpty
          ? _znnAmountController.text.toNum()
          : 0;
      _qsrAmount = _qsrAmountController.text.isNotEmpty
          ? _qsrAmountController.text.toNum()
          : 0;
    } catch (_) {}

    return InputValidators.correctValue(
              _znnAmountController.text,
              AmountUtils.addDecimals(
                accountInfo.znn()!,
                znnDecimals,
              ),
              znnDecimals,
              canBeEqualToMin: true,
              canBeBlank: true,
            ) ==
            null &&
        InputValidators.correctValue(
              _qsrAmountController.text,
              AmountUtils.addDecimals(
                accountInfo.qsr()!,
                qsrDecimals,
              ),
              qsrDecimals,
              canBeEqualToMin: true,
              canBeBlank: true,
            ) ==
            null &&
        (_qsrAmountController.text.isNotEmpty ||
            _znnAmountController.text.isNotEmpty) &&
        (_znnAmount > 0 || _qsrAmount > 0);
  }

  Widget _getSubmitDonationStepContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const DottedBorderInfoWidget(
          text: 'Thank you for supporting the Accelerator',
        ),
        kVerticalSpacing,
        Row(
          children: [
            StepperButton(
              onPressed: () {
                setState(() {
                  _currentStep = AcceleratorDonationStep.donationDetails;
                  _lastCompletedStep = AcceleratorDonationStep.donationAddress;
                });
              },
              text: 'Go back',
            ),
            const SizedBox(
              width: 15.0,
            ),
            _getSubmitDonationViewModel(),
          ],
        ),
      ],
    );
  }

  Widget _getSubmitDonationButton(SubmitDonationBloc model) {
    return LoadingButton.stepper(
      onPressed: () {
        _submitButtonKey.currentState?.animateForward();
        model.submitDonation(
          _znnAmount,
          _qsrAmount,
        );
      },
      text: 'Submit',
      key: _submitButtonKey,
    );
  }

  Widget _getSubmitDonationViewModel() {
    return ViewModelBuilder<SubmitDonationBloc>.reactive(
      onViewModelReady: (model) {
        model.stream.listen(
          (event) {
            if (event != null) {
              _submitButtonKey.currentState?.animateReverse();
              setState(() {
                _lastCompletedStep = AcceleratorDonationStep.values.last;
              });
            }
          },
          onError: (error) {
            _submitButtonKey.currentState?.animateReverse();
            NotificationUtils.sendNotificationError(
              error,
              'Error while submitting donation',
            );
          },
        );
      },
      builder: (_, model, __) => _getSubmitDonationButton(model),
      viewModelBuilder: () => SubmitDonationBloc(),
    );
  }

  @override
  void dispose() {
    _addressController.dispose();
    _znnAmountController.dispose();
    _qsrAmountController.dispose();
    super.dispose();
  }
}
