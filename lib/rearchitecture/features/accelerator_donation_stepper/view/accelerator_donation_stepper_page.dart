import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/accelerator_donation_stepper/accelerator_donation_stepper.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';

/// Dependency-injection wrapper for [AcceleratorDonationStepperView].
class AcceleratorDonationStepperPage extends StatelessWidget {
  /// Creates an [AcceleratorDonationStepperPage].
  const AcceleratorDonationStepperPage({this._onDonationSubmitted, super.key});

  final VoidCallback? _onDonationSubmitted;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SubmitDonationBloc>(
      create: (_) => SubmitDonationBloc(
        accountBlockUtils: AccountBlockUtils(),
        zenon: zenon!,
        zenonAddressUtils: ZenonAddressUtils(),
      ),
      child: AcceleratorDonationStepperView(
        onDonationSubmitted: _onDonationSubmitted,
      ),
    );
  }
}
