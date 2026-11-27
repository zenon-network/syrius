import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:zenon_syrius_wallet_flutter/l10n/app_localizations.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/exceptions/syrius_exception.dart';
import 'package:zenon_syrius_wallet_flutter/rearchitecture/utils/l10n/app_localizations_resolver.dart';

/// Centered error display showing an animation and localized error message.
class SyriusErrorWidget extends StatelessWidget {
  /// Creates a [SyriusErrorWidget] for the given [error].
  const SyriusErrorWidget(this.error, {super.key});

  /// Named route identifier for [SyriusErrorWidget].
  static const String route = 'syrius-error-widget';

  /// Error object formatted and displayed to the user.
  final Object error;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n =
        AppLocalizations.of(context) ?? resolveAppLocalizations();
    final Object currentError = error;
    final String rawText = currentError is SyriusException
        ? currentError.localizedMessage(l10n)
        : currentError.toString();

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: SingleChildScrollView(
          child: Column(
            children: <Widget>[
              Lottie.asset(
                'assets/lottie/ic_anim_no_data.json',
                width: 32,
                height: 32,
              ),
              Text(
                _getErrorText(rawText, l10n),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getErrorText(String errorText, AppLocalizations l10n) =>
      errorText.toLowerCase().contains('bad state: the client is closed')
      ? l10n.notConnectedToNetwork
      : errorText;
}
