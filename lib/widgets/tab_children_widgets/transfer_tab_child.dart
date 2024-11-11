import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:layout/layout.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/send/send.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

enum CardDimension { small, medium, large }

class TransferTabChild extends StatefulWidget {
  TransferTabChild({
    super.key,
  });

  @override
  State<TransferTabChild> createState() => _TransferTabChildState();
}

class _TransferTabChildState extends State<TransferTabChild> {
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SendCardDimensionBloc, SendCardDimensionState>(
      builder: (_, SendCardDimensionState state) {
        return StandardFluidLayout(
          children: <FluidCell>[
            _getSendCard(sendCardDimension: state.cardDimension),
            _getReceiveCard(sendCardDimension: state.cardDimension),
            const FluidCell(
              child: LatestTransactions(),
              width: kStaggeredNumOfColumns ~/ 2,
              height: kStaggeredNumOfColumns / 3,
            ),
            const FluidCell(
              child: PendingTransactions(),
              width: kStaggeredNumOfColumns ~/ 2,
              height: kStaggeredNumOfColumns / 3,
            ),
          ],
        );
      },
    );
  }

  FluidCell _getReceiveCard({required CardDimension sendCardDimension}) {
    return switch (sendCardDimension) {
      CardDimension.large => _getSmallFluidCell(ReceiveSmallCard(_onCollapse)),
      CardDimension.medium => _getMediumFluidCell(
          ReceiveMediumCard(
            onExpandClicked: _onExpandReceiveCard,
          ),
        ),
      CardDimension.small => _getLargeFluidCell(
          ReceiveLargeCard(
            extendIcon: true,
            onCollapseClicked: _onCollapse,
          ),
        ),
    };
  }

  FluidCell _getSendCard({required CardDimension sendCardDimension}) {
    return switch (sendCardDimension) {
      CardDimension.small => _getSmallFluidCell(SendSmallCard(_onCollapse)),
      CardDimension.medium => _getMediumFluidCell(
          SendMediumCard(onExpandClicked: _onExpandSendCard),
        ),
      CardDimension.large => _getLargeFluidCell(
          SendLargeCard(
            extendIcon: true,
            onCollapsePressed: _onCollapse,
          ),
        ),
    };
  }

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
    context.read<SendCardDimensionBloc>().add(
          SendCardDimensionChanged(CardDimension.large),
        );
  }

  void _onExpandReceiveCard() {
    context.read<SendCardDimensionBloc>().add(
          SendCardDimensionChanged(CardDimension.small),
        );
  }

  void _onCollapse() {
    context.read<SendCardDimensionBloc>().add(
          SendCardDimensionChanged(CardDimension.medium),
        );
  }
}
