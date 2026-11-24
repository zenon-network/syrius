import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/p2p_swap_options/widgets/view_swap_tutorial_button.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/reclaim_deposit/bloc/reclaim_deposit_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/reclaim_deposit/widgets/reclaim_deposit_button.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';

/// Modal containing the flow used to reclaim an expired deposit.
class ReclaimDepositModal extends StatelessWidget {
  /// Creates a [ReclaimDepositModal].
  const ReclaimDepositModal({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ReclaimDepositBloc>(
      create: (_) => ReclaimDepositBloc(
        accountBlockUtils: AccountBlockUtils(
          publishSuccessNotification: false,
        ),
        walletAddresses: kDefaultAddressList.whereType<String>().toSet(),
        zenon: zenon!,
        zenonAddressUtils: ZenonAddressUtils(),
      ),
      child: const _View(),
    );
  }
}

class _View extends StatefulWidget {
  const _View();

  @override
  State<_View> createState() => _ViewState();
}

class _ViewState extends State<_View> {
  final TextEditingController _depositIdController = TextEditingController();

  @override
  void dispose() {
    _depositIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReclaimDepositBloc, ReclaimDepositState>(
      builder: (_, ReclaimDepositState state) => BaseModal(
        title: context.l10n.reclaimDeposit,
        child: state is ReclaimDepositDone
            ? _buildDoneView()
            : _buildSearchView(),
      ),
    );
  }

  Widget _buildDoneView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: kVerticalGap16.height!,
      children: <Widget>[
        SvgPicture.asset(
          'assets/svg/ic_completed_symbol.svg',
          colorFilter: const ColorFilter.mode(
            AppColors.znnColor,
            BlendMode.srcIn,
          ),
          height: 70,
        ),
        Text(
          context.l10n.reclaimTransactionSentFundsShortly,
          style: context.textTheme.titleMedium,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSearchView() {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: _depositIdController,
      builder: (_, TextEditingValue value, _) {
        final String? depositIdError = InputValidators.checkHash(value.text);

        return Column(
          spacing: kVerticalGap16.height!,
          children: <Widget>[
            Text(
              context.l10n.reclaimExpiredDepositWithId,
            ),
            const ViewSwapTutorialButton(),
            TextField(
              decoration: InputDecoration(
                errorText: value.text.isNotEmpty ? depositIdError : null,
                hintText: context.l10n.depositId,
                suffixIcon: FieldSuffixButtons(
                  controller: _depositIdController,
                ),
              ),
              controller: _depositIdController,
            ),
            ReclaimDepositButton(
              depositId: value.text,
              isEnabled: depositIdError == null && value.text.isNotEmpty,
              text: context.l10n.reclaimDeposit,
              loadingText: context.l10n.sendingTransaction,
              successMessage: context.l10n.reclaimTransactionSentFundsShortly,
              instructionText: context.l10n.inputDepositId,
            ),
          ],
        );
      },
    );
  }
}
