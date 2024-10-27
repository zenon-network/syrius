import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

/// A card with two [IconButton] widgets that redirect to the Transfer tab
class TransferCard extends StatefulWidget {
  /// Creates a Transfer object.
  const TransferCard({
    super.key,
    this.changePage,
  });
  /// Function that triggers the redirect to the Transfer tab
  final Function(
    Tabs, {
    bool redirectWithSendContainerLarge,
    bool redirectWithReceiveContainerLarge,
  })? changePage;

  @override
  State<TransferCard> createState() => _TransferCardState();
}

class _TransferCardState extends State<TransferCard> {
  @override
  Widget build(BuildContext context) {
    return CardScaffoldWithoutListener(
      data: CardType.transfer.getData(context: context),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          IconButton(
            splashRadius: 30,
            onPressed: () {
              widget.changePage!(
                Tabs.transfer,
                redirectWithSendContainerLarge: true,
              );
            },
            icon: const Icon(
              SimpleLineIcons.arrow_up_circle,
            ),
            color: AppColors.darkHintTextColor,
            iconSize: 48,
          ),
          const TransferIconLegend(
            legendText: '● Send',
          ),
          IconButton(
            splashRadius: 30,
            onPressed: () {
              widget.changePage!(
                Tabs.transfer,
                redirectWithReceiveContainerLarge: true,
              );
            },
            icon: const Icon(
              SimpleLineIcons.arrow_down_circle,
            ),
            iconSize: 48,
            color: AppColors.lightHintTextColor,
          ),
          const TransferIconLegend(
            legendText: '● Receive',
          ),
        ],
      ),
    );
  }
}
