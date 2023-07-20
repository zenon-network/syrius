import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

class SendSmallCard extends StatefulWidget {
  final VoidCallback onClicked;

  const SendSmallCard(
    this.onClicked, {
    Key? key,
  }) : super(key: key);

  @override
  State<SendSmallCard> createState() => _SendSmallCardState();
}

class _SendSmallCardState extends State<SendSmallCard> {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onClicked,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(
            15.0,
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(
            20.0,
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                SimpleLineIcons.arrow_up_circle,
                size: 60.0,
                color: AppColors.darkHintTextColor,
              ),
              SizedBox(
                height: 20.0,
              ),
              TransferIconLegend(
                legendText: '● Send',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
