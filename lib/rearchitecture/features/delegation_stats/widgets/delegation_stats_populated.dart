import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/reusable_widgets.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

/// A widget that displays the delegation stats amount and to which pillar the amount
/// was delegated to.
class DelegationStatsPopulated extends StatefulWidget {
  /// Creates a DelegationPopulated object.
  const DelegationStatsPopulated({required this.delegationInfo, super.key});

  /// Field that holds the needed details
  final DelegationInfo delegationInfo;

  @override
  State<DelegationStatsPopulated> createState() =>
      _DelegationStatsPopulatedState();
}

class _DelegationStatsPopulatedState extends State<DelegationStatsPopulated> {
  final GlobalKey<LoadingButtonState> _undelegateButtonKey =
      GlobalKey<LoadingButtonState>();

  @override
  Widget build(BuildContext context) {
    final String pillarName = widget.delegationInfo.name;
    final BigInt weight = widget.delegationInfo.weight;

    return Column(
      mainAxisAlignment: .spaceEvenly,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            SizedBox.square(
              dimension: 36,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: widget.delegationInfo.status == 1
                        ? AppColors.znnColor
                        : AppColors.errorColor,
                  ),
                ),
                child: const Icon(
                  SimpleLineIcons.trophy,
                  size: 12,
                ),
              ),
            ),
            kHorizontalGap16,
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  pillarName,
                  style: context.textTheme.bodyMedium,
                ),
                Text(
                  '${weight.addDecimals(coinDecimals)} ${kZnnCoin.symbol}',
                  style: context.textTheme.titleMedium,
                ),
              ],
            ),
          ],
        ),
        _getUndelegateButton(context: context),
      ],
    );
  }

  Widget _getUndelegateButton({
    required BuildContext context,
  }) {
    return BlocListener<UndelegateBloc, UndelegateState>(
      listener: (_, UndelegateState state) {
        if (state is UndelegateDone) {
          _undelegateButtonKey.currentState?.animateReverse();
          context.read<DelegationStatsBloc>().add(
            FetchRequestData(address: Address.parse(kSelectedAddress!)),
          );
        } else if (state is UndelegateFailure) {
          _undelegateButtonKey.currentState?.animateReverse();
          unawaited(
            NotificationUtils.sendNotificationError(
              state.exception,
              context.l10n.errorUndelegating,
            ),
          );
        } else if (state is UndelegateLoading) {
          _undelegateButtonKey.currentState?.animateForward();
        }
      },
      child: LoadingButton(
        onPressed: () {
          context.read<UndelegateBloc>().add(
            UndelegateRequested(address: Address.parse(kSelectedAddress!)),
          );
        },
        text: context.l10n.undelegate,
        textStyle: const TextStyle(
          color: Colors.white,
        ),
        outlineColor: AppColors.errorColor,
        key: _undelegateButtonKey,
      ),
    );
  }
}
