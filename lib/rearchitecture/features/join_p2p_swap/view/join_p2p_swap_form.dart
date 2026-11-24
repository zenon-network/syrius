import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/utils/extensions.dart';
import 'package:zenon_syrius_wallet_flutter/utils/input_validators.dart';
import 'package:zenon_syrius_wallet_flutter/utils/notification_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/zts_utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/input_fields/input_fields.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// Form for reviewing and joining a validated native P2P swap.
class JoinP2pSwapForm extends StatefulWidget {
  /// Creates a [JoinP2pSwapForm].
  const JoinP2pSwapForm({
    required this.accountInfo,
    required this.initialHtlc,
    required this.token,
    super.key,
  });

  /// Current account information for the address joining the swap.
  final AccountInfo accountInfo;

  /// The fetched and validated initial HTLC.
  final HtlcInfo initialHtlc;

  /// Token locked in the initial HTLC.
  final Token token;

  @override
  State<JoinP2pSwapForm> createState() => _JoinP2pSwapFormState();
}

class _JoinP2pSwapFormState extends State<JoinP2pSwapForm> {
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final ValueNotifier<Token> _tokenNotifier = .new(kZnnCoin);

  Token get _token => _tokenNotifier.value;

  @override
  void initState() {
    super.initState();
    _addressController.text = widget.initialHtlc.hashLocked.toString();
  }

  @override
  void dispose() {
    _addressController.dispose();
    _amountController.dispose();
    _tokenNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<JoinSwapAvailabilityCubit>(
      create: (_) => JoinSwapAvailabilityCubit(
        initialHtlc: widget.initialHtlc,
      ),
      child: _buildContent(),
    );
  }

  Widget _buildContent() {
    final String counterpartyDeadlineBullet = context.l10n
        .counterpartyTimeToCompleteSwap(
          kCounterHtlcDuration.inHours,
        );
    final String reclaimBullet = context.l10n.reclaimFundsIfCounterpartyFails;

    return BlocConsumer<JoinP2pSwapBloc, JoinP2pSwapState>(
      listener: _onJoinP2pSwapStateChanged,
      builder: (_, JoinP2pSwapState state) {
        final bool isSwapLoading = state is JoinP2pSwapLoading;

        return ListenableBuilder(
          listenable: Listenable.merge(<Listenable>[
            _amountController,
            _tokenNotifier,
          ]),
          builder: (_, _) {
            final String amount = _amountController.text;
            final String? amountError = InputValidators.correctValue(
              amount,
              widget.accountInfo.getBalance(_token.tokenStandard),
              _token.decimals,
              BigInt.zero,
            );
            final bool isAmountValid = amount.isNotEmpty && amountError == null;

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              spacing: kVerticalGap16.height!,
              children: <Widget>[
                DisabledAddressField(
                  _addressController,
                  labelText: context.l10n.receiveSwappedFundsToAddress,
                ),
                Divider(color: Colors.white.withValues(alpha: 0.1)),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: AmountTextField(
                        accountInfo: widget.accountInfo,
                        controller: _amountController,
                        enabled: !isSwapLoading,
                        errorText: amount.isNotEmpty ? amountError : null,
                        labelText: context.l10n.youAreSending,
                        token: _token,
                        onSubmitted: (_) {},
                      ),
                    ),
                    kHorizontalGap16,
                    Expanded(
                      child: ZtsDropdown(
                        availableTokens: getTokensWithBalance(
                          accountInfo: widget.accountInfo,
                        ),
                        enabled: !isSwapLoading,
                        label: Text(context.l10n.asset),
                        selectedToken: _tokenNotifier,
                      ),
                    ),
                  ],
                ),
                const Icon(
                  AntDesign.arrowdown,
                  color: Colors.white,
                ),
                HtlcCard.fromHtlcInfo(
                  title: context.l10n.youAreReceiving,
                  htlc: widget.initialHtlc,
                  token: widget.token,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _buildExchangeRateWidget(),
                ),
                _buildAvailabilitySection(
                  amount: amount,
                  counterpartyDeadlineBullet: counterpartyDeadlineBullet,
                  isAmountValid: isAmountValid,
                  reclaimBullet: reclaimBullet,
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildAvailabilitySection({
    required String amount,
    required String counterpartyDeadlineBullet,
    required bool isAmountValid,
    required String reclaimBullet,
  }) {
    return BlocBuilder<JoinSwapAvailabilityCubit, JoinSwapAvailabilityState>(
      builder: (_, JoinSwapAvailabilityState state) => switch (state) {
        JoinSwapAvailable(:final int minutesLeftToJoin) => Column(
          spacing: kVerticalGap16.height!,
          children: <Widget>[
            BulletPointCard(
              bulletPoints: <String>[
                context.l10n.minutesLeftToJoinSwap(minutesLeftToJoin),
                counterpartyDeadlineBullet,
                reclaimBullet,
              ],
            ),
            if (!isTrustedToken(
              widget.token.tokenStandard.toString(),
            ))
              Warning(
                text: context.l10n.verifyNonFavoriteToken(
                  widget.token.tokenStandard.toString(),
                ),
              ),
            JoinSwapButton(
              fromAmount: amount,
              fromToken: _token,
              initialHtlc: widget.initialHtlc,
              isEnabled: isAmountValid,
              toToken: widget.token,
            ),
          ],
        ),
        JoinSwapUnavailable() => Column(
          children: <Widget>[
            Warning(
              text: context.l10n.cannotJoinSwapExpiresTooSoon,
            ),
          ],
        ),
      },
    );
  }

  void _onJoinP2pSwapStateChanged(
    BuildContext context,
    JoinP2pSwapState state,
  ) {
    if (state is JoinP2pSwapDone) {
      Navigator.pop(context, state.swap.id);
    } else if (state case JoinP2pSwapFailure(
      :final SyriusException exception,
    )) {
      unawaited(
        NotificationUtils.showForegroundError(
          context,
          exception,
          context.l10n.errorJoiningSwap,
        ),
      );
    }
  }

  Widget _buildExchangeRateWidget() {
    return ExchangeRate(
      fromAmount: _amountController.text.extractDecimals(
        _token.decimals,
      ),
      toAmount: widget.initialHtlc.amount,
      fromToken: _token,
      toToken: widget.token,
    );
  }
}
