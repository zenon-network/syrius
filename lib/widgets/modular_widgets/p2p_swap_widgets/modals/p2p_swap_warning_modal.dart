import 'package:flutter/material.dart';
import 'package:zenon_syrius_wallet_flutter/widgets/reusable_widgets/modals/base_modal.dart';

class P2PSwapWarningModal extends StatefulWidget {
  final Function() onAccepted;

  const P2PSwapWarningModal({
    required this.onAccepted,
    Key? key,
  }) : super(key: key);

  @override
  State<P2PSwapWarningModal> createState() => _P2PSwapWarningModalState();
}

class _P2PSwapWarningModalState extends State<P2PSwapWarningModal> {
  @override
  Widget build(BuildContext context) {
    return BaseModal(
      title: 'Before continuing',
      child: _getContent(),
    );
  }

  Widget _getContent() {
    return Column(
      children: [
        const SizedBox(
          height: 20.0,
        ),
        const Text(
          '''Please note that the P2P swap is an experimental feature and may result in funds being lost.\n\n'''
          '''Use the feature with caution and consider splitting large swaps into multiple smaller ones.''',
          style: TextStyle(
            fontSize: 14.0,
          ),
        ),
        const SizedBox(
          height: 30.0,
        ),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => widget.onAccepted.call(),
            child: Text(
              'Continue',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
        ),
      ],
    );
  }
}
