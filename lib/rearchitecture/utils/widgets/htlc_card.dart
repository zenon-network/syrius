import 'package:flutter/material.dart';
import 'package:hive_ce/hive_ce.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/address_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';
import 'package:zenon_syrius_wallet_flutter/utils/color_utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/constants.dart';
import 'package:zenon_syrius_wallet_flutter/utils/extensions.dart';
import 'package:zenon_syrius_wallet_flutter/utils/format_utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/loading_info_text.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// Displays an expandable summary of a hash time-locked contract.
class HtlcCard extends StatefulWidget {
  /// Creates a card from explicit HTLC details.
  const HtlcCard({
    required this._title,
    required this._sender,
    required this._htlcId,
    required this._hashLock,
    required this.expirationTime,
    required this._recipient,
    required this._amount,
    this._token,
    super.key,
  });

  /// Creates a card for the HTLC that sends funds in [swap].
  factory HtlcCard.sending({
    required BuildContext context,
    required HtlcSwap swap,
  }) => HtlcCard(
    title: context.l10n.youAreSending,
    sender: swap.selfAddress,
    htlcId: swap.direction == P2pSwapDirection.outgoing
        ? swap.initialHtlcId
        : swap.counterHtlcId,
    hashLock: swap.hashLock,
    expirationTime: swap.direction == P2pSwapDirection.outgoing
        ? swap.initialHtlcExpirationTime
        : swap.counterHtlcExpirationTime,
    recipient: swap.counterpartyAddress,
    amount: swap.fromAmount,
    token: swap.fromToken,
  );

  /// Creates a card for the HTLC that receives funds in [swap].
  factory HtlcCard.receiving({
    required BuildContext context,
    required HtlcSwap swap,
  }) => HtlcCard(
    title: context.l10n.youAreReceiving,
    sender: swap.counterpartyAddress,
    htlcId: swap.direction == P2pSwapDirection.outgoing
        ? swap.counterHtlcId
        : swap.initialHtlcId,
    hashLock: swap.hashLock,
    expirationTime: swap.direction == P2pSwapDirection.outgoing
        ? swap.counterHtlcExpirationTime
        : swap.initialHtlcExpirationTime,
    recipient: swap.selfAddress,
    amount: swap.toAmount,
    token: swap.toToken,
  );

  /// Creates a card from on-chain [htlc] information.
  factory HtlcCard.fromHtlcInfo({
    required String title,
    required HtlcInfo htlc,
    required Token token,
  }) => HtlcCard(
    title: title,
    sender: htlc.timeLocked.toString(),
    htlcId: htlc.id.toString(),
    hashLock: FormatUtils.encodeHexString(htlc.hashLock),
    expirationTime: htlc.expirationTime,
    recipient: htlc.hashLocked.toString(),
    amount: htlc.amount,
    token: token,
  );
  final String _title;
  final String _sender;
  final String? _htlcId;
  final String? _hashLock;

  /// The Unix timestamp at which the contract expires.
  final int? expirationTime;
  final String? _recipient;
  final BigInt? _amount;
  final Token? _token;

  @override
  State<HtlcCard> createState() => _HtlcCardState();
}

class _HtlcCardState extends State<HtlcCard> {
  final Duration _animationDuration = const Duration(milliseconds: 100);
  bool _areDetailsExpanded = false;

  @override
  Widget build(BuildContext context) {
    final Widget loading = LoadingInfoText(
      text: context.l10n.waitingForCounterpartyToJoin,
    );

    final Widget cardChild = widget._htlcId == null
        ? loading
        : _buildWidgetBody();

    return ConstrainedBox(
      constraints: const BoxConstraints(
        minHeight: 72,
      ),
      child: Card.filled(
        color: AppColors.znnColor.withAlpha((255 * 0.2).round()),
        clipBehavior: Clip.hardEdge,
        child: cardChild,
      ),
    );
  }

  Widget _buildWidgetBody() {
    final int decimals = widget._token!.decimals;
    final String symbol = widget._token!.symbol;

    final String title =
        '${widget._title} ${widget._amount!.addDecimals(decimals)} ';

    return InkWell(
      mouseCursor: SystemMouseCursors.click,
      onTap: () => setState(() => _areDetailsExpanded = !_areDetailsExpanded),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      text: title,
                      children: <InlineSpan>[
                        TextSpan(
                          text: symbol,
                          style: TextStyle(
                            color: ColorUtils.getTokenColor(
                              widget._token!.tokenStandard,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                _buildArrowButton(),
              ],
            ),
            _buildDetailsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildArrowButton() {
    return AnimatedRotation(
      turns: _areDetailsExpanded ? 0.5 : 0,
      duration: _animationDuration,
      child: const Icon(Icons.keyboard_arrow_down),
    );
  }

  Widget _buildDetailsSection() {
    // TODO(maznnwell): create a widget that expands and shrinks
    return AnimatedSwitcher(
      duration: _animationDuration,
      transitionBuilder:
          (
            Widget child,
            Animation<double> animation,
          ) {
            return SizeTransition(
              sizeFactor: animation,
              child: child,
            );
          },
      child: _areDetailsExpanded
          ? Column(
              children: <Widget>[
                kVerticalGap16,
                Divider(
                  color: Colors.white.withAlpha((255 * 0.1).round()),
                ),
                kVerticalGap16,
                _buildDetailsList(),
              ],
            )
          : null,
    );
  }

  Widget _buildDetailsList() {
    final Hash htlcId = Hash.parse(widget._htlcId!);
    final Hash hashLock = Hash.parse(widget._hashLock!);

    final List<Widget> children = <Widget>[
      _buildExpirationRow(widget.expirationTime!),
      DetailsRow(
        label: context.l10n.depositId,
        value: htlcId.toString(),
        valueToShow: htlcId.toShortString(),
      ),
      DetailsRow(
        label: context.l10n.tokenStandard,
        value: widget._token!.tokenStandard.toString(),
        prefixWidget: _buildTokenStandardTooltip(
          widget._token!.tokenStandard.toString(),
        ),
      ),
      DetailsRow(
        label: context.l10n.sender,
        value: widget._sender,
        valueToShow: ZenonAddressUtils.getLabel(widget._sender),
      ),
      DetailsRow(
        label: context.l10n.recipient,
        value: widget._recipient!,
        valueToShow: ZenonAddressUtils.getLabel(widget._recipient!),
      ),
      DetailsRow(
        label: context.l10n.hashlock,
        value: hashLock.toString(),
        valueToShow: hashLock.toShortString(),
      ),
    ];

    return Column(
      spacing: kVerticalGap16.height!,
      children: children,
    );
  }

  Widget _buildTokenStandardTooltip(String tokenStandard) {
    String message = context.l10n.tokenNotInFavorites;
    IconData icon = Icons.help;
    Color iconColor = AppColors.errorColor;
    if (<String>[znnTokenStandard, qsrTokenStandard].contains(tokenStandard)) {
      message = context.l10n.tokenVerified;
      icon = Icons.check_circle_outline;
      iconColor = AppColors.znnColor;
    } else if (Hive.box(kFavoriteTokensBox).values.contains(tokenStandard)) {
      message = context.l10n.tokenInFavorites;
      icon = Icons.star;
      iconColor = AppColors.znnColor;
    }
    return Tooltip(
      message: message,
      child: Icon(
        icon,
        color: iconColor,
        size: 16,
      ),
    );
  }

  Widget _buildExpirationRow(int expirationTime) {
    final Duration duration = Duration(
      seconds: expirationTime - DateTime.now().unixTimestamp,
    );

    final Widget expired = DetailsRow(
      label: context.l10n.expiresIn,
      value: context.l10n.expired,
      canBeCopied: false,
    );

    if (duration.isNegative) {
      return expired;
    }
    return TweenAnimationBuilder<Duration>(
      duration: duration,
      tween: .new(begin: duration, end: Duration.zero),
      builder: (_, Duration d, _) {
        final Widget status = DetailsRow(
          label: context.l10n.expiresIn,
          value: d.toString().split('.').first,
          canBeCopied: false,
        );

        final Widget finalWidget = d > Duration.zero ? status : expired;

        return finalWidget;
      },
    );
  }
}
