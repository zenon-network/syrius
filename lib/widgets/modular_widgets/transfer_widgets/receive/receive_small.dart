import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

class ReceiveSmallCard extends StatefulWidget {

  const ReceiveSmallCard(
    this.onPressed, {
    super.key,
  });
  final VoidCallback onPressed;

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
            15,
          ),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              SimpleLineIcons.arrow_down_circle,
              size: 60,
              color: AppColors.lightHintTextColor,
            ),
            SizedBox(
              height: 20,
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
