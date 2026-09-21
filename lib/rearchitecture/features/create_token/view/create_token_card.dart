import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/features/features.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/utils.dart';
import 'package:zenon_syrius_wallet_flutter/screens/screens.dart';

/// A card that starts the token creation flow.
class CreateTokenCard extends StatelessWidget {
  /// Creates a token creation card.
  const CreateTokenCard({
    required this._onStepperNotificationSeeMorePressed,
    super.key,
  });

  final VoidCallback _onStepperNotificationSeeMorePressed;

  @override
  Widget build(BuildContext context) {
    return NewCardScaffold(
      data: _buildCardData(context: context),
      body: _View(
        onStepperNotificationSeeMorePressed:
            _onStepperNotificationSeeMorePressed,
      ),
    );
  }

  CardData _buildCardData({required BuildContext context}) => CardData(
    title: context.l10n.createTokenTitle,
    description: context.l10n.createTokenDescription,
  );
}

class _View extends StatelessWidget {
  const _View({
    required this.onStepperNotificationSeeMorePressed,
  });

  final VoidCallback onStepperNotificationSeeMorePressed;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: .spaceEvenly,
      children: <Widget>[
        Lottie.asset(
          'assets/lottie/ic_anim_zts.json',
          width: 128,
          height: 128,
          repeat: false,
        ),
        ElevatedButton.icon(
          onPressed: () {
            unawaited(
              Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (BuildContext context) => StepperScreen(
                    stepper: const CreateTokenStepperPage(),
                    onStepperNotificationSeeMorePressed:
                        onStepperNotificationSeeMorePressed,
                  ),
                ),
              ),
            );
          },
          label: Text(context.l10n.createToken),
          icon: const Icon(Icons.add),
        ),
      ],
    );
  }
}
