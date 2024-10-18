import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/blocs/blocs.dart';
import 'package:zenon_syrius_wallet_flutter/main.dart';
import 'package:znn_sdk_dart/znn_sdk_dart.dart';

class TransferToggleCardSizeButton extends StatelessWidget {

  const TransferToggleCardSizeButton({
    required this.onPressed,
    required this.iconData,
    super.key,
  });
  final VoidCallback? onPressed;
  final IconData iconData;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PowStatus>(
      stream: sl.get<PowGeneratingStatusBloc>().stream,
      builder: (_, snapshot) {
        if (snapshot.hasError) {
          return _getButton(context, onPressed);
        } else if (snapshot.hasData) {
          switch (snapshot.data) {
            case PowStatus.generating:
              return _getButton(context, null);
            case PowStatus.done:
              return _getButton(context, onPressed);
            case null:
              return _getButton(context, onPressed);
          }
        }
        return _getButton(context, onPressed);
      },
    );
  }

  RawMaterialButton _getButton(
    BuildContext context,
    VoidCallback? onButtonPressed,
  ) {
    return RawMaterialButton(
      constraints: const BoxConstraints.tightForFinite(),
      padding: const EdgeInsets.all(
        20,
      ),
      shape: const CircleBorder(),
      onPressed: onButtonPressed,
      child: Icon(
        iconData,
        color: onPressed == null
            ? Colors.grey
            : Theme.of(context).textTheme.headlineSmall!.color,
      ),
    );
  }
}
