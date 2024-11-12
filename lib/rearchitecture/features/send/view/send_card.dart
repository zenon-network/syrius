import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/send/send.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

/// A widget that handles returning the correct sized widget, depending on the
/// provided [cardDimension]
class SendCard extends StatelessWidget {
  /// Creates a new instance.
  const SendCard({required this.cardDimension, super.key});
  /// The dimension that the card should have
  final CardDimension cardDimension;

  @override
  Widget build(BuildContext context) {
    return switch (cardDimension) {
      CardDimension.small => SendSmallCard(
          () => _onCollapse(context: context),
        ),
      CardDimension.medium => SendMediumCard(
          onExpandClicked: () => _onExpandSendCard(context: context),
        ),
      CardDimension.large => SendLargeCard(
          extendIcon: true,
          onCollapsePressed: () => _onCollapse(context: context),
        ),
    };
  }

  void _onCollapse({required BuildContext context}) {
    context.read<SendCardDimensionBloc>().add(
          SendCardDimensionChanged(CardDimension.medium),
        );
  }

  void _onExpandSendCard({required BuildContext context}) {
    context.read<SendCardDimensionBloc>().add(
          SendCardDimensionChanged(CardDimension.large),
        );
  }
}
