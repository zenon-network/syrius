import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:layout/layout.dart';
import 'package:zenon_syrius_wallet_flutter/utils/app_colors.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/widgets.dart';

class AccessWalletFluidCell extends FluidCell {

  AccessWalletFluidCell({
    required this.onPressed,
    required this.buttonIconLocation,
    required this.buttonText,
    required this.context,
  }) : super(
          width: context.layout.value(
            xl: kStaggeredNumOfColumns ~/ 3,
            lg: kStaggeredNumOfColumns ~/ 3,
            md: kStaggeredNumOfColumns ~/ 3,
            sm: kStaggeredNumOfColumns ~/ 2,
            xs: kStaggeredNumOfColumns,
          ),
          child: MaterialButton(
            disabledColor: Theme.of(context).colorScheme.secondary.withOpacity(
                  0.7,
                ),
            padding: const EdgeInsets.all(50),
            color: Theme.of(context).colorScheme.secondaryContainer,
            hoverColor: Theme.of(context).colorScheme.secondary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Colors.transparent),
            ),
            onPressed: onPressed,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                Container(
                  width: 70,
                  height: 70,
                  color: Colors.transparent,
                  child: SvgPicture.asset(
                    buttonIconLocation,
                    colorFilter: const ColorFilter.mode(
                        AppColors.znnColor, BlendMode.srcIn,),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(
                    left: 40,
                    right: 40,
                  ),
                  child: Text(
                    buttonText,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
              ],
            ),
          ),
        );
  final VoidCallback? onPressed;
  final String buttonIconLocation;
  final String buttonText;
  final BuildContext context;
}
