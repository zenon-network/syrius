import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

const String _kWidgetTitle = 'Transfer';
const String _kWidgetDescription =
    'Redirects you to the Transfer tab where you '
    'can manage sending and receiving funds';

class Transfer extends StatefulWidget {

  const Transfer({
    super.key,
    this.changePage,
  });
  final Function(
    Tabs, {
    bool redirectWithSendContainerLarge,
    bool redirectWithReceiveContainerLarge,
  })? changePage;

  @override
  State<Transfer> createState() => _TransferState();
}

class _TransferState extends State<Transfer> {
  @override
  Widget build(BuildContext context) {
    return CardScaffold(
      title: _kWidgetTitle,
      description: _kWidgetDescription,
      childBuilder: _getTransferButtons,
    );
  }

  Column _getTransferButtons() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        IconButton(
          splashRadius: 30,
          onPressed: () {
            widget.changePage!(Tabs.transfer,
                redirectWithSendContainerLarge: true,);
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
            widget.changePage!(Tabs.transfer,
                redirectWithReceiveContainerLarge: true,);
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
    );
  }
}
