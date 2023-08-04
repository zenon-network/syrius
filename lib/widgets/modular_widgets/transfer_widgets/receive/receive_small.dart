import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

class ReceiveSmallCard extends StatefulWidget {
  final VoidCallback onPressed;

  const ReceiveSmallCard(
    this.onPressed, {
    Key? key,
  }) : super(key: key);

  @override
  State<ReceiveSmallCard> createState() => _ReceiveSmallCardState();
}

class _ReceiveSmallCardState extends State<ReceiveSmallCard> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onPressed,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(
            15.0,
          ),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              SimpleLineIcons.arrow_down_circle,
              size: 60.0,
              color: AppColors.lightHintTextColor,
            ),
            SizedBox(
              height: 20.0,
            ),
            TransferIconLegend(
              legendText: '● Receive',
            ),
          ],
        ),
      ),
    );
  }
}
