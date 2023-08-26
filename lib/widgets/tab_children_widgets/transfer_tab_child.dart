import 'package:flutter/material.dart';
import 'package:layout/layout.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

enum DimensionCard { small, medium, large }

class TransferTabChild extends StatefulWidget {
  DimensionCard sendCard;
  DimensionCard receiveCard;

  TransferTabChild({
    Key? key,
    this.sendCard = DimensionCard.medium,
    this.receiveCard = DimensionCard.medium,
  }) : super(key: key);

  @override
  State<TransferTabChild> createState() => _TransferTabChildState();
}

class _TransferTabChildState extends State<TransferTabChild> {
  @override
  Widget build(BuildContext context) {
    return StandardFluidLayout(
      children: [
        _getSendCard(),
        _getReceiveCard(),
        const FluidCell(
          width: kStaggeredNumOfColumns,
          child: LatestTransactions(),
          height: kStaggeredNumOfColumns / 2,
        ),
      ],
    );
  }

  FluidCell _getReceiveCard() => widget.receiveCard == DimensionCard.medium
      ? _getMediumFluidCell(
          ReceiveMediumCard(
            onExpandClicked: _onExpandReceiveCard,
          ),
        )
      : widget.receiveCard == DimensionCard.small
          ? _getSmallFluidCell(ReceiveSmallCard(_onCollapse))
          : _getLargeFluidCell(
              ReceiveLargeCard(
                extendIcon: true,
                onCollapseClicked: _onCollapse,
              ),
            );

  FluidCell _getSendCard() => widget.sendCard == DimensionCard.medium
      ? _getMediumFluidCell(
          SendMediumCard(onExpandClicked: _onExpandSendCard),
        )
      : widget.sendCard == DimensionCard.small
          ? _getSmallFluidCell(SendSmallCard(_onCollapse))
          : _getLargeFluidCell(
              SendLargeCard(
                extendIcon: true,
                onCollapsePressed: _onCollapse,
              ),
            );

  FluidCell _getMediumFluidCell(Widget child) {
    return FluidCell(
      width: context.layout.value(
        xl: kStaggeredNumOfColumns ~/ 2,
        lg: kStaggeredNumOfColumns ~/ 2,
        md: kStaggeredNumOfColumns ~/ 2,
        sm: kStaggeredNumOfColumns,
        xs: kStaggeredNumOfColumns,
      ),
      child: child,
    );
  }

  FluidCell _getLargeFluidCell(Widget child) {
    return FluidCell(
      width: context.layout.value(
        xl: kStaggeredNumOfColumns ~/ 1.2,
        lg: kStaggeredNumOfColumns ~/ 1.2,
        md: kStaggeredNumOfColumns ~/ 1.2,
        sm: kStaggeredNumOfColumns,
        xs: kStaggeredNumOfColumns,
      ),
      child: child,
    );
  }

  FluidCell _getSmallFluidCell(Widget child) {
    return FluidCell(
      width: context.layout.value(
        xl: kStaggeredNumOfColumns ~/ 6,
        lg: kStaggeredNumOfColumns ~/ 6,
        md: kStaggeredNumOfColumns ~/ 6,
        sm: kStaggeredNumOfColumns,
        xs: kStaggeredNumOfColumns,
      ),
      child: child,
    );
  }

  void _onExpandSendCard() {
    setState(() {
      widget.sendCard = DimensionCard.large;
      widget.receiveCard = DimensionCard.small;
    });
  }

  void _onExpandReceiveCard() {
    setState(() {
      widget.sendCard = DimensionCard.small;
      widget.receiveCard = DimensionCard.large;
    });
  }

  void _onCollapse() {
    setState(() {
      widget.sendCard = DimensionCard.medium;
      widget.receiveCard = DimensionCard.medium;
    });
  }
}
