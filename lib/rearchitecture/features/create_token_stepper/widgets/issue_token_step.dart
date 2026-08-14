import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/model/model.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// Final step that issues the token.
class IssueTokenStep extends StatefulWidget {
  /// Creates an [IssueTokenStep].
  const IssueTokenStep({
    required this.onBackPressed,
    required this.onIssueDone,
    required this.onIssuePressed,
    required this.tokenData,
    super.key,
  });

  /// Called when the user wants to go back.
  final VoidCallback onBackPressed;

  /// Called after the issue operation succeeds.
  final VoidCallback onIssueDone;

  /// Called when the user presses create.
  final VoidCallback onIssuePressed;

  /// Token data draft updated by this step.
  final ValueNotifier<NewTokenData> tokenData;

  @override
  State<IssueTokenStep> createState() => _IssueTokenStepState();
}

class _IssueTokenStepState extends State<IssueTokenStep> {
  final GlobalKey<LoadingButtonState> _createButtonKey = GlobalKey();

  bool get _isLoading =>
      (_createButtonKey.currentState?.btnState ?? ButtonState.idle) !=
      ButtonState.idle;

  @override
  Widget build(BuildContext context) {
    return BlocListener<IssueTokenBloc, IssueTokenState>(
      listener: (_, IssueTokenState state) => _onIssueTokenStateChanged(state),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Checkbox(
                key: const Key('token_utility_checkbox'),
                activeColor: AppColors.ztsColor,
                value: widget.tokenData.value.isUtility,
                onChanged: (bool? value) {
                  if (value != null) {
                    widget.tokenData.value = widget.tokenData.value.copyWith(
                      isUtility: value
                    );
                  }
                },
              ),
              Text(
                context.l10n.utilityToken,
                style: Theme.of(context).inputDecorationTheme.hintStyle,
              ),
              kHorizontalGap8,
              const Icon(
                Icons.settings,
                color: AppColors.ztsColor,
              ),
              StandardTooltipIcon(
                context.l10n.tokenStatusUtilityTooltip,
                Icons.help,
                iconColor: AppColors.ztsColor,
              ),
            ],
          ),
          kVerticalGap25,
          DottedBorderInfoWidget(
            text: context.l10n.burnTokenIssueFee(
              tokenZtsIssueFeeInZnn.addDecimals(coinDecimals),
              kZnnCoin.symbol,
            ),
            borderColor: AppColors.ztsColor,
          ),
          kVerticalGap25,
          Row(
            children: <Widget>[
              Visibility(
                visible: !_isLoading,
                child: Row(
                  children: <Widget>[
                    OutlinedButton(
                      onPressed: widget.onBackPressed,
                      child: Text(context.l10n.goBack),
                    ),
                    kHorizontalGap25,
                  ],
                ),
              ),
              KeyedSubtree(
                key: const Key('token_create_button'),
                child: LoadingButton.stepper(
                  textColor: AppColors.ztsColor,
                  text: context.l10n.create,
                  outlineColor: AppColors.ztsColor,
                  onPressed: () {
                    widget.onIssuePressed();
                  },
                  key: _createButtonKey,
                ),
              ),
            ],
          ),
          kVerticalGap25,
        ],
      ),
    );
  }

  void _onIssueTokenStateChanged(IssueTokenState state) {
    if (state is IssueTokenLoading) {
      _createButtonKey.currentState?.animateForward();
    } else if (state is IssueTokenDone) {
      _createButtonKey.currentState?.animateReverse();
      widget.onIssueDone();
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
}
