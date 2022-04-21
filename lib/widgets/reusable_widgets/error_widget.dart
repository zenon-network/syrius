import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class SyriusErrorWidget extends StatelessWidget {
  static const String route = 'syrius-error-widget';

  final Object error;

  const SyriusErrorWidget(
    this.error, {
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Lottie.asset(
                'assets/lottie/ic_anim_no_data.json',
                width: 32.0,
                height: 32.0,
              ),
              Text(
                _getErrorText(error.toString()),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyText2,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getErrorText(String errorText) =>
      errorText.toLowerCase().contains('bad state: the client is closed')
          ? 'Not connected to the network'
          : errorText;
}
